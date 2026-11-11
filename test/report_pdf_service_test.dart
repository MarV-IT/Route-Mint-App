import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// The printing plugin uses this interface for platform implementations/tests.
// ignore: implementation_imports
import 'package:printing/src/interface.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/pdf/report_pdf_service.dart';
import 'package:route_mint_app/core/tax/tax_service.dart';

class _CapturingPrinting extends PrintingPlatform {
  Uint8List? document;

  @override
  Future<bool> layoutPdf(
    Printer? printer,
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
    bool dynamicLayout,
    bool usePrinterSettings,
    OutputType outputType,
    bool forceCustomPrintPaper,
    bool windowsModernDialog,
  ) async {
    document = await onLayout(format);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Extract the standard-font literal strings from the generated PDF content
// streams. This checks the exported document, not just the label constants.
String _documentText(Uint8List bytes) {
  final raw = latin1.decode(bytes);
  final strings = <String>[];
  for (final stream in RegExp(
    r'stream\r?\n([\s\S]*?)\r?\nendstream',
  ).allMatches(raw)) {
    var content = stream.group(1)!;
    try {
      content = latin1.decode(zlib.decode(latin1.encode(content)));
    } on FormatException {
      // Uncompressed streams need no decoding.
    }
    for (final literal in RegExp(r'\((?:\\.|[^\\)])*\)').allMatches(content)) {
      final text = literal.group(0)!;
      strings.add(
        text
            .substring(1, text.length - 1)
            .replaceAllMapped(
              RegExp(r'\\([()\\])'),
              (match) => match.group(1)!,
            ),
      );
    }
  }
  return strings.join(' ').replaceAll(RegExp(r'\s+'), ' ');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PrintingPlatform original;
  late _CapturingPrinting printing;

  setUp(() {
    original = PrintingPlatform.instance;
    printing = _CapturingPrinting();
    PrintingPlatform.instance = printing;
  });
  tearDown(() => PrintingPlatform.instance = original);

  Future<String> generate(Country country) async {
    await ReportPdfService().generateReport(
      trips: const [],
      totalDistance: 100,
      businessDistance: 60,
      tax: 1234.56,
      platformBreakdown: const {},
      country: country,
      unit: AppUnit.kilometers,
      currencyCode: country == Country.usa ? 'USD' : 'CAD',
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 30),
    );
    expect(printing.document, isNotNull);
    expect(latin1.decode(printing.document!.take(5).toList()), '%PDF-');
    return _documentText(printing.document!);
  }

  test('US PDF exports an estimate and its explanation', () async {
    final text = await generate(Country.usa);
    expect(text, contains('Est. Deduction (IRS Rate)'));
    expect(text, contains('USD 1234.56'));
    expect(text, contains('estimate at the IRS standard mileage rate'));
    expect(text, contains('Not tax advice.'));
  });

  test('Canada PDF never exports a supplied deduction amount', () async {
    final text = await generate(Country.canada);
    expect(text, contains('Personal Distance'));
    expect(text, contains('40.0 km'));
    expect(text, isNot(contains('1234.56')));
    expect(text, isNot(contains('IRS')));
    expect(text, contains('No deduction amount is calculated for Canada'));
  });
}
