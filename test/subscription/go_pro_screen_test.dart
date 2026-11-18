import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/core/subscription/subscription_controller.dart';
import 'package:route_mint_app/core/subscription/subscription_models.dart';
import 'package:route_mint_app/features/subscription/go_pro_screen.dart';
import 'package:route_mint_app/features/subscription/subscription_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  const uk = AppStrings(AppLanguage.ukrainian);
  late FakeGateway gateway;
  late SubscriptionController subscription;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
    gateway = FakeGateway();
    subscription = SubscriptionController(
      gateway: gateway,
      clock: () => checkedAt,
    );
  });

  tearDown(() async {
    subscription.dispose();
    await gateway.close();
    AccountDataStore.resetForTesting();
  });

  /// Opens the Pro screen for a signed-in account, tall enough that the
  /// whole paywall is laid out at once.
  Future<void> open(
    WidgetTester tester, {
    SubscriptionController? controller,
    AppStrings strings = uk,
    Size size = const Size(420, 2600),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final target = controller ?? subscription;
    await tester.runAsync(() async {
      await AccountDataStore.activate('A');
      await target.attach(AccountDataStore.current);
      await pumpEventQueue();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: GoProScreen(
          key: ValueKey(strings.currentLanguage),
          strings: strings,
          subscription: target,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('before payments are switched on', () {
    testWidgets('the screen is what it was: benefits and "coming soon"', (
      tester,
    ) async {
      final off = SubscriptionController();
      addTearDown(off.dispose);
      await open(tester, controller: off);

      expect(find.text(uk.proUnlimitedReports), findsOneWidget);
      expect(find.text(uk.paymentsComingSoon), findsOneWidget);
      expect(find.text(uk.restorePurchase), findsNothing);
      expect(find.text(uk.subscribeNow), findsNothing);
    });
  });

  group('paywall', () {
    testWidgets('test payments are labelled and never claim store billing', (
      tester,
    ) async {
      final testStore = SubscriptionController(
        gateway: gateway,
        clock: () => checkedAt,
        isTestStore: true,
      );
      addTearDown(testStore.dispose);
      await open(tester, controller: testStore);
      expect(find.text(uk.testPaymentsNotice), findsNWidgets(2));
      expect(find.textContaining('Google Play'), findsNothing);
      gateway.push(activeAnnual);
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(find.text(uk.proActive), findsOneWidget);
      expect(find.text(uk.testPaymentsNotice), findsOneWidget);
      expect(find.text(uk.manageSubscription), findsNothing);
    });
    testWidgets('shows what Pro includes, both prices with their period, the '
        'trial, the renewal terms and the required links', (tester) async {
      await open(tester);

      // What is included, in short.
      for (final benefit in [
        uk.proUnlimitedReports,
        uk.proCloudBackup,
        uk.proAutoDetection,
        uk.proFuelSummaries,
        uk.proMonthlyCloseChecklist,
        uk.proMaintenanceReminders,
      ]) {
        expect(find.text(benefit), findsOneWidget, reason: benefit);
      }

      // Prices straight from the store, each with its period.
      expect(find.text(r'$39.99 / рік'), findsOneWidget);
      expect(find.text(r'$3.33 на місяць'), findsOneWidget);
      expect(find.text('Економія 33%'), findsOneWidget);
      expect(find.text(r'$4.99 / місяць'), findsOneWidget);
      expect(find.text('Безкоштовний період: 7 днів'), findsOneWidget);

      // The yearly plan is preselected, and it comes with a trial.
      expect(find.text(uk.startFreeTrial), findsOneWidget);
      final terms = find.textContaining(r'Підписка коштує $39.99 на рік');
      expect(terms, findsOneWidget);
      final termsText = tester.widget<Text>(terms).data!;
      expect(termsText, contains('Безкоштовний період: 7 днів.'));
      expect(termsText, contains('поновлюється автоматично'));
      expect(termsText, contains('Google Play'));
      expect(termsText, contains('24 години'));

      expect(find.text(uk.restorePurchase), findsOneWidget);
      expect(find.text(uk.termsOfService), findsOneWidget);
      expect(find.text(uk.privacyPolicy), findsOneWidget);
    });

    testWidgets('the price is the largest text on a plan', (tester) async {
      await open(tester);
      double size(String text) =>
          tester.widget<Text>(find.text(text)).style!.fontSize!;

      expect(size(r'$39.99 / рік'), greaterThan(size(uk.planAnnual)));
      expect(size(r'$39.99 / рік'), greaterThan(size(r'$3.33 на місяць')));
    });

    testWidgets('choosing the monthly plan changes the button and the terms', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text(r'$4.99 / місяць'));
      await tester.pump();

      // No trial on this plan, so no promise of one.
      expect(find.text(uk.subscribeNow), findsOneWidget);
      expect(find.text(uk.startFreeTrial), findsNothing);
      final terms = tester
          .widget<Text>(find.textContaining(r'Підписка коштує $4.99 на місяць'))
          .data!;
      expect(terms, isNot(contains('Безкоштовний період')));
    });

    testWidgets('on iPhone the terms name the App Store', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await open(tester);
      final terms = tester
          .widget<Text>(find.textContaining(r'Підписка коштує $39.99 на рік'))
          .data!;
      debugDefaultTargetPlatformOverride = null;

      expect(terms, contains('App Store'));
      expect(terms, isNot(contains('Google Play')));
    });

    testWidgets('a store with one plan shows it without a saving badge', (
      tester,
    ) async {
      gateway.offered = const [monthlyPlan];
      await open(tester);

      expect(find.text(r'$4.99 / місяць'), findsOneWidget);
      expect(find.textContaining('Економія'), findsNothing);
      expect(find.text(uk.subscribeNow), findsOneWidget);
    });

    testWidgets('plans that fail to load can be retried', (tester) async {
      gateway.plansFailure = const PurchaseFailure(PurchaseFailureKind.network);
      await open(tester);

      expect(find.text(uk.plansLoadFailed), findsOneWidget);
      expect(find.text(uk.startFreeTrial), findsNothing);
      // Restore and the documents stay reachable.
      expect(find.text(uk.restorePurchase), findsOneWidget);

      gateway.plansFailure = null;
      await tester.tap(find.text(uk.retry));
      await tester.pumpAndSettle();
      expect(find.text(r'$39.99 / рік'), findsOneWidget);
    });

    testWidgets('a store with nothing on sale says so', (tester) async {
      gateway.offered = const [];
      await open(tester);
      expect(find.text(uk.plansUnavailable), findsOneWidget);
      expect(find.text(uk.subscribeNow), findsNothing);
    });
  });

  group('buying', () {
    testWidgets('Pro is on at once and the screen shows the subscription', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text(uk.startFreeTrial));
      await tester.pumpAndSettle();

      expect(gateway.calls, contains(r'purchase:$rc_annual'));
      expect(subscription.isPremium, isTrue);
      expect(find.text(uk.proActivated), findsOneWidget);
      expect(find.text(uk.proActive), findsOneWidget);
      expect(find.text(uk.proPlanAnnual), findsOneWidget);
      expect(find.text('Поновиться 2027-11-12'), findsOneWidget);
      expect(find.text(uk.manageSubscription), findsOneWidget);
      // Nothing left to buy or restore.
      expect(find.text(uk.startFreeTrial), findsNothing);
      expect(find.text(uk.restorePurchase), findsNothing);
    });

    testWidgets('buys the plan that is selected', (tester) async {
      await open(tester);
      await tester.tap(find.text(r'$4.99 / місяць'));
      await tester.pump();
      await tester.tap(find.text(uk.subscribeNow));
      await tester.pumpAndSettle();

      expect(gateway.calls, contains(r'purchase:$rc_monthly'));
    });

    testWidgets('while the store is busy nothing else can be started', (
      tester,
    ) async {
      gateway.purchaseGate = Completer<void>();
      await open(tester);
      await tester.tap(find.text(uk.startFreeTrial));
      await tester.pump();

      FilledButton buy() =>
          tester.widget<FilledButton>(find.byType(FilledButton).last);
      expect(buy().onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, uk.restorePurchase),
            )
            .onPressed,
        isNull,
      );
      // A second tap, or switching plan mid-purchase, does nothing.
      await tester.tap(find.text(r'$4.99 / місяць'), warnIfMissed: false);
      await tester.pump();
      expect(
        gateway.calls.where((call) => call.startsWith('purchase')),
        hasLength(1),
      );

      gateway.purchaseGate!.complete();
      await tester.pumpAndSettle();
      expect(subscription.isPremium, isTrue);
    });

    testWidgets('closing the payment sheet is not an error', (tester) async {
      gateway.purchaseFailure = const PurchaseFailure(
        PurchaseFailureKind.cancelled,
      );
      await open(tester);
      await tester.tap(find.text(uk.startFreeTrial));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(subscription.isPremium, isFalse);
      // The paywall is still there and usable.
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNotNull,
      );
    });

    for (final (kind, message) in [
      (PurchaseFailureKind.pending, uk.purchasePending),
      (PurchaseFailureKind.network, uk.networkErrorCheckConnection),
      (PurchaseFailureKind.notAllowed, uk.purchaseNotAllowed),
      (PurchaseFailureKind.alreadyOwned, uk.purchaseAlreadyOwned),
      (PurchaseFailureKind.store, uk.purchaseFailed),
      (PurchaseFailureKind.unknown, uk.purchaseFailed),
    ]) {
      testWidgets('${kind.name}: says what happened and leaves Pro off', (
        tester,
      ) async {
        gateway.purchaseFailure = PurchaseFailure(kind);
        await open(tester);
        await tester.tap(find.text(uk.startFreeTrial));
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
        expect(subscription.isPremium, isFalse);
        expect(find.text(uk.startFreeTrial), findsOneWidget);
      });
    }

    testWidgets('a pending purchase switches the screen over when the store '
        'approves it', (tester) async {
      gateway.purchaseFailure = const PurchaseFailure(
        PurchaseFailureKind.pending,
      );
      await open(tester);
      await tester.tap(find.text(uk.startFreeTrial));
      await tester.pumpAndSettle();
      expect(find.text(uk.proActive), findsNothing);

      // Approved later, with the screen still open.
      await tester.runAsync(() async {
        gateway.push(activeAnnual);
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.text(uk.proActive), findsOneWidget);
    });
  });

  group('restoring', () {
    testWidgets('an earlier purchase turns Pro on', (tester) async {
      gateway.restored = activeAnnual;
      await open(tester);
      await tester.tap(find.text(uk.restorePurchase));
      await tester.pumpAndSettle();

      expect(find.text(uk.purchaseRestored), findsOneWidget);
      expect(find.text(uk.proActive), findsOneWidget);
    });

    testWidgets('nothing to restore is said plainly', (tester) async {
      await open(tester);
      await tester.tap(find.text(uk.restorePurchase));
      await tester.pumpAndSettle();

      expect(find.text(uk.nothingToRestore), findsOneWidget);
      expect(find.text(uk.startFreeTrial), findsOneWidget);
    });

    testWidgets('no connection is reported as such', (tester) async {
      gateway.restoreFailure = const PurchaseFailure(
        PurchaseFailureKind.network,
      );
      await open(tester);
      await tester.tap(find.text(uk.restorePurchase));
      await tester.pumpAndSettle();
      expect(find.text(uk.networkErrorCheckConnection), findsOneWidget);
    });
  });

  group('with Pro', () {
    final end = DateTime(2026, 12, 12, 10);

    testWidgets('a cancelled subscription shows how long Pro stays', (
      tester,
    ) async {
      gateway.byUser['A'] = stateWith(expiresAt: end, willRenew: false);
      await open(tester);

      expect(find.text(uk.proActive), findsOneWidget);
      expect(find.text(uk.proPlanMonthly), findsOneWidget);
      expect(find.text('Скасовано. Pro діє до 2026-12-12'), findsOneWidget);
      expect(find.text(uk.manageSubscription), findsOneWidget);
      expect(find.text(uk.termsOfService), findsOneWidget);
      // The store is not asked for plans nobody needs.
      expect(gateway.calls, isNot(contains('plans')));
    });

    testWidgets('a trial shows when it ends', (tester) async {
      gateway.byUser['A'] = stateWith(expiresAt: end, inTrial: true);
      await open(tester);
      expect(find.text('Безкоштовний період до 2026-12-12'), findsOneWidget);
    });

    testWidgets('a payment problem is called out', (tester) async {
      gateway.byUser['A'] = stateWith(expiresAt: end, hasBillingIssue: true);
      await open(tester);
      expect(find.text(uk.proBillingIssue), findsOneWidget);
    });

    testWidgets('bought on the other platform: says where to manage it', (
      tester,
    ) async {
      // Bought on an iPhone, opened on Android.
      gateway.byUser['A'] = stateWith(
        expiresAt: end,
        store: SubscriptionStore.appStore,
      );
      await open(tester);
      expect(find.text(uk.boughtInStore('App Store')), findsOneWidget);
      expect(find.text(uk.manageSubscription), findsOneWidget);
    });

    testWidgets('granted without a store: nothing to manage', (tester) async {
      gateway.byUser['A'] = stateWith(
        expiresAt: null,
        period: null,
        store: SubscriptionStore.other,
      );
      await open(tester);
      expect(find.text(uk.proActive), findsOneWidget);
      expect(find.text(uk.manageSubscription), findsNothing);
    });

    testWidgets('when Pro ends with the screen open, the plans come back', (
      tester,
    ) async {
      gateway.byUser['A'] = stateWith(expiresAt: end);
      await open(tester);
      expect(find.text(uk.proActive), findsOneWidget);

      await tester.runAsync(() async {
        gateway.push(
          stateWith(entitled: false, expiresAt: end, willRenew: false),
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();

      expect(find.text(uk.proActive), findsNothing);
      expect(find.text(r'$39.99 / рік'), findsOneWidget);
    });
  });

  group('promo codes', () {
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    late List<MethodCall> launched;

    setUp(() {
      launched = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(launcher, (call) async {
            launched.add(call);
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(launcher, null);
    });

    testWidgets('Android: the code is handed to Google Play to redeem', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text(uk.havePromoCode));
      await tester.pumpAndSettle();

      // Says plainly what a code gives before asking for it.
      expect(find.text(uk.promoCodeBody), findsOneWidget);
      expect(find.text(uk.promoCodeAlternative), findsOneWidget);
      FilledButton redeem() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, uk.redeemInGooglePlay),
      );
      expect(redeem().onPressed, isNull);

      await tester.enterText(find.byType(TextField), '  MARVFREE ');
      await tester.pump();
      expect(redeem().onPressed, isNotNull);
      await tester.tap(find.text(uk.redeemInGooglePlay));
      await tester.pumpAndSettle();

      expect(launched.map((call) => call.arguments['url']), [
        'https://play.google.com/redeem?code=MARVFREE',
      ]);
      expect(find.byType(AlertDialog), findsNothing);
      // The store call for iOS offer codes is not used here.
      expect(gateway.calls, isNot(contains('offerCode')));
    });

    testWidgets('Android: closing the dialog opens nothing', (tester) async {
      await open(tester);
      await tester.tap(find.text(uk.havePromoCode));
      await tester.pumpAndSettle();
      await tester.tap(find.text(uk.close));
      await tester.pumpAndSettle();

      expect(launched, isEmpty);
      expect(find.text(uk.startFreeTrial), findsOneWidget);
    });

    testWidgets('iPhone: opens the App Store sheet for offer codes', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await open(tester);
      await tester.tap(find.text(uk.havePromoCode));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;

      expect(gateway.calls, contains('offerCode'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(launched, isEmpty);
    });

    testWidgets('iPhone: a store problem is reported, not swallowed', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      gateway.offerCodeFailure = const PurchaseFailure(
        PurchaseFailureKind.network,
      );
      await open(tester);
      await tester.tap(find.text(uk.havePromoCode));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;

      expect(find.text(uk.networkErrorCheckConnection), findsOneWidget);
    });

    testWidgets('a subscription started by a code switches the screen over', (
      tester,
    ) async {
      await open(tester);
      // Redeemed in the Play Store; the store reports it afterwards.
      await tester.runAsync(() async {
        gateway.push(activeAnnual);
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();

      expect(find.text(uk.proActive), findsOneWidget);
      expect(find.text(uk.havePromoCode), findsNothing);
    });

    testWidgets('is not offered with test payments or before the store is on', (
      tester,
    ) async {
      final testStore = SubscriptionController(
        gateway: gateway,
        clock: () => checkedAt,
        isTestStore: true,
      );
      addTearDown(testStore.dispose);
      await open(tester, controller: testStore);
      expect(find.text(uk.restorePurchase), findsOneWidget);
      expect(find.text(uk.havePromoCode), findsNothing);
    });

    testWidgets('is not offered while payments are switched off', (
      tester,
    ) async {
      final off = SubscriptionController();
      addTearDown(off.dispose);
      await open(tester, controller: off);
      expect(find.text(uk.havePromoCode), findsNothing);
    });

    test('the Google Play link carries the code safely', () {
      expect(
        playRedeemUri(' MARV-7 ').toString(),
        'https://play.google.com/redeem?code=MARV-7',
      );
      expect(playRedeemUri('a b&c=d').queryParameters, {'code': 'a b&c=d'});
    });
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform: paywall and subscription view fit 320x568 at 3x '
        'text in every language', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      for (final language in AppLanguage.values) {
        // Each language starts as a customer who has not bought anything.
        SharedPreferences.setMockInitialValues({});
        final strings = AppStrings(language);
        // Built outside the test's fake clock, like the app's own controller,
        // so its store calls run when the screen waits for them.
        late FakeGateway store;
        late SubscriptionController controller;
        await tester.runAsync(() async {
          store = FakeGateway();
          controller = SubscriptionController(
            gateway: store,
            clock: () => checkedAt,
          );
        });

        await open(
          tester,
          controller: controller,
          strings: strings,
          size: const Size(320, 568),
          textScaler: const TextScaler.linear(3),
        );
        expect(tester.takeException(), isNull, reason: '$language paywall');

        // Everything down to the documents can be reached by scrolling.
        final list = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text(strings.privacyPolicy),
          300,
          scrollable: list,
          maxScrolls: 200,
        );
        expect(tester.takeException(), isNull, reason: '$language paywall');
        final buy = find.text(strings.startFreeTrial);
        await tester.scrollUntilVisible(
          buy,
          -200,
          scrollable: list,
          maxScrolls: 200,
        );
        // Scrolling back up finds the button just above the visible area;
        // bring all of it below the app bar, as a thumb would.
        for (var i = 0; i < 20; i++) {
          final view = tester.getRect(list);
          final button = tester.getRect(buy);
          if (button.top >= view.top && button.bottom <= view.bottom) break;
          final shift = button.top < view.top
              ? view.top - button.top + 40
              : view.bottom - button.bottom - 40;
          await tester.drag(list, Offset(0, shift));
          await tester.pumpAndSettle();
        }
        await tester.tap(buy);
        await tester.pumpAndSettle();
        expect(controller.isPremium, isTrue, reason: '$language');
        expect(tester.takeException(), isNull, reason: '$language active');

        // At this font size the confirmation message covers much of the
        // screen; let it go before scrolling what is underneath.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.drag(list, const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$language active');

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        await store.close();
        AccountDataStore.resetForTesting();
      }
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
