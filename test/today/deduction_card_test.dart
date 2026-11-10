import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/tax/tax_service.dart';
import 'package:route_mint_app/features/today/deduction_card.dart';

void main() {
  final strings = AppStrings(AppLanguage.english);

  Widget host(
    Country country, {
    AppStrings? localized,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: Scaffold(
        body: SingleChildScrollView(
          child: DeductionCard(
            strings: localized ?? strings,
            country: country,
            title: (localized ?? strings).estimatedDeductionThisWeek,
            amount: 76,
            currencyCode: country == Country.usa ? 'USD' : 'CAD',
          ),
        ),
      ),
    ),
  );

  testWidgets('United States: the amount is labelled as an estimate', (
    tester,
  ) async {
    await tester.pumpWidget(host(Country.usa));

    expect(find.text('Estimated deduction this week'), findsOneWidget);
    expect(find.text('USD 76.00'), findsOneWidget);
    expect(find.text(strings.deductionEstimateNote), findsOneWidget);
  });

  testWidgets('Canada: a kilometer log note and no amount', (tester) async {
    await tester.pumpWidget(host(Country.canada));

    expect(find.text(strings.kilometerLogTitle), findsOneWidget);
    expect(find.text(strings.kilometerLogBody), findsOneWidget);
    expect(find.textContaining('76'), findsNothing);
    expect(find.text(strings.estimatedDeductionThisWeek), findsNothing);
  });

  testWidgets('both cards fit a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final language in AppLanguage.values) {
      for (final country in Country.values) {
        await tester.pumpWidget(
          host(
            country,
            localized: AppStrings(language),
            textScaler: const TextScaler.linear(2),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$language $country');
      }
    }
  });
}
