import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../app/app.dart';
import '../../features/trips/models/trip.dart';
import '../../features/work_mode/models/work_shift.dart';
import '../../shared/utils/distance_utils.dart';
import '../tax/tax_service.dart';
import 'pdf_report_labels.dart';

enum PdfReportType { simple, detailed }

class ReportPdfService {
  // ─── Palette ──────────────────────────────────────────────────────────────

  static const _teal = PdfColor.fromInt(0xFF009688);
  static const _tealLight = PdfColor.fromInt(0xFFE0F2F1);
  static const _tealDark = PdfColor.fromInt(0xFF00695C);
  static const _grey = PdfColor.fromInt(0xFF757575);
  static const _greyLight = PdfColor.fromInt(0xFF9E9E9E);
  static const _divider = PdfColor.fromInt(0xFFE0E0E0);
  static const _black = PdfColor.fromInt(0xFF212121);
  static const _bgAlt = PdfColor.fromInt(0xFFFAFAFA);
  static const _bgCard = PdfColor.fromInt(0xFFF5F5F5);
  static const _noteYellow = PdfColor.fromInt(0xFFFFF9C4);
  static const _noteYellowBorder = PdfColor.fromInt(0xFFFFF176);

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Generates a PDF report for the given period.
  ///
  /// [startDate] and [endDate] define the period shown in the header.
  /// If omitted, the current calendar month is used as the default range.
  ///
  /// All labels inside the PDF are always in English via [PdfReportLabels],
  /// regardless of the app's UI locale.
  Future<void> generateReport({
    required List<Trip> trips,
    required double totalDistance,
    required double businessDistance,
    required double tax,
    required Map<String, double> platformBreakdown,
    required Country country,
    required AppUnit unit,
    List<WorkShift> shifts = const [],
    PdfReportType reportType = PdfReportType.simple,
    DateTime? startDate,
    DateTime? endDate,
    String? driverName,
    String? businessName,
    String? vehicleName,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? DateTime(now.year, now.month + 1, 0); // last day

    final periodLabel = PdfReportLabels.formatPeriod(start, end);
    final monthYearSlug = PdfReportLabels.formatMonthYear(
      start,
    ).replaceAll(' ', '_').toLowerCase();
    final unitStr = unitLabel(unit);
    final currencyCode = country == Country.usa
        ? PdfReportLabels.usd
        : PdfReportLabels.cad;

    // Fuel is shift-level only. Parking and tolls combine shift + trip level.
    final totalFuel = shifts.fold(0.0, (s, sh) => s + sh.fuelExpense);
    final totalParking =
        shifts.fold(0.0, (s, sh) => s + sh.parkingExpense) +
        trips.fold(0.0, (s, t) => s + t.parkingExpense);
    final totalTolls =
        shifts.fold(0.0, (s, sh) => s + sh.tollsExpense) +
        trips.fold(0.0, (s, t) => s + t.tollsExpense);
    final totalExpenses = totalFuel + totalParking + totalTolls;

    final doc = pw.Document();

    switch (reportType) {
      case PdfReportType.simple:
        _buildSimplePage(
          doc: doc,
          periodLabel: periodLabel,
          unitStr: unitStr,
          currencyCode: currencyCode,
          totalDistance: totalDistance,
          businessDistance: businessDistance,
          shifts: shifts,
          totalFuel: totalFuel,
          totalParking: totalParking,
          totalTolls: totalTolls,
          totalExpenses: totalExpenses,
          platformBreakdown: platformBreakdown,
          tax: tax,
          country: country,
          unit: unit,
          driverName: driverName,
          businessName: businessName,
          vehicleName: vehicleName,
        );
        break;
      case PdfReportType.detailed:
        _buildDetailedPage(
          doc: doc,
          now: now,
          periodLabel: periodLabel,
          unitStr: unitStr,
          currencyCode: currencyCode,
          totalDistance: totalDistance,
          businessDistance: businessDistance,
          shifts: shifts,
          trips: trips,
          unit: unit,
          totalFuel: totalFuel,
          totalParking: totalParking,
          totalTolls: totalTolls,
          totalExpenses: totalExpenses,
          driverName: driverName,
          businessName: businessName,
          vehicleName: vehicleName,
        );
        break;
    }

    final typeSlug = reportType == PdfReportType.simple ? 'simple' : 'detailed';
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'marv_route_${typeSlug}_$monthYearSlug.pdf',
    );
  }

