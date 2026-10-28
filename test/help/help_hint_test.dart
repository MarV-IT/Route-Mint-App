import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/help/help_analytics.dart';
import 'package:route_mint_app/core/help/help_catalog.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/localization/app_strings_scope.dart';
import 'package:route_mint_app/shared/widgets/help_hint.dart';

class _RecordingAnalytics implements HelpAnalytics {
  final opened = <String>[];

  @override
  void helpOpened(String topicId) => opened.add(topicId);
}

void main() {
  late _RecordingAnalytics analytics;

  setUp(() {
    analytics = _RecordingAnalytics();
    helpAnalytics = analytics;
  });
  tearDown(() => helpAnalytics = const DebugHelpAnalytics());

  Widget host(
    HelpTopic topic, {
    AppLanguage language = AppLanguage.ukrainian,
    TextScaler textScaler = TextScaler.noScaling,
    TargetPlatform? platform,
  }) => MaterialApp(
    theme: ThemeData(platform: platform),
    builder: (context, child) => AppStringsScope(
      strings: AppStrings(language),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
    ),
    home: Scaffold(
      appBar: AppBar(title: const Text('Title'), actions: [HelpHint(topic)]),
    ),
  );

  testWidgets('reads as "Help: <feature>" to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(HelpTopic.reports));

    // IconButton exposes its tooltip as the node's spoken description, which
    // TalkBack and VoiceOver announce along with "button".
    expect(
      tester.getSemantics(find.byType(IconButton)),
      isSemantics(
        tooltip: 'Пояснення: Звіти',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the touch target meets both platform minimums', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(HelpTopic.reports));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('opens the topic text in place and records help_opened', (
    tester,
  ) async {
    await tester.pumpWidget(host(HelpTopic.reports));
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    final entry = helpEntry(HelpTopic.reports, AppLanguage.ukrainian);
    expect(find.text('Звіти'), findsOneWidget);
    expect(find.text(entry.body), findsOneWidget);
    expect(analytics.opened, ['reports']);
  });

  testWidgets('shows the example with its lead-in when the topic has one', (
    tester,
  ) async {
    await tester.pumpWidget(host(HelpTopic.addTrip));
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Наприклад: Uber, 12 км', findRichText: true),
      findsOneWidget,
    );
  });

  group('closes', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(host(HelpTopic.trips));
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();
      expect(find.byType(HelpSheet), findsOneWidget);
    }

    testWidgets('with the close button', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Закрити'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpSheet), findsNothing);
    });

    testWidgets('with a tap outside the sheet', (tester) async {
      await open(tester);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byType(HelpSheet), findsNothing);
    });

    testWidgets('with a swipe down', (tester) async {
      await open(tester);
      await tester.fling(find.byType(HelpSheet), const Offset(0, 600), 1500);
      await tester.pumpAndSettle();
      expect(find.byType(HelpSheet), findsNothing);
    });
  });

  testWidgets('falls back to English outside the app shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: const [HelpHint(HelpTopic.home)]),
        ),
      ),
    );
    expect(find.byTooltip('Help: Home'), findsOneWidget);
  });

  // The spec's acceptance check: smallest phone, largest system font. iOS
  // accessibility sizes reach about 3.1x, so this goes beyond Android's 2x.
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('$platform: every topic in every language fits 320x568 at 3x '
        'text', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final topic in HelpTopic.values) {
        for (final language in AppLanguage.values) {
          await tester.pumpWidget(
            host(
              topic,
              language: language,
              platform: platform,
              textScaler: const TextScaler.linear(3),
            ),
          );
          await tester.tap(find.byIcon(Icons.help_outline));
          await tester.pumpAndSettle();
          expect(
            find.byType(HelpSheet),
            findsOneWidget,
            reason: '${topic.id} / $language did not open',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${topic.id} / $language',
          );

          // The end of the text must stay reachable by scrolling.
          await tester.drag(find.byType(HelpSheet), const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Only the close button is pinned (the title scrolls with the
          // text), so it is still there after scrolling to the end.
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
          expect(
            find.byType(HelpSheet),
            findsNothing,
            reason: '${topic.id} / $language: close scrolled out of reach',
          );
        }
      }
    });
  }
}
