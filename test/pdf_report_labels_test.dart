import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/pdf/pdf_report_labels.dart';

void main() {
  group('PdfReportLabels.exportPurposeFor', () {
    test('uses English platform purpose for localized saved purpose', () {
      final purpose = PdfReportLabels.exportPurposeFor(
        category: 'business',
        platformName: 'Spark Driver',
        businessPurpose: 'Доставка Spark Driver',
      );

      expect(purpose, 'Spark Driver business trip');
    });

    test('keeps English custom purpose unchanged', () {
      final purpose = PdfReportLabels.exportPurposeFor(
        category: 'business',
        platformName: 'Uber',
        businessPurpose: 'Airport pickup',
      );

      expect(purpose, 'Airport pickup');
    });
  });

  group('PdfReportLabels.summaryNote', () {
    test('calls the US deduction an estimate', () {
      final note = PdfReportLabels.summaryNote(showsDeduction: true);

      expect(note, startsWith(PdfReportLabels.reportDisclaimer));
      expect(note, contains('estimate at the IRS standard mileage rate'));
      expect(note, endsWith('Not tax advice.'));
    });

    test('says no amount is calculated for Canada', () {
      final note = PdfReportLabels.summaryNote(showsDeduction: false);

      expect(note, startsWith(PdfReportLabels.reportDisclaimer));
      expect(note, contains('No deduction amount is calculated for Canada'));
      expect(note, isNot(contains('IRS')));
    });

    test('uses only characters the PDF font can draw', () {
      for (final showsDeduction in [true, false]) {
        final note = PdfReportLabels.summaryNote(
          showsDeduction: showsDeduction,
        );
        expect(
          note.codeUnits.every((unit) => unit >= 0x20 && unit <= 0x7E),
          isTrue,
          reason: 'showsDeduction: $showsDeduction',
        );
      }
    });
  });
}
