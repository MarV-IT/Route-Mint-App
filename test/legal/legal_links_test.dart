import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/legal/legal_links.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/shared/widgets/legal_consent_notice.dart';

void main() {
  test('documents open in the language of the app when the site has it', () {
    expect(
      LegalLinks.termsOfService(AppLanguage.french).toString(),
      'https://marvroute.com/terms/?lang=fr',
    );
    expect(
      LegalLinks.privacyPolicy(AppLanguage.ukrainian).toString(),
      'https://marvroute.com/privacy/?lang=uk',
    );
  });

  test('languages the site does not have fall back to English', () {
    for (final language in [
      AppLanguage.english,
      AppLanguage.spanish,
      AppLanguage.russian,
      AppLanguage.dari,
    ]) {
      expect(
        LegalLinks.privacyPolicy(language).queryParameters['lang'],
        'en',
        reason: '$language',
      );
      expect(
        LegalLinks.termsOfService(language).queryParameters['lang'],
        'en',
        reason: '$language',
      );
    }
  });

  testWidgets('the sign-in notice offers both documents', (tester) async {
    final strings = AppStrings(AppLanguage.english);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LegalConsentNotice(strings: strings)),
      ),
    );

    expect(find.text(strings.legalConsentNotice), findsOneWidget);
    expect(
      find.widgetWithText(TextButton, strings.termsOfService),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextButton, strings.privacyPolicy),
      findsOneWidget,
    );
  });

  testWidgets('the notice fits a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final language in AppLanguage.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: LegalConsentNotice(strings: AppStrings(language)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$language');
    }
  });
}