  // ─── Simple report ────────────────────────────────────────────────────────

  void _buildSimplePage({
    required pw.Document doc,
    required String periodLabel,
    required String unitStr,
    required String currencyCode,
    required double totalDistance,
    required double businessDistance,
    required List<WorkShift> shifts,
    required double totalFuel,
    required double totalParking,
    required double totalTolls,
    required double totalExpenses,
    required Map<String, double> platformBreakdown,
    required double tax,
    required Country country,
    required AppUnit unit,
    String? driverName,
    String? businessName,
    String? vehicleName,
  }) {
    final identityPairs = _identityPairs(
        driverName: driverName,
        businessName: businessName,
        vehicleName: vehicleName);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => _buildHeader(
          title: PdfReportLabels.simpleReportTitle,
          subtitle: periodLabel,
          badgeLabel: PdfReportLabels.monthlySummary,
        ),
        footer: _buildFooter,
        build: (_) => [
          pw.SizedBox(height: 20),

          // ── Meta ──────────────────────────────────────────────────────
          _metaRow([
            _metaPair(PdfReportLabels.period, periodLabel),
            _metaPair(PdfReportLabels.currency, currencyCode),
            _metaPair(PdfReportLabels.distanceUnit, unitStr.toUpperCase()),
          ]),

          // ── Identity block ─────────────────────────────────────────────
          if (identityPairs.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _metaRow(identityPairs),
          ],

          pw.SizedBox(height: 24),

          // ── Distance summary ──────────────────────────────────────────
          _sectionTitle(PdfReportLabels.summary),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _statCard(
                  label: PdfReportLabels.totalDistance,
                  value: formatDistance(totalDistance, unit),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _statCard(
                  label: PdfReportLabels.businessDistance,
                  value: formatDistance(businessDistance, unit),
                  highlight: true,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _statCard(
                  label: PdfReportLabels.totalShifts,
                  value: '${shifts.length}',
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _statCard(
                  label: PdfReportLabels.taxDeduction,
                  value: PdfReportLabels.formatReportCurrency(
                    tax,
                    currencyCode,
                  ),
                  highlight: true,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ── Expenses ──────────────────────────────────────────────────
          _sectionTitle(PdfReportLabels.totalExpenses),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _statCard(
                  label: PdfReportLabels.fuel,
                  value: PdfReportLabels.formatReportCurrency(
                    totalFuel,
                    currencyCode,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _statCard(
                  label: PdfReportLabels.parking,
                  value: PdfReportLabels.formatReportCurrency(
                    totalParking,
                    currencyCode,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _statCard(
                  label: PdfReportLabels.tolls,
                  value: PdfReportLabels.formatReportCurrency(
                    totalTolls,
                    currencyCode,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _statCard(
                  label: PdfReportLabels.totalExpenses,
                  value: PdfReportLabels.formatReportCurrency(
                    totalExpenses,
                    currencyCode,
                  ),
                  highlight: true,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 28),

          // ── Platform breakdown (optional) ─────────────────────────────
          if (platformBreakdown.isNotEmpty) ...[
            _sectionTitle(PdfReportLabels.platformBreakdown),
            pw.SizedBox(height: 12),
            _platformTable(platformBreakdown, unit, unitStr),
          ],
          // NOTE: Simple PDF intentionally does not include a Trip Details table.
        ],
      ),
    );
  }

  // ─── Detailed report ──────────────────────────────────────────────────────

  void _buildDetailedPage({
    required pw.Document doc,
    required DateTime now,
    required String periodLabel,
    required String unitStr,
    required String currencyCode,
    required double totalDistance,
    required double businessDistance,
    required List<WorkShift> shifts,
    required List<Trip> trips,
    required AppUnit unit,
    required double totalFuel,
    required double totalParking,
    required double totalTolls,
    required double totalExpenses,
    String? driverName,
    String? businessName,
    String? vehicleName,
  }) {
    final identityPairs = _identityPairs(
        driverName: driverName,
        businessName: businessName,
        vehicleName: vehicleName);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => _buildHeader(
          title: PdfReportLabels.detailedReportTitle,
          // Period in the header subtitle so every page is self-contained.
          subtitle: periodLabel,
          badgeLabel: PdfReportLabels.reportTypeDetailed,
        ),
        footer: _buildFooter,
        build: (_) => [
          pw.SizedBox(height: 16),

          // ── Disclaimer note (page 1 only, inside build) ────────────────
          _disclaimerNote(),

          pw.SizedBox(height: 12),

          // ── Meta ──────────────────────────────────────────────────────
          _metaRow([
            _metaPair(
              PdfReportLabels.reportType,
              PdfReportLabels.reportTypeDetailed,
            ),
            _metaPair(PdfReportLabels.period, periodLabel),
            _metaPair(PdfReportLabels.currency, currencyCode),
            _metaPair(PdfReportLabels.distanceUnit, unitStr.toUpperCase()),
            _metaPair(
              PdfReportLabels.generatedOn,
              PdfReportLabels.formatLongDate(now),
            ),
          ]),

          // ── Identity block ─────────────────────────────────────────────
          if (identityPairs.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _metaRow(identityPairs),
          ],

          pw.SizedBox(height: 28),

          // ── Summary ───────────────────────────────────────────────────
          _sectionTitle(PdfReportLabels.summary),
          pw.SizedBox(height: 10),
          _detailedSummaryTable(
            totalDistance: totalDistance,
            businessDistance: businessDistance,
            trips: trips,
            unit: unit,
            unitStr: unitStr,
            currencyCode: currencyCode,
            totalFuel: totalFuel,
            totalParking: totalParking,
            totalTolls: totalTolls,
            totalExpenses: totalExpenses,
          ),

          pw.SizedBox(height: 32),

          // ── Work Shift Expenses (only when shifts exist) ───────────────
          if (shifts.isNotEmpty) ...[
            _sectionTitle(PdfReportLabels.workShiftExpenses),
            pw.SizedBox(height: 10),
            _shiftExpensesTable(shifts, currencyCode),
            pw.SizedBox(height: 32),
          ],

          // ── Trip Details (only when trips exist) ──────────────────────
          if (trips.isNotEmpty) ...[
            _sectionTitle(PdfReportLabels.tripDetails),
            pw.SizedBox(height: 10),
            _detailedTripTable(trips, unit, currencyCode),
          ],
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  pw.Widget _buildHeader({
    required String title,
    required String subtitle,
    required String badgeLabel,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _teal, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _teal,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(fontSize: 9, color: _grey),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _tealLight,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              badgeLabel,
              style: pw.TextStyle(
                fontSize: 10,
                color: _tealDark,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _divider, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            PdfReportLabels.generatedBy,
            style: pw.TextStyle(fontSize: 9, color: _grey),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} ${PdfReportLabels.pageOf} ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: _grey),
          ),
        ],
      ),
    );
  }

  // ─── Disclaimer note ──────────────────────────────────────────────────────

  pw.Widget _disclaimerNote() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: _noteYellow,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _noteYellowBorder, width: 0.5),
      ),
      child: pw.Text(
        PdfReportLabels.reportDisclaimer,
        style: pw.TextStyle(
          fontSize: 7,
          color: _grey,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  // ─── Meta row ─────────────────────────────────────────────────────────────

  pw.Widget _metaRow(List<pw.Widget> pairs) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _bgAlt,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _divider, width: 0.5),
      ),
      child: pw.Wrap(spacing: 24, runSpacing: 6, children: pairs),
    );
  }

  pw.Widget _metaPair(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontSize: 8, color: _grey),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _black,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section title ────────────────────────────────────────────────────────

  pw.Widget _sectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _grey,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 1, color: _divider),
      ],
    );
  }

  // ─── Stat card ────────────────────────────────────────────────────────────

  pw.Widget _statCard({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: highlight ? _tealLight : _bgCard,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: highlight ? _teal : _divider, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _grey)),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: highlight ? _teal : _black,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Detailed summary table ───────────────────────────────────────────────

  pw.Widget _detailedSummaryTable({
    required double totalDistance,
    required double businessDistance,
    required List<Trip> trips,
    required AppUnit unit,
    required String unitStr,
    required String currencyCode,
    required double totalFuel,
    required double totalParking,
    required double totalTolls,
    required double totalExpenses,
  }) {
    final rows = <_SummaryRow>[
      // ── Mileage group ──────────────────────────────────────────────
      _SummaryRow(PdfReportLabels.mileageGroup, '', isGroup: true),
      _SummaryRow(
        PdfReportLabels.totalDistance,
        formatDistance(totalDistance, unit),
      ),
      _SummaryRow(
        PdfReportLabels.businessDistance,
        formatDistance(businessDistance, unit),
      ),
      _SummaryRow(
        PdfReportLabels.personalDistance,
        formatDistance(totalDistance - businessDistance, unit),
      ),
      _SummaryRow(PdfReportLabels.totalTrips, '${trips.length}'),
      // ── Expenses group ─────────────────────────────────────────────
      _SummaryRow(PdfReportLabels.expensesGroup, '', isGroup: true),
      _SummaryRow(
        PdfReportLabels.fuel,
        PdfReportLabels.formatReportCurrency(totalFuel, currencyCode),
      ),
      _SummaryRow(
        PdfReportLabels.parking,
        PdfReportLabels.formatReportCurrency(totalParking, currencyCode),
      ),
      _SummaryRow(
        PdfReportLabels.tolls,
        PdfReportLabels.formatReportCurrency(totalTolls, currencyCode),
      ),
      _SummaryRow(
        PdfReportLabels.totalExpenses,
        PdfReportLabels.formatReportCurrency(totalExpenses, currencyCode),
        highlight: true,
      ),
    ];

    int dataRowIndex = 0; // separate alternating counter for non-group rows

    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        if (row.isGroup) {
          return pw.TableRow(
            decoration: const pw.BoxDecoration(color: _tealLight),
            children: [_tableCellGroup(row.label), pw.Container()],
          );
        }
        final isEven = dataRowIndex.isEven;
        dataRowIndex++;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: row.highlight
                ? _tealLight
                : (isEven ? PdfColors.white : _bgAlt),
          ),
          children: [
            _tableCell(
              row.label,
              bold: row.highlight,
              color: row.highlight ? _tealDark : _black,
            ),
            _tableCell(
              row.value,
              bold: row.highlight,
              color: row.highlight ? _tealDark : _black,
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─── Platform breakdown table ─────────────────────────────────────────────

  pw.Widget _platformTable(
    Map<String, double> breakdown,
    AppUnit unit,
    String unitStr,
  ) {
    final rows = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _teal),
          children: [
            _tableCell(PdfReportLabels.platform, isHeader: true),
            _tableCell(
              '${PdfReportLabels.distance} ($unitStr)',
              isHeader: true,
            ),
          ],
        ),
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : _bgAlt,
            ),
            children: [
              _tableCell(rows[i].key),
              _tableCell(formatDistance(rows[i].value, unit)),
            ],
          ),
      ],
    );
  }

  // ─── Work shift expenses table ────────────────────────────────────────────

  pw.Widget _shiftExpensesTable(List<WorkShift> shifts, String currencyCode) {
    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.8), // Platform — widest
        1: const pw.FlexColumnWidth(1.0), // Start
        2: const pw.FlexColumnWidth(1.0), // End
        3: const pw.FlexColumnWidth(1.1), // Fuel
        4: const pw.FlexColumnWidth(1.1), // Parking
        5: const pw.FlexColumnWidth(1.1), // Tolls
        6: const pw.FlexColumnWidth(1.4), // Total — slightly wider
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _teal),
          children: [
            _tableCell(PdfReportLabels.platform, isHeader: true),
            _tableCell(PdfReportLabels.start, isHeader: true),
            _tableCell(PdfReportLabels.end, isHeader: true),
            _tableCell(PdfReportLabels.fuel, isHeader: true),
            _tableCell(PdfReportLabels.parking, isHeader: true),
            _tableCell(PdfReportLabels.tolls, isHeader: true),
            _tableCell(PdfReportLabels.total, isHeader: true),
          ],
        ),
        for (int i = 0; i < shifts.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : _bgAlt,
            ),
            children: [
              _tableCell(shifts[i].platformName, maxLines: 1),
              _tableCell(_fmtTime(shifts[i].startHour, shifts[i].startMinute)),
              _tableCell(_fmtTime(shifts[i].endHour, shifts[i].endMinute)),
              _tableCell(
                PdfReportLabels.formatReportCurrency(
                  shifts[i].fuelExpense,
                  currencyCode,
                ),
              ),
              _tableCell(
                PdfReportLabels.formatReportCurrency(
                  shifts[i].parkingExpense,
                  currencyCode,
                ),
              ),
              _tableCell(
                PdfReportLabels.formatReportCurrency(
                  shifts[i].tollsExpense,
                  currencyCode,
                ),
              ),
              _tableCell(
                PdfReportLabels.formatReportCurrency(
                  shifts[i].totalExpenses,
                  currencyCode,
                ),
                bold: true,
              ),
            ],
          ),
      ],
    );
  }

  // ─── Detailed trip table ──────────────────────────────────────────────────

  pw.Widget _detailedTripTable(
    List<Trip> trips,
    AppUnit unit,
    String currencyCode,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5), // Date
        1: const pw.FlexColumnWidth(1.8), // From
        2: const pw.FlexColumnWidth(1.8), // To
        3: const pw.FlexColumnWidth(2.0), // Purpose (+notes)
        4: const pw.FlexColumnWidth(1.3), // Distance
        5: const pw.FlexColumnWidth(1.1), // Parking
        6: const pw.FlexColumnWidth(1.1), // Tolls
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _teal),
          children: [
            _tableCell(PdfReportLabels.date, isHeader: true),
            _tableCell(PdfReportLabels.from, isHeader: true),
            _tableCell(PdfReportLabels.to, isHeader: true),
            _tableCell(PdfReportLabels.purpose, isHeader: true),
            _tableCell(PdfReportLabels.distance, isHeader: true),
            _tableCell(PdfReportLabels.parking, isHeader: true),
            _tableCell(PdfReportLabels.tolls, isHeader: true),
          ],
        ),
        for (int i = 0; i < trips.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : _bgAlt,
            ),
            children: [
              _tableCell(
                PdfReportLabels.formatLongDate(trips[i].date),
                fontSize: 7,
              ),
              _tableCell(trips[i].from, maxLines: 2, fontSize: 7),
              _tableCell(trips[i].to, maxLines: 2, fontSize: 7),
              _tripPurposeCell(trips[i]),
              _tableCell(formatDistance(trips[i].distance, unit), fontSize: 7),
              _tableCell(
                PdfReportLabels.formatReportCurrency(
                  trips[i].parkingExpense,
                  currencyCode,
                ),
                fontSize: 7,
              ),
              _tableCell(
                PdfReportLabels.formatReportCurrency(
                  trips[i].tollsExpense,
                  currencyCode,
                ),
                fontSize: 7,
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _tripPurposeCell(Trip trip) {
    final purpose =
        (trip.businessPurpose != null && trip.businessPurpose!.isNotEmpty)
        ? trip.businessPurpose!
        : PdfReportLabels.businessPurposeFor(
            category: trip.category,
            platformName: trip.platformName,
          );

    if (trip.notes == null || trip.notes!.isEmpty) {
      return _tableCell(purpose, maxLines: 2, fontSize: 7);
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            purpose,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(fontSize: 7, color: _black),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            trip.notes!,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              fontSize: 6,
              color: _greyLight,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Table cell ───────────────────────────────────────────────────────────

  pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool bold = false,
    PdfColor? color,
    double? fontSize,
    int? maxLines,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: pw.Text(
        text,
        maxLines: maxLines,
        overflow: maxLines != null ? pw.TextOverflow.clip : null,
        style: pw.TextStyle(
          fontSize: fontSize ?? (isHeader ? 8 : 8),
          fontWeight: (isHeader || bold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : _black),
        ),
      ),
    );
  }

  // ─── Table group header cell ───────────────────────────────────────────────

  pw.Widget _tableCellGroup(String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: pw.Text(
        label.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _tealDark,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ─── Identity pairs ───────────────────────────────────────────────────────

  List<pw.Widget> _identityPairs({
    String? driverName,
    String? businessName,
    String? vehicleName,
  }) {
    final pairs = <pw.Widget>[];
    if (driverName != null && driverName.isNotEmpty) {
      pairs.add(_metaPair(PdfReportLabels.driver, driverName));
    }
    if (businessName != null && businessName.isNotEmpty) {
      pairs.add(_metaPair(PdfReportLabels.business, businessName));
    }
    if (vehicleName != null && vehicleName.isNotEmpty) {
      pairs.add(_metaPair(PdfReportLabels.vehicle, vehicleName));
    }
    return pairs;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

// ─── Internal data class ──────────────────────────────────────────────────────

class _SummaryRow {
  final String label;
  final String value;
  final bool highlight;
  final bool isGroup;
  const _SummaryRow(
    this.label,
    this.value, {
    this.highlight = false,
    this.isGroup = false,
  });
}
