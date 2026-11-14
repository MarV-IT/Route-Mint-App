import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/review/review_prompt_host.dart';
import 'package:route_mint_app/core/review/review_settings.dart';

import 'review_fakes.dart';

Future<void> advance(WidgetTester tester, ReviewHarness h, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    h.elapsed += const Duration(seconds: 1);
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<ReviewHarness> host(
  WidgetTester tester, {
  bool eligible = true,
  bool Function()? tracking,
  ValueNotifier<bool>? homeEnabled,
  GlobalKey<NavigatorState>? navigator,
  GlobalKey<ScaffoldMessengerState>? messenger,
  Widget child = const Text('Home'),
}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  final h = ReviewHarness();
  await h.start(eligible: eligible);
  final activity = ReviewActivity(elapsed: () => h.elapsed);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      scaffoldMessengerKey: messenger,
      navigatorObservers: [ReviewNavigationObserver(activity)],
      builder: (context, child) => ReviewPromptHost(
        service: h.service,
        activity: activity,
        isTracking: tracking ?? () => false,
        child: child!,
      ),
      home: homeEnabled == null
          ? ReviewHome(enabled: true, child: Scaffold(body: child))
          : ValueListenableBuilder<bool>(
              valueListenable: homeEnabled,
              builder: (_, enabled, _) => ReviewHome(
                enabled: enabled,
                child: Scaffold(body: child),
              ),
            ),
    ),
  );
  await tester.pump();
  return h;
}

void main() {
  testWidgets('successful trip save gets two quiet seconds before requesting', (
    tester,
  ) async {
    final h = await host(tester);
    await advance(tester, h, 9);
    await h.service.recordCompletedTrip('A', 'new');
    await advance(tester, h, 1);
    expect(h.gateway.requests, 0);
    await advance(tester, h, 1);
    expect(h.gateway.requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('feedback before eligibility still postpones a later trigger', (
    tester,
  ) async {
    final messenger = GlobalKey<ScaffoldMessengerState>();
    final h = await host(tester, eligible: false, messenger: messenger);
    messenger.currentState!.showSnackBar(
      const SnackBar(content: Text('Error'), duration: Duration(seconds: 2)),
    );
    await advance(tester, h, 5);
    for (var i = 0; i < 10; i++) {
      await h.service.recordCompletedTrip('A', '$i');
    }
    await advance(tester, h, 10);
    expect(h.gateway.requests, 0);
    await advance(tester, h, 25);
    expect(h.gateway.requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('quiet open waits, requests once and survives home rebuilds', (
    tester,
  ) async {
    final enabled = ValueNotifier(true);
    final h = await host(tester, homeEnabled: enabled);
    await advance(tester, h, 9);
    expect(h.gateway.requests, 0);
    await advance(tester, h, 2);
    expect(h.gateway.requests, 1);
    enabled.value = false;
    await tester.pump();
    enabled.value = true;
    await advance(tester, h, 30);
    expect(h.gateway.requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('onboarding/other tabs and tracking defer until quiet home', (
    tester,
  ) async {
    var tracking = true;
    final enabled = ValueNotifier(false);
    final h = await host(
      tester,
      homeEnabled: enabled,
      tracking: () => tracking,
    );
    await advance(tester, h, 15);
    expect(h.gateway.requests, 0);
    enabled.value = true;
    await advance(tester, h, 15);
    expect(h.gateway.requests, 0);
    tracking = false;
    await advance(tester, h, 3);
    expect(h.gateway.requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('modal dialog and its dismissal defer requests', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final h = await host(tester, navigator: navigator);
    showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const AlertDialog(content: Text('Hint or paywall')),
    );
    await advance(tester, h, 15);
    expect(h.gateway.requests, 0);
    navigator.currentState!.pop();
    await advance(tester, h, 29);
    expect(h.gateway.requests, 0);
    await advance(tester, h, 3);
    expect(h.gateway.requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('error feedback is followed by a quiet cooldown', (tester) async {
    final messenger = GlobalKey<ScaffoldMessengerState>();
    final h = await host(tester, messenger: messenger);
    messenger.currentState!.showSnackBar(
      const SnackBar(
        content: Text('Payment failed'),
        duration: Duration(seconds: 2),
      ),
    );
    await advance(tester, h, 20);
    expect(h.gateway.requests, 0);
    await advance(tester, h, 20);
    expect(h.gateway.requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('inactive/locked/background screen never requests', (
    tester,
  ) async {
    final h = await host(tester);
    await advance(tester, h, 8);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await advance(tester, h, 20);
    expect(h.gateway.requests, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await advance(tester, h, 20);
    expect(h.gateway.requests, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await advance(tester, h, 9);
    expect(h.gateway.requests, 0);
    await advance(tester, h, 2);
    expect(h.gateway.requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'touch/long press prevents a request until interaction finishes',
    (tester) async {
      final h = await host(tester);
      final gesture = await tester.startGesture(const Offset(50, 50));
      await advance(tester, h, 15);
      expect(h.gateway.requests, 0);
      await gesture.up();
      await advance(tester, h, 1);
      expect(h.gateway.requests, 0);
      await advance(tester, h, 2);
      expect(h.gateway.requests, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('keyboard/focused input prevents native review', (tester) async {
    final h = await host(tester, child: const TextField());
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await advance(tester, h, 15);
    expect(h.gateway.requests, 0);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await advance(tester, h, 4);
    expect(h.gateway.requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'settings persist opt-out, open store, then disable auto toggle',
    (tester) async {
      final h = ReviewHarness();
      await h.start(eligible: true);
      const strings = AppStrings(AppLanguage.ukrainian);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewSettings(strings: strings, service: h.service),
          ),
        ),
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(h.service.state.optedOut, true);
      await tester.tap(find.text(strings.rateApp));
      await tester.pumpAndSettle();
      expect(h.gateway.storeOpens, 1);
      expect(h.gateway.requests, 0);
      expect(find.text(strings.reviewRequestsStopped), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
    },
  );

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final language in AppLanguage.values) {
      testWidgets(
        'rating settings fit small $platform screen, 200% text, $language',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = ReviewHarness();
          await h.start();
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(platform: platform),
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2),
                  size: Size(320, 568),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ReviewSettings(
                        strings: AppStrings(language),
                        service: h.service,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
