import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/preferences/user_preferences.dart';
import 'package:route_mint_app/core/tax/tax_service.dart';
import 'package:route_mint_app/features/whats_new/whats_new_content.dart';
import 'package:route_mint_app/features/whats_new/whats_new_dialog.dart';

void main() {
  final uk = AppStrings(AppLanguage.ukrainian);
  final setUp = UserPreferences.fromCountry(
    Country.usa,
  ).copyWith(onboardingCompleted: true, featureGuideCompleted: true);

  group('who sees the notes', () {
    test('someone who updated from an older version', () {
      // Saved by an older version: no guide flag, no notes flag.
      final json = setUp.toJson()
        ..remove('featureGuideCompleted')
        ..remove('whatsNewSeenVersion');
      expect(shouldShowWhatsNew(UserPreferences.fromJson(json)), isTrue);
    });

    test('not again once closed for this version', () {
      expect(
        shouldShowWhatsNew(
          setUp.copyWith(whatsNewSeenVersion: whatsNewVersion),
        ),
        isFalse,
      );
      // A later version brings them back.
      expect(
        shouldShowWhatsNew(setUp.copyWith(whatsNewSeenVersion: '1.0.0')),
        isTrue,
      );
    });

    test('not a brand-new user, who gets the guide instead', () {
      final fresh = UserPreferences.fromCountry(Country.usa);
      expect(shouldShowWhatsNew(fresh), isFalse);
      expect(
        shouldShowWhatsNew(fresh.copyWith(onboardingCompleted: true)),
        isFalse,
      );
    });

    test('the seen version survives a save and reload', () {
      final seen = setUp.copyWith(whatsNewSeenVersion: whatsNewVersion);
      expect(
        UserPreferences.fromJson(seen.toJson()).whatsNewSeenVersion,
        whatsNewVersion,
      );
    });
  });

  test('the notes are for the version being released', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9.]+)\+',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(whatsNewVersion, version);
  });

  test('every language lists the same changes, none blank', () {
    final count = whatsNewItems(AppLanguage.english).length;
    for (final language in AppLanguage.values) {
      final items = whatsNewItems(language);
      expect(items, hasLength(count), reason: '$language');
      for (final item in items) {
        expect(item.title.trim(), isNotEmpty, reason: '$language');
        expect(item.body.trim(), isNotEmpty, reason: '$language');
      }
    }
  });

  Widget gateHost(
    UserPreferences prefs,
    VoidCallback onSeen, {
    TextScaler textScaler = TextScaler.noScaling,
    AppLanguage language = AppLanguage.ukrainian,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: WhatsNewGate(
      preferences: prefs,
      strings: AppStrings(language),
      onSeen: onSeen,
      child: const Scaffold(body: Text('main')),
    ),
  );

  testWidgets('opens over the app after an update and closes with the X', (
    tester,
  ) async {
    var seen = 0;
    await tester.pumpWidget(gateHost(setUp, () => seen++));
    await tester.pumpAndSettle();

    expect(find.text(uk.whatsNewTitle(whatsNewVersion)), findsOneWidget);
    for (final item in whatsNewItems(AppLanguage.ukrainian)) {
      expect(find.text(item.title), findsOneWidget);
    }
    expect(seen, 0);

    await tester.tap(find.byTooltip(uk.close));
    await tester.pumpAndSettle();
    expect(find.byType(WhatsNewDialog), findsNothing);
    expect(find.text('main'), findsOneWidget);
    expect(seen, 1);
  });

  testWidgets('the close button sits in the top right corner', (tester) async {
    await tester.pumpWidget(gateHost(setUp, () {}));
    await tester.pumpAndSettle();

    // The window itself, not the full-screen area around it.
    final dialog = tester.getRect(
      find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first,
    );
    final close = tester.getRect(find.byTooltip(uk.close));
    expect(close.right, greaterThan(dialog.right - 24));
    expect(close.top, lessThan(dialog.top + 24));
  });

  testWidgets('stays away once seen', (tester) async {
    var seen = 0;
    await tester.pumpWidget(
      gateHost(
        setUp.copyWith(whatsNewSeenVersion: whatsNewVersion),
        () => seen++,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WhatsNewDialog), findsNothing);
    expect(seen, 0);
  });

  testWidgets('every language fits 320x568 at 3x text, X still reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final language in AppLanguage.values) {
      var seen = 0;
      // Keyed so each language gets a fresh gate that shows the notes.
      await tester.pumpWidget(
        KeyedSubtree(
          key: ValueKey(language),
          child: gateHost(
            setUp,
            () => seen++,
            language: language,
            textScaler: const TextScaler.linear(3),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$language');

      await tester.drag(
        find.descendant(
          of: find.byType(WhatsNewDialog),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$language');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewDialog), findsNothing, reason: '$language');
      expect(seen, greaterThanOrEqualTo(1), reason: '$language');
    }
  });
}
