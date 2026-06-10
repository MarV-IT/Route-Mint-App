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
}
