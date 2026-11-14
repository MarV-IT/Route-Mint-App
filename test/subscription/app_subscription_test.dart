import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/auth/account_session_service.dart';
import 'package:route_mint_app/core/preferences/preferences_service.dart';
import 'package:route_mint_app/core/preferences/user_preferences.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/core/subscription/subscription_controller.dart';
import 'package:route_mint_app/core/subscription/subscription_models.dart';
import 'package:route_mint_app/core/tax/tax_service.dart';
import 'package:route_mint_app/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
}

class _Auth extends Fake implements FirebaseAuth {
  final controller = StreamController<User?>.broadcast(sync: true);
  User? _user;
  @override
  User? get currentUser => _user;
  @override
  Stream<User?> authStateChanges() => controller.stream;
  void emit(String uid) {
    _user = _User(uid);
    controller.add(_user);
  }
}

class _DelayedPreferences extends PreferencesService {
  _DelayedPreferences({required super.scope, required this.gate});
  final Completer<void> gate;
  final loaded = Completer<void>();

  @override
  Future<UserPreferences> loadPreferences() async {
    final stored = await super.loadPreferences();
    loaded.complete();
    await gate.future;
    return stored;
  }
}

/// The app shell from launch to its first screen, with a store that knows
/// one customer. Onboarding is left unfinished so the test stays clear of
/// the sign-in screen; preferences are loaded and corrected before it.
void main() {
  late _Auth auth;
  late AccountSessionService session;
  late FakeGateway gateway;
  late SubscriptionController subscription;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
  });

  Future<void> launch(
    WidgetTester tester, {
    required SubscriptionStatus stored,
  }) async {
    await tester.runAsync(() async {
      auth = _Auth();
      session = AccountSessionService(
        auth: auth,
        beforeSwitch: () async {},
        afterSwitch: () {},
      );
      gateway = FakeGateway();
      subscription = SubscriptionController(
        gateway: gateway,
        clock: () => checkedAt,
      );
      auth.emit('A');
      await session.initialize();
      // What the previous launch, or a restored backup, left in storage.
      await PreferencesService().savePreferences(
        UserPreferences.fromCountry(
          Country.canada,
        ).copyWith(subscriptionStatus: stored, driverName: 'Dana'),
      );
    });
    addTearDown(() async {
      subscription.dispose();
      session.dispose();
      await auth.controller.close();
      await gateway.close();
    });
  }

  Future<UserPreferences> storedPreferences(WidgetTester tester) async {
    late UserPreferences preferences;
    await tester.runAsync(() async {
      preferences = await PreferencesService().loadPreferences();
    });
    return preferences;
  }

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(
      RouteMintApp(accountSession: session, subscription: subscription),
    );
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  }

  testWidgets(
    'late preferences from A cannot overwrite B during Pro correction',
    (tester) async {
      await launch(tester, stored: SubscriptionStatus.pro);
      final gate = Completer<void>();
      final delayed = _DelayedPreferences(
        scope: AccountDataStore.current,
        gate: gate,
      );
      await tester.pumpWidget(
        RouteMintApp(
          accountSession: session,
          subscription: subscription,
          preferencesFactory: (scope) =>
              scope.uid == 'A' ? delayed : PreferencesService(scope: scope),
        ),
      );
      await tester.runAsync(() => delayed.loaded.future);
      await tester.runAsync(() async {
        auth.emit('B');
        await session.synchronize();
        await pumpEventQueue();
        await PreferencesService().savePreferences(
          UserPreferences.fromCountry(
            Country.usa,
          ).copyWith(driverName: 'B owner'),
        );
        gate.complete();
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      final preferences = await storedPreferences(tester);
      expect(preferences.driverName, 'B owner');
      expect(preferences.country, Country.usa);
      expect(preferences.subscriptionStatus, SubscriptionStatus.free);
      expect(subscription.isPremium, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a stored "pro" the store does not confirm is not Pro', (
    tester,
  ) async {
    await launch(tester, stored: SubscriptionStatus.pro);
    await start(tester);

    final preferences = await storedPreferences(tester);
    expect(preferences.subscriptionStatus, SubscriptionStatus.free);
    // Everything else the user set up is left exactly as it was.
    expect(preferences.driverName, 'Dana');
    expect(preferences.country, Country.canada);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a subscriber is Pro from the first frame of the next launch, '
      'even with no connection', (tester) async {
    await launch(tester, stored: SubscriptionStatus.free);
    // Confirmed by the store on an earlier launch.
    await tester.runAsync(() async {
      final scoped = await AccountDataStore.current.getPreferences();
      await scoped.setString(
        SubscriptionController.snapshotKey,
        jsonEncode(activeAnnual.toJson()),
      );
    });
    const offline = PurchaseFailure(PurchaseFailureKind.network);
    gateway
      ..connectFailure = offline
      ..stateFailure = offline;

    await start(tester);

    expect(subscription.isPremium, isTrue);
    expect(
      (await storedPreferences(tester)).subscriptionStatus,
      SubscriptionStatus.pro,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Pro bought on another device arrives when the store answers', (
    tester,
  ) async {
    await launch(tester, stored: SubscriptionStatus.free);
    gateway.byUser['A'] = activeAnnual;

    await start(tester);

    expect(gateway.calls, containsAllInOrder(['start:A', 'state']));
    expect(
      (await storedPreferences(tester)).subscriptionStatus,
      SubscriptionStatus.pro,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('coming back to the app asks the store again', (tester) async {
    await launch(tester, stored: SubscriptionStatus.free);
    gateway.byUser['A'] = activeAnnual;
    await start(tester);
    final before = gateway.calls.where((call) => call == 'state').length;

    // Refunded while the app was in the background.
    gateway.byUser['A'] = stateWith(
      entitled: false,
      expiresAt: checkedAt,
      willRenew: false,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    expect(
      gateway.calls.where((call) => call == 'state').length,
      greaterThan(before),
    );
    expect(subscription.isPremium, isFalse);
    expect(
      (await storedPreferences(tester)).subscriptionStatus,
      SubscriptionStatus.free,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
