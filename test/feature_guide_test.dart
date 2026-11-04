import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/features/guide/feature_guide_content.dart';
import 'package:route_mint_app/features/guide/feature_guide_screen.dart';

void main() {
  final uk = AppStrings(AppLanguage.ukrainian);

  Widget host({
    required VoidCallback onDone,
    AppLanguage language = AppLanguage.ukrainian,
    TextScaler textScaler = TextScaler.noScaling,
    TargetPlatform? platform,
  }) => MaterialApp(
    theme: ThemeData(platform: platform),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    // Keyed by language so each language starts its own fresh tour.
    home: FeatureGuideScreen(
      key: ValueKey(language),
      strings: AppStrings(language),
      onDone: onDone,
    ),
  );

  testWidgets('skip ends the guide straight away, once', (tester) async {
    var done = 0;
    await tester.pumpWidget(host(onDone: () => done++));

    expect(
      find.text(guideSteps(AppLanguage.ukrainian).first.title),
      findsOneWidget,
    );
    await tester.tap(find.text(uk.skipGuide));
    await tester.tap(find.text(uk.skipGuide), warnIfMissed: false);
    expect(done, 1);
  });

  testWidgets('next walks every step and the last one starts the app', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(host(onDone: () => done++));
    final steps = guideSteps(AppLanguage.ukrainian);

    for (var i = 0; i < steps.length - 1; i++) {
      expect(find.text(steps[i].title), findsOneWidget);
      expect(
        find.bySemanticsLabel(uk.guideStep(i + 1, steps.length)),
        findsOneWidget,
      );
      await tester.tap(find.text(uk.next));
      await tester.pumpAndSettle();
    }

    expect(find.text(steps.last.title), findsOneWidget);
    // The main button ends the tour on the last step, so Skip goes away.
    expect(find.text(uk.skipGuide).hitTestable(), findsNothing);
    expect(done, 0);
    await tester.tap(find.text(uk.getStarted));
    expect(done, 1);
  });

  testWidgets('swiping moves between steps too', (tester) async {
    await tester.pumpWidget(host(onDone: () {}));
    final steps = guideSteps(AppLanguage.ukrainian);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(steps[1].title), findsOneWidget);
  });

  test('every language has the same six steps, none blank', () {
    for (final language in AppLanguage.values) {
      final steps = guideSteps(language);
      expect(steps, hasLength(6), reason: '$language');
      for (final step in steps) {
        expect(step.title.trim(), isNotEmpty, reason: '$language');
        expect(step.body.trim(), isNotEmpty, reason: '$language');
      }
    }
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('$platform: every step in every language fits 320x568 at 3x '
        'text', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final language in AppLanguage.values) {
        await tester.pumpWidget(
          host(
            onDone: () {},
            language: language,
            platform: platform,
            textScaler: const TextScaler.linear(3),
          ),
        );
        final strings = AppStrings(language);
        for (var i = 0; i < 6; i++) {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$language step $i');
          // The end of a long step stays reachable by scrolling.
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -2000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$language step $i');
          if (i < 5) {
            await tester.tap(find.text(strings.next));
          }
        }
        expect(find.text(strings.getStarted), findsOneWidget);
      }
    });
  }
}
