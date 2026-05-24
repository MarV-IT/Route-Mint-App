import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/pdf/report_pdf_service.dart';
import '../../core/tax/tax_service.dart';
import '../../core/preferences/user_preferences.dart';
import '../../shared/widgets/summary_card.dart';
import '../../shared/utils/distance_utils.dart';
import '../../shared/utils/currency_utils.dart';
import '../../app/app.dart';
import '../trips/models/trip.dart';
import '../trips/services/trip_service.dart';
import '../work_mode/services/work_mode_service.dart';
import '../../core/export/csv_export_service.dart';

enum ReportPeriodType { thisMonth, lastMonth, custom }

class ReportsScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;
  final UserPreferences preferences;

  const ReportsScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.preferences,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _tripService = TripService();
  final _workModeService = WorkModeService();
  final _pdfService = ReportPdfService();
  final _taxService = TaxService();
  final _csvService = CsvExportService();

  // ─── All trips (raw, unfiltered) ─────────────────────────────────────────
  List<Trip> _allTrips = [];

  // ─── Period selection ─────────────────────────────────────────────────────
  ReportPeriodType _selectedPeriod = ReportPeriodType.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // ─── Computed state for the selected period ───────────────────────────────
  List<Trip> _reportTrips = [];
  double _totalDistance = 0;
  double _businessDistance = 0;

  // ─── Expenses ─────────────────────────────────────────────────────────────
  // TODO: WorkShift fuel/parking/tolls are not date-filtered until shift log dates are added.
  double _totalFuel = 0;
  double _totalParking = 0; // shift parking + trip parking for selected period
  double _totalTolls = 0; // shift tolls + trip tolls for selected period
  double _shiftParking = 0; // shift-only, reused across period changes
  double _shiftTolls = 0;

  bool _isLoading = true;
  bool _isExportingSimple = false;
  bool _isExportingDetailed = false;
  bool _isExportingCsv = false;

  bool get _isExportingAny =>
      _isExportingSimple || _isExportingDetailed || _isExportingCsv;

  String get _currencyCode => widget.preferences.currencyCode;
  bool get _hasTripsNeedingReview => _reportTrips.any(
    (trip) => trip.reviewStatus == TripReviewStatus.needsReview,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── Period range ─────────────────────────────────────────────────────────

  DateTimeRange _currentReportRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ReportPeriodType.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ReportPeriodType.lastMonth:
        final first = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: first,
          end: DateTime(first.year, first.month + 1, 0, 23, 59, 59),
        );
      case ReportPeriodType.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return DateTimeRange(
            start: _customStartDate!,
            end: DateTime(
              _customEndDate!.year,
              _customEndDate!.month,
              _customEndDate!.day,
              23,
              59,
              59,
            ),
          );
        }
        // No custom range picked yet — fall back to this month.
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
    }
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final trips = await _tripService.loadTrips();
    final workSettings = await _workModeService.loadSettings();
    final shifts = workSettings.shifts;

    _allTrips = trips;
    final reportTrips = _filterTrips(_currentReportRange());

    setState(() {
      _reportTrips = reportTrips;
      _totalDistance = reportTrips.fold(0.0, (s, t) => s + t.distance);
      _businessDistance = reportTrips
          .where((t) => t.category == 'business')
          .fold(0.0, (s, t) => s + t.distance);
      // TODO: WorkShift fuel/parking/tolls are not date-filtered until shift log dates are added.
      _totalFuel = shifts.fold(0.0, (s, sh) => s + sh.fuelExpense);
      _shiftParking = shifts.fold(0.0, (s, sh) => s + sh.parkingExpense);
      _shiftTolls = shifts.fold(0.0, (s, sh) => s + sh.tollsExpense);
      _totalParking =
          _shiftParking + reportTrips.fold(0.0, (s, t) => s + t.parkingExpense);
      _totalTolls =
          _shiftTolls + reportTrips.fold(0.0, (s, t) => s + t.tollsExpense);
      _isLoading = false;
    });
  }

  List<Trip> _filterTrips(DateTimeRange range) => _allTrips
      .where((t) => !t.date.isBefore(range.start) && !t.date.isAfter(range.end))
      .toList();

  void _computeTotals() {
    final reportTrips = _filterTrips(_currentReportRange());
    setState(() {
      _reportTrips = reportTrips;
      _totalDistance = reportTrips.fold(0.0, (s, t) => s + t.distance);
      _businessDistance = reportTrips
          .where((t) => t.category == 'business')
          .fold(0.0, (s, t) => s + t.distance);
      _totalParking =
          _shiftParking + reportTrips.fold(0.0, (s, t) => s + t.parkingExpense);
      _totalTolls =
          _shiftTolls + reportTrips.fold(0.0, (s, t) => s + t.tollsExpense);
    });
  }

  // ─── Custom date range picker ─────────────────────────────────────────────

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );
    if (picked != null && mounted) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _computeTotals();
    }
  }

  // ─── Export ───────────────────────────────────────────────────────────────

  Future<void> _handleExport(PdfReportType type) async {
    if (_hasTripsNeedingReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.reviewDetectedTripsBeforeExport)),
      );
      return;
    }

    final isSimple = type == PdfReportType.simple;
    setState(() {
      if (isSimple) {
        _isExportingSimple = true;
      } else {
        _isExportingDetailed = true;
      }
    });

    try {
      final workSettings = await _workModeService.loadSettings();
      final country = widget.preferences.country;
      final tax = _taxService.calculateTaxFromKm(_businessDistance, country);
      final range = _currentReportRange();

      await _pdfService.generateReport(
        trips: _reportTrips,
        totalDistance: _totalDistance,
        businessDistance: _businessDistance,
        tax: tax,
        platformBreakdown: _buildPlatformBreakdown(_reportTrips),
        country: country,
        unit: widget.unit,
        shifts: workSettings.shifts,
        reportType: type,
        startDate: range.start,
        endDate: range.end,
        driverName: widget.preferences.driverName,
        businessName: widget.preferences.businessName,
        vehicleName: widget.preferences.vehicleName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.exportFailed)));
    } finally {
      if (mounted) {
        setState(() {
          if (isSimple) {
            _isExportingSimple = false;
          } else {
            _isExportingDetailed = false;
          }
        });
      }
    }
  }

  Future<void> _handleCsvExport() async {
    if (_hasTripsNeedingReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.reviewDetectedTripsBeforeExport)),
      );
      return;
    }

    setState(() => _isExportingCsv = true);
    try {
      final range = _currentReportRange();
      await _csvService.exportTrips(
        trips: _reportTrips,
        unit: widget.unit,
        currencyCode: _currencyCode,
        startDate: range.start,
        endDate: range.end,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.csvExportFailed)));
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Map<String, double> _buildPlatformBreakdown(List<Trip> trips) {
    final breakdown = <String, double>{};
    for (final trip in trips) {
      if (trip.category == 'business' && trip.platformName != null) {
        breakdown[trip.platformName!] =
            (breakdown[trip.platformName!] ?? 0) + trip.distance;
      }
    }
    return breakdown;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _periodTitle(AppStrings s) {
    switch (_selectedPeriod) {
      case ReportPeriodType.thisMonth:
        return s.thisMonth;
      case ReportPeriodType.lastMonth:
        return s.lastMonth;
      case ReportPeriodType.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return '${_fmtDate(_customStartDate!)} – ${_fmtDate(_customEndDate!)}';
        }
        return s.thisMonth;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final totalExpenses = _totalFuel + _totalParking + _totalTolls;

    return Scaffold(
      appBar: AppBar(title: Text(s.reports)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Report period selector ─────────────────────────────
                  Text(
                    s.reportPeriod,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ReportPeriodType>(
                    segments: [
                      ButtonSegment(
                        value: ReportPeriodType.thisMonth,
                        label: Text(s.thisMonth),
                      ),
                      ButtonSegment(
                        value: ReportPeriodType.lastMonth,
                        label: Text(s.lastMonth),
                      ),
                      ButtonSegment(
                        value: ReportPeriodType.custom,
                        label: Text(s.customRange),
                      ),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (newSelection) {
                      setState(() => _selectedPeriod = newSelection.first);
                      _computeTotals();
                    },
                  ),
                  if (_selectedPeriod == ReportPeriodType.custom) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _pickCustomRange,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _customStartDate != null && _customEndDate != null
                            ? '${_fmtDate(_customStartDate!)} – ${_fmtDate(_customEndDate!)}'
                            : s.selectDateRange,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Distance summary ───────────────────────────────────
                  SummaryCard(
                    title: _periodTitle(s),
                    value: formatDistance(_totalDistance, widget.unit),
                    subtitle:
                        '${s.business}: ${formatDistance(_businessDistance, widget.unit)}',
                  ),
                  const SizedBox(height: 12),

                  // ── Expenses summary ───────────────────────────────────
                  SummaryCard(
                    title: s.expenses,
                    value: formatCurrency(totalExpenses, _currencyCode),
                    subtitle: s.fuelParkingTolls,
                  ),
                  const SizedBox(height: 12),

                  // ── Expense breakdown ──────────────────────────────────
                  if (totalExpenses > 0)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.expenses,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            _expenseRow(s.fuel, _totalFuel),
                            _expenseRow(s.parking, _totalParking),
                            _expenseRow(s.tolls, _totalTolls),
                            const Divider(height: 16),
                            _expenseRow(
                              s.totalExpenses,
                              totalExpenses,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.taxReportTemplates,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          _templateTile(
                            icon: Icons.speed_outlined,
                            title: s.mileageSummary,
                            subtitle: s.businessMileage(
                              formatDistance(_businessDistance, widget.unit),
                            ),
                            onTap: _isExportingAny
                                ? null
                                : () => _handleExport(PdfReportType.simple),
                          ),
                          _templateTile(
                            icon: Icons.donut_small_outlined,
                            title: s.platformBreakdownReport,
                            subtitle: s.platformCount(
                              _buildPlatformBreakdown(_reportTrips).length,
                            ),
                            onTap: _isExportingAny
                                ? null
                                : () => _handleExport(PdfReportType.detailed),
                          ),
                          _templateTile(
                            icon: Icons.table_chart_outlined,
                            title: s.rawTripLog,
                            subtitle: s.tripsAsCsv(_reportTrips.length),
                            onTap: _isExportingAny ? null : _handleCsvExport,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Export section ─────────────────────────────────────
                  Text(
                    s.exportReport,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.accountantFriendlyReport,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_hasTripsNeedingReview) ...[
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: Icon(
                          Icons.rate_review_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                        title: Text(s.needsReview),
                        subtitle: Text(s.reviewDetectedTripsBeforeExport),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isExportingAny
                          ? null
                          : () => _handleExport(PdfReportType.simple),
                      icon: _isExportingSimple
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _isExportingSimple ? s.exporting : s.exportSimplePdf,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isExportingAny
                          ? null
                          : () => _handleExport(PdfReportType.detailed),
                      icon: _isExportingDetailed
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.description_outlined),
                      label: Text(
                        _isExportingDetailed
                            ? s.exporting
                            : s.exportDetailedPdf,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isExportingAny ? null : _handleCsvExport,
                      icon: _isExportingCsv
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.table_chart_outlined),
                      label: Text(_isExportingCsv ? s.exporting : s.exportCsv),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _expenseRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatCurrency(amount, _currencyCode),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
