import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/auth/auth_service.dart';
import 'package:route_mint_app/core/legal/legal_links.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/features/auth/auth_screen.dart';
import 'package:route_mint_app/shared/widgets/legal_consent_notice.dart';

class _ScreenAuth extends Fake implements AuthService {
  @override
  bool get supportsGoogleSignIn => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const launcher = MethodChannel('plugins.flutter.io/url_launcher');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, null);
  });

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

  testWidgets('legal notice precedes every account entry action', (
    tester,
  ) async {
    const strings = AppStrings(AppLanguage.english);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          strings: strings,
          authService: _ScreenAuth(),
          onContinueAsGuest: () {},
        ),
      ),
    );

    final noticeBottom = tester
        .getBottomLeft(find.byType(LegalConsentNotice))
        .dy;
    for (final action in [
      find.widgetWithText(FilledButton, strings.signIn),
      find.widgetWithText(OutlinedButton, strings.continueWithGoogle),
      find.widgetWithText(OutlinedButton, strings.continueWithoutAccount),
    ]) {
      expect(tester.getTopLeft(action).dy, greaterThan(noticeBottom));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('document buttons launch the localized URLs in the browser', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, (call) async {
          calls.add(call);
          return true;
        });
    const strings = AppStrings(AppLanguage.french);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LegalConsentNotice(strings: strings)),
      ),
    );
    await tester.tap(find.widgetWithText(TextButton, strings.termsOfService));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, strings.privacyPolicy));
    await tester.pumpAndSettle();

    expect(calls.map((call) => call.method), ['launch', 'launch']);
    expect(calls.map((call) => call.arguments['url']), [
      LegalLinks.termsOfService(AppLanguage.french).toString(),
      LegalLinks.privacyPolicy(AppLanguage.french).toString(),
    ]);
    for (final call in calls) {
      expect(call.arguments['useWebView'], isFalse);
      expect(call.arguments['useSafariVC'], isFalse);
    }
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'signup legal links and actions stay reachable with a keyboard and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        for (final language in AppLanguage.values) {
          final strings = AppStrings(language);
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(platform: platform),
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 568),
                  textScaler: TextScaler.linear(2),
                  viewInsets: EdgeInsets.only(bottom: 220),
                ),
                child: AuthScreen(
                  key: ValueKey('$platform-$language'),
                  strings: strings,
                  authService: _ScreenAuth(),
                  onContinueAsGuest: () {},
                ),
              ),
            ),
          );
          final register = find.widgetWithText(
            TextButton,
            strings.createAccount,
          );
          await tester.ensureVisible(register);
          await tester.tap(register);
          await tester.pumpAndSettle();
          for (final control in [
            find.widgetWithText(TextButton, strings.termsOfService),
            find.widgetWithText(TextButton, strings.privacyPolicy),
            find.widgetWithText(FilledButton, strings.createAccount),
            find.widgetWithText(OutlinedButton, strings.continueWithGoogle),
            find.widgetWithText(OutlinedButton, strings.continueWithoutAccount),
          ]) {
            await tester.ensureVisible(control);
            await tester.pumpAndSettle();
            expect(
              control.hitTestable(),
              findsOneWidget,
              reason: '$platform $language',
            );
          }
          expect(tester.takeException(), isNull, reason: '$platform $language');
        }
      }
    },
  );

  for (final throws in [false, true]) {
    testWidgets('failed legal launch shows the address (throws=$throws)', (
      tester,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(launcher, (_) async {
            if (throws) throw PlatformException(code: 'NO_BROWSER');
            return false;
          });
      const strings = AppStrings(AppLanguage.ukrainian);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LegalConsentNotice(strings: strings)),
        ),
      );
      await tester.tap(find.widgetWithText(TextButton, strings.privacyPolicy));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '${strings.couldNotOpenLink} ${LegalLinks.privacyPolicy(AppLanguage.ukrainian)}',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('late launch failure after leaving the screen is harmless', (
    tester,
  ) async {
    final result = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, (_) => result.future);
    const strings = AppStrings(AppLanguage.english);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LegalConsentNotice(strings: strings)),
      ),
    );
    await tester.tap(find.widgetWithText(TextButton, strings.privacyPolicy));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    result.complete(false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
