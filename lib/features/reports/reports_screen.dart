import 'package:flutter/material.dart';
import '../../core/backup/cloud_backup_service.dart';
import '../../core/localization/app_strings.dart';
import '../../core/pdf/report_pdf_service.dart';
import '../../core/tax/tax_service.dart';
import '../../core/preferences/user_preferences.dart';
import '../../core/subscription/entitlement_service.dart';
import '../../core/subscription/pro_feature_gate.dart';
import '../../shared/widgets/summary_card.dart';
import '../../shared/utils/distance_utils.dart';
import '../../shared/utils/currency_utils.dart';
import '../../app/app.dart';
import '../expenses/models/expense_entry.dart';
import '../expenses/services/expense_service.dart';
import '../fuel/models/fuel_entry.dart';
import '../fuel/services/fuel_service.dart';
import '../trips/models/trip.dart';
import '../trips/services/trip_service.dart';
import '../../core/export/csv_export_service.dart';
import 'expense_breakdown.dart';
import 'platform_breakdown.dart';
import 'widgets/platform_charts_section.dart';
import '../../core/help/help_catalog.dart';
import '../../shared/widgets/help_hint.dart';

enum ReportPeriodType { thisMonth, lastMonth, custom }

class ReportsScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;
  final UserPreferences preferences;
  final VoidCallback? onReviewDetectedTrips;
  final VoidCallback? onAddTrip;

  /// Opens the add-expense screen; Reports reloads once it closes.
  final Future<void> Function()? onAddExpense;

  const ReportsScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.preferences,
    this.onReviewDetectedTrips,
    this.onAddTrip,
    this.onAddExpense,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _tripService = TripService();
  final _fuelService = FuelService();
  final _expenseService = ExpenseService();
  final _pdfService = ReportPdfService();
  final _taxService = TaxService();
  final _csvService = CsvExportService();
  final _cloudBackupService = CloudBackupService();

  // ─── All trips (raw, unfiltered) ─────────────────────────────────────────
  List<Trip> _allTrips = [];
  List<FuelEntry> _allFuelEntries = [];
  List<ExpenseEntry> _allExpenseEntries = [];

  // ─── Period selection ─────────────────────────────────────────────────────
  ReportPeriodType _selectedPeriod = ReportPeriodType.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // ─── Computed state for the selected period ───────────────────────────────
  List<Trip> _reportTrips = [];
  List<FuelEntry> _reportFuelEntries = [];
  double _totalDistance = 0;
  double _businessDistance = 0;

  // ─── Expenses ─────────────────────────────────────────────────────────────
  // WorkShift expenses have no transaction date, so period reports exclude
  // them to avoid overstating month-specific totals.
  double _totalFuel = 0;
  double _totalParking = 0;
  double _totalTolls = 0;
  double _shiftParking = 0;
  double _shiftTolls = 0;
  double _totalFuelLogCost = 0;
  double _totalFuelVolumeLiters = 0;
  DateTime? _lastCloudBackupTime;

  // ─── Platform charts ──────────────────────────────────────────────────────
  ChartPeriod _chartPeriod = ChartPeriod.month;
  PlatformColorAssignment _platformColors = PlatformColorAssignment.fromTrips(
    const [],
  );
  // Aggregated once per period and reused until the data reloads, so
  // flipping between periods on a long history does not re-walk every record.
  final Map<ChartPeriod, PlatformBreakdown> _chartCache = {};
  final Map<ChartPeriod, ExpenseBreakdown> _expenseChartCache = {};

  bool _isLoading = true;
  bool _isExportingSimple = false;
  bool _isExportingDetailed = false;
  bool _isExportingCsv = false;
  bool _isExportingCharts = false;

  bool get _isExportingAny =>
      _isExportingSimple ||
      _isExportingDetailed ||
      _isExportingCsv ||
      _isExportingCharts;

  String get _currencyCode => widget.preferences.currencyCode;
  int get _needsReviewCount => _reportTrips
      .where((trip) => trip.reviewStatus == TripReviewStatus.needsReview)
      .length;

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
    final fuelEntries = await _fuelService.loadFuelEntries();
    final expenseEntries = await _expenseService.loadExpenseEntries();
    DateTime? lastCloudBackupTime;
    try {
      lastCloudBackupTime = await _cloudBackupService.getLastCloudBackupTime();
    } catch (_) {
      lastCloudBackupTime = null;
    }

    _allTrips = trips;
    _allFuelEntries = fuelEntries;
    _allExpenseEntries = expenseEntries;
    _platformColors = PlatformColorAssignment.fromTrips(trips);
    _chartCache.clear();
    _expenseChartCache.clear();
    final range = _currentReportRange();
    final reportTrips = _filterTrips(range);
    final reportFuelEntries = _filterFuelEntries(range);

    setState(() {
      _reportTrips = reportTrips;
      _reportFuelEntries = reportFuelEntries;
      _totalDistance = reportTrips.fold(0.0, (s, t) => s + t.distance);
      _businessDistance = reportTrips
          .where((t) => t.category == 'business')
          .fold(0.0, (s, t) => s + t.distance);
      // WorkShift expenses are recurring settings without dates. Excluding
      // them prevents selected-period reports from counting all-time values.
      _totalFuel = 0;
      _shiftParking = 0;
      _shiftTolls = 0;
      _totalParking =
          _shiftParking + reportTrips.fold(0.0, (s, t) => s + t.parkingExpense);
      _totalTolls =
          _shiftTolls + reportTrips.fold(0.0, (s, t) => s + t.tollsExpense);
      _totalFuelLogCost = reportFuelEntries.fold(
        0.0,
        (sum, entry) => sum + entry.totalCost,
      );
      _totalFuelVolumeLiters = reportFuelEntries.fold(
        0.0,
        (sum, entry) => sum + entry.volumeLiters,
      );
      _lastCloudBackupTime = lastCloudBackupTime;
      _isLoading = false;
    });
  }

  List<Trip> _filterTrips(DateTimeRange range) => _allTrips
      .where((t) => !t.date.isBefore(range.start) && !t.date.isAfter(range.end))
      .toList();

  List<FuelEntry> _filterFuelEntries(DateTimeRange range) => _allFuelEntries
      .where((e) => !e.date.isBefore(range.start) && !e.date.isAfter(range.end))
      .toList();

  void _computeTotals() {
    final range = _currentReportRange();
    final reportTrips = _filterTrips(range);
    final reportFuelEntries = _filterFuelEntries(range);
    setState(() {
      _reportTrips = reportTrips;
      _reportFuelEntries = reportFuelEntries;
      _totalDistance = reportTrips.fold(0.0, (s, t) => s + t.distance);
      _businessDistance = reportTrips
          .where((t) => t.category == 'business')
          .fold(0.0, (s, t) => s + t.distance);
      _totalParking =
          _shiftParking + reportTrips.fold(0.0, (s, t) => s + t.parkingExpense);
      _totalTolls =
          _shiftTolls + reportTrips.fold(0.0, (s, t) => s + t.tollsExpense);
      _totalFuelLogCost = reportFuelEntries.fold(
        0.0,
        (sum, entry) => sum + entry.totalCost,
      );
      _totalFuelVolumeLiters = reportFuelEntries.fold(
        0.0,
        (sum, entry) => sum + entry.volumeLiters,
      );
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

  /// Exports a PDF for the report period, or — when [chartPeriod] is given —
  /// for exactly the period the charts are showing, so "Create report" under
  /// the charts never produces a report for different dates than the reader
  /// was just looking at.
  Future<void> _handleExport(
    PdfReportType type, {
    ChartPeriod? chartPeriod,
  }) async {
    final entitlements = EntitlementService(widget.preferences);
    if (!requireProFeature(
      context: context,
      strings: widget.strings,
      allowed: entitlements.canExportUnlimitedReports,
    )) {
      return;
    }

    void setBusy(bool busy) {
      if (chartPeriod != null) {
        _isExportingCharts = busy;
      } else if (type == PdfReportType.simple) {
        _isExportingSimple = busy;
      } else {
        _isExportingDetailed = busy;
      }
    }

    setState(() => setBusy(true));

    try {
      final country = widget.preferences.country;
      final DateTimeRange range;
      final List<Trip> trips;
      final List<FuelEntry> fuelEntries;
      if (chartPeriod == null) {
        range = _currentReportRange();
        trips = _reportTrips;
        fuelEntries = _reportFuelEntries;
      } else {
        range = chartPeriodRange(
          chartPeriod,
          DateTime.now(),
          earliest: _earliestRecordDate(),
        );
        trips = tripsInPeriod(_allTrips, chartPeriod, DateTime.now());
        fuelEntries = chartPeriod == ChartPeriod.allTime
            ? _allFuelEntries
            : _filterFuelEntries(range);
      }
      final totalDistance = trips.fold(0.0, (s, t) => s + t.distance);
      final businessDistance = trips
          .where((t) => t.category == 'business')
          .fold(0.0, (s, t) => s + t.distance);

      await _pdfService.generateReport(
        trips: trips,
        totalDistance: totalDistance,
        businessDistance: businessDistance,
        tax: _taxService.calculateTaxFromKm(businessDistance, country),
        platformBreakdown: _buildPlatformBreakdown(trips),
        country: country,
        unit: widget.unit,
        currencyCode: _currencyCode,
        fuelEntries: fuelEntries,
        shifts: const [],
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
      if (mounted) setState(() => setBusy(false));
    }
  }

  DateTime? _earliestRecordDate() {
    DateTime? earliest;
    for (final date in [
      for (final t in _allTrips) t.date,
      for (final e in _allFuelEntries) e.date,
      for (final e in _allExpenseEntries) e.date,
    ]) {
      if (earliest == null || date.isBefore(earliest)) earliest = date;
    }
    return earliest;
  }

  PlatformBreakdown _chartBreakdown(ChartPeriod period) =>
      _chartCache.putIfAbsent(
        period,
        () => buildPlatformBreakdown(
          trips: tripsInPeriod(_allTrips, period, DateTime.now()),
          colors: _platformColors,
        ),
      );

  ExpenseBreakdown _expenseBreakdown(ChartPeriod period) {
    return _expenseChartCache.putIfAbsent(period, () {
      final now = DateTime.now();
      return buildExpenseBreakdown(
        trips: tripsInPeriod(_allTrips, period, now),
        fuelEntries: inChartPeriod(_allFuelEntries, (e) => e.date, period, now),
        expenseEntries: inChartPeriod(
          _allExpenseEntries,
          (e) => e.date,
          period,
          now,
        ),
      );
    });
  }

  Future<void> _addExpenseFromCharts() async {
    await widget.onAddExpense?.call();
    if (mounted) await _loadData();
  }

  Future<void> _handleCsvExport() async {
    final entitlements = EntitlementService(widget.preferences);
    if (!requireProFeature(
      context: context,
      strings: widget.strings,
      allowed: entitlements.canExportUnlimitedReports,
    )) {
      return;
    }

    setState(() => _isExportingCsv = true);
    try {
      final range = _currentReportRange();
      await _csvService.exportTrips(
        trips: _reportTrips,
        unit: widget.unit,
        currencyCode: _currencyCode,
        fuelEntries: _reportFuelEntries,
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

  String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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

  double get _displayFuelVolume {
    if (widget.unit == AppUnit.kilometers) return _totalFuelVolumeLiters;
    return _totalFuelVolumeLiters / 3.785411784;
  }

  double get _displayDistance => fromKilometers(_totalDistance, widget.unit);

  String _formatFuelVolume(AppStrings s) {
    if (_displayFuelVolume <= 0) return s.notAvailable;
    final unit = widget.unit == AppUnit.kilometers ? s.liters : s.gallons;
    return '${_displayFuelVolume.toStringAsFixed(1)} $unit';
  }

  String _formatAverageFuelPrice(AppStrings s) {
    final volume = _displayFuelVolume;
    if (volume <= 0) return s.notAvailable;
    final suffix = widget.unit == AppUnit.kilometers ? s.perLiter : s.perGallon;
    return '${formatCurrency(_totalFuelLogCost / volume, _currencyCode)} $suffix';
  }

  String _formatFuelCostPerDistance(AppStrings s) {
    final distance = _displayDistance;
    if (distance <= 0) return s.notAvailable;
    return formatCurrency(_totalFuelLogCost / distance, _currencyCode);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final entitlements = EntitlementService(widget.preferences);
    final totalExpenses = _totalFuel + _totalParking + _totalTolls;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.reports),
        actions: const [HelpHint(HelpTopic.reports)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Platform charts ────────────────────────────────────
                  PlatformChartsSection(
                    strings: s,
                    period: _chartPeriod,
                    onPeriodChanged: (period) =>
                        setState(() => _chartPeriod = period),
                    breakdown: _chartBreakdown(_chartPeriod),
                    expenses: _expenseBreakdown(_chartPeriod),
                    hasAnyRecords:
                        _allTrips.isNotEmpty ||
                        _allFuelEntries.isNotEmpty ||
                        _allExpenseEntries.isNotEmpty,
                    currencyCode: _currencyCode,
                    onAddTrip: widget.onAddTrip,
                    onAddExpense: widget.onAddExpense == null
                        ? null
                        : _addExpenseFromCharts,
                    isCreatingReport: _isExportingCharts,
                    // The detailed PDF is the one with the platform table,
                    // which is what these charts preview.
                    onCreateReport: _isExportingAny
                        ? null
                        : () => _handleExport(
                            PdfReportType.detailed,
                            chartPeriod: _chartPeriod,
                          ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

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
                  if (entitlements.canUseFuelSummaries)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.fuelSummary,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            _valueRow(
                              s.fuelCost,
                              formatCurrency(_totalFuelLogCost, _currencyCode),
                            ),
                            _valueRow(s.fuelAmount, _formatFuelVolume(s)),
                            _valueRow(
                              s.averageFuelPrice,
                              _formatAverageFuelPrice(s),
                            ),
                            _valueRow(
                              widget.unit == AppUnit.kilometers
                                  ? s.costPerKm
                                  : s.costPerMile,
                              _formatFuelCostPerDistance(s),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ProLockedCard(
                      strings: s,
                      title: s.proFuelSummaries,
                      icon: Icons.local_gas_station_outlined,
                    ),
                  const SizedBox(height: 12),

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
                  if (entitlements.canUseMonthlyCloseChecklist)
                    _monthlyCloseChecklist(s)
                  else
                    ProLockedCard(
                      strings: s,
                      title: s.proMonthlyCloseChecklist,
                      icon: Icons.fact_check_outlined,
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
    return _valueRow(label, formatCurrency(amount, _currencyCode), bold: bold);
  }

  Widget _valueRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyCloseChecklist(AppStrings s) {
    final lastBackup = _lastCloudBackupTime;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.monthlyCloseChecklist,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              s.checklistGuidance,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _checklistTile(
              label: s.reviewDetectedTrips,
              detail: _needsReviewCount > 0
                  ? s.tripsNeedReviewCount(_needsReviewCount)
                  : null,
              status: _needsReviewCount > 0
                  ? _ChecklistStatus.warning
                  : _ChecklistStatus.done,
              onTap: widget.onReviewDetectedTrips,
            ),
            _checklistTile(
              label: s.checkCategories,
              status: _ChecklistStatus.neutral,
            ),
            _checklistTile(
              label: s.checkFuelEntries,
              detail: _reportFuelEntries.isEmpty ? s.notAvailable : null,
              status: _reportFuelEntries.isEmpty
                  ? _ChecklistStatus.neutral
                  : _ChecklistStatus.done,
            ),
            _checklistTile(
              label: s.checkParkingAndTolls,
              status: totalParkingAndTolls > 0
                  ? _ChecklistStatus.done
                  : _ChecklistStatus.neutral,
            ),
            _checklistTile(
              label: s.backUpYourData,
              detail: lastBackup == null
                  ? null
                  : '${s.lastBackup}: ${_fmtDateTime(lastBackup)}',
              status: lastBackup == null
                  ? _ChecklistStatus.neutral
                  : _ChecklistStatus.done,
            ),
            _checklistTile(
              label: s.exportPdfCsv,
              status: _ChecklistStatus.neutral,
            ),
          ],
        ),
      ),
    );
  }

  double get totalParkingAndTolls => _totalParking + _totalTolls;

  Widget _checklistTile({
    required String label,
    required _ChecklistStatus status,
    String? detail,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final icon = switch (status) {
      _ChecklistStatus.done => Icons.check_circle_outline,
      _ChecklistStatus.warning => Icons.warning_amber_outlined,
      _ChecklistStatus.neutral => Icons.radio_button_unchecked,
    };
    final color = switch (status) {
      _ChecklistStatus.done => Colors.green,
      _ChecklistStatus.warning => cs.error,
      _ChecklistStatus.neutral => cs.onSurfaceVariant,
    };

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: detail == null ? null : Text(detail),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
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

enum _ChecklistStatus { done, warning, neutral }
