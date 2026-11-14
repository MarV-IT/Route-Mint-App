import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/preferences/user_preferences.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/core/subscription/subscription_controller.dart';
import 'package:route_mint_app/core/subscription/entitlement_service.dart';
import 'package:route_mint_app/core/subscription/subscription_models.dart';
import 'package:route_mint_app/core/tax/tax_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

const _offline = PurchaseFailure(PurchaseFailureKind.network, 'offline');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeGateway gateway;
  late DateTime now;
  late SubscriptionController controller;
  var notifications = 0;

  SubscriptionController newController([FakeGateway? store]) =>
      SubscriptionController(gateway: store ?? gateway, clock: () => now)
        ..addListener(() => notifications++);

  /// Makes [uid] the app's active account, as signing in does.
  Future<AccountDataScope> account(String? uid) async {
    await AccountDataStore.activate(uid);
    return AccountDataStore.current;
  }

  /// Attaches and waits for the background store calls to finish.
  Future<void> attach(SubscriptionController target, String? uid) async {
    await target.attach(await account(uid));
    await pumpEventQueue();
  }

  Future<SubscriptionState> savedFor(String? uid) async {
    final preferences = await (await account(uid)).getPreferences();
    final raw = preferences.getString(SubscriptionController.snapshotKey);
    return raw == null
        ? SubscriptionState.none
        : SubscriptionState.fromJson(jsonDecode(raw));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
    gateway = FakeGateway();
    now = checkedAt;
    notifications = 0;
    controller = newController();
  });

  tearDown(() async {
    controller.dispose();
    await gateway.close();
    AccountDataStore.resetForTesting();
  });

  group('before payments are switched on', () {
    test(
      'without a store, valid saved subscription statuses are preserved',
      () {
        final off = SubscriptionController();
        addTearDown(off.dispose);

        expect(off.storeEnabled, isFalse);
        expect(off.isPremium, isFalse);
        for (final stored in SubscriptionStatus.values) {
          expect(off.statusFor(stored), stored);
        }
      },
    );

    test('buying is refused rather than silently doing nothing', () async {
      final off = SubscriptionController();
      addTearDown(off.dispose);
      await off.attach(await account('A'));

      await expectLater(off.loadPlans(), throwsA(isA<PurchaseFailure>()));
      await expectLater(off.restore(), throwsA(isA<PurchaseFailure>()));
    });
  });

  group('at launch', () {
    test('asks the store for the signed-in account and turns Pro on', () async {
      gateway.byUser['A'] = activeAnnual;

      await attach(controller, 'A');

      expect(gateway.calls, ['start:A', 'state']);
      expect(controller.isPremium, isTrue);
      expect(controller.state, activeAnnual);
      expect(notifications, greaterThan(0));
      expect(await savedFor('A'), activeAnnual);
    });

    test('a guest is an anonymous customer', () async {
      await attach(controller, null);
      expect(gateway.calls, ['start:null', 'state']);
      expect(controller.isPremium, isFalse);
    });

    test('Pro is back before the store answers, and offline', () async {
      gateway.byUser['A'] = activeAnnual;
      await attach(controller, 'A');

      // Next cold start with no connection at all.
      final offlineStore = FakeGateway()
        ..connectFailure = _offline
        ..stateFailure = _offline;
      final restarted = newController(offlineStore);
      addTearDown(restarted.dispose);
      addTearDown(offlineStore.close);

      await restarted.attach(await account('A'));
      // No waiting for the network: the saved answer is already in force.
      expect(restarted.isPremium, isTrue);
      await pumpEventQueue();
      expect(restarted.isPremium, isTrue);
      expect(restarted.state, activeAnnual);
    });

    test('the store saying "not active" replaces what was saved', () async {
      gateway.byUser['A'] = activeAnnual;
      await attach(controller, 'A');

      // Refunded since the last launch.
      final refunded = stateWith(
        entitled: false,
        expiresAt: now,
        willRenew: false,
      );
      final nextLaunchStore = FakeGateway()..byUser['A'] = refunded;
      final restarted = newController(nextLaunchStore);
      addTearDown(restarted.dispose);
      addTearDown(nextLaunchStore.close);
      await attach(restarted, 'A');

      expect(restarted.isPremium, isFalse);
      expect(await savedFor('A'), refunded);
    });
  });

  group('coming back to the app', () {
    test('picks up a cancellation without touching Pro', () async {
      gateway.byUser['A'] = activeAnnual;
      await attach(controller, 'A');
      notifications = 0;

      final cancelled = stateWith(
        period: PlanPeriod.annual,
        expiresAt: activeAnnual.expiresAt,
        willRenew: false,
        checked: now.add(const Duration(hours: 1)),
      );
      gateway.byUser['A'] = cancelled;
      await controller.refresh();

      expect(controller.isPremium, isTrue);
      expect(controller.state.willRenew, isFalse);
      // Profile must hear about it to change "renews" into "ends".
      expect(notifications, 1);
    });

    test('offline, Pro lasts the paid period and the renewal grace', () async {
      final end = now.add(const Duration(days: 10));
      gateway.byUser['A'] = stateWith(expiresAt: end);
      await attach(controller, 'A');
      gateway.stateFailure = _offline;

      now = end.subtract(const Duration(minutes: 1));
      await controller.refresh();
      expect(controller.isPremium, isTrue);

      now = end.add(const Duration(days: 2));
      await controller.refresh();
      expect(controller.isPremium, isTrue);

      notifications = 0;
      now = end.add(const Duration(days: 3, minutes: 1));
      await controller.refresh();
      expect(controller.isPremium, isFalse);
      // The app is told, so Pro features switch off without a restart.
      expect(notifications, 1);
    });

    test('offline, a cancelled subscription ends on its date', () async {
      final end = now.add(const Duration(days: 10));
      gateway.byUser['A'] = stateWith(expiresAt: end, willRenew: false);
      await attach(controller, 'A');
      gateway.stateFailure = _offline;

      now = end.add(const Duration(minutes: 1));
      await controller.refresh();
      expect(controller.isPremium, isFalse);
    });

    test('a renewal pushed by the store is taken and saved', () async {
      final end = now.add(const Duration(days: 30));
      gateway.byUser['A'] = stateWith(expiresAt: end);
      await attach(controller, 'A');

      final renewed = stateWith(
        expiresAt: end.add(const Duration(days: 30)),
        checked: end,
      );
      gateway.push(renewed);
      await pumpEventQueue();

      expect(controller.state, renewed);
      expect(await savedFor('A'), renewed);
    });
  });

  group('switching accounts', () {
    test('a queued purchase cannot move to the next account', () async {
      gateway.connectGate = Completer<void>();
      await controller.attach(await account('A'));
      final purchase = controller.purchase(annualPlan);
      final rejected = expectLater(
        purchase,
        throwsA(
          isA<PurchaseFailure>().having(
            (f) => f.kind,
            'kind',
            PurchaseFailureKind.cancelled,
          ),
        ),
      );
      await controller.attach(await account('B'));
      gateway.connectGate!.complete();
      await rejected;
      await pumpEventQueue();
      expect(
        gateway.calls.where((call) => call.startsWith('purchase:')),
        isEmpty,
      );
      expect(gateway.user, 'B');
      expect(controller.isPremium, isFalse);
    });

    for (final restoring in [false, true]) {
      test(
        '${restoring ? 'restore' : 'purchase'} stays with its initiating account',
        () async {
          await attach(controller, 'A');
          final gate = Completer<void>();
          if (restoring) {
            gateway.restoreGate = gate;
            gateway.restored = activeAnnual;
          } else {
            gateway.purchaseGate = gate;
          }
          final operation = restoring
              ? controller.restore()
              : controller.purchase(annualPlan);
          final rejected = expectLater(
            operation,
            throwsA(
              isA<PurchaseFailure>().having(
                (f) => f.kind,
                'kind',
                PurchaseFailureKind.cancelled,
              ),
            ),
          );
          await pumpEventQueue();
          await controller.attach(await account('B'));
          await pumpEventQueue();
          expect(
            gateway.user,
            'A',
            reason: 'native account cannot change during payment',
          );
          expect(controller.isPremium, isFalse);
          gate.complete();
          await rejected;
          await pumpEventQueue();
          expect(gateway.byUser['A'], activeAnnual);
          expect(gateway.user, 'B');
          expect(controller.isPremium, isFalse);
          expect((await savedFor('B')).entitled, isFalse);
          await attach(controller, 'A');
          expect(controller.isPremium, isTrue);
        },
      );
    }

    test(
      'a delayed old-customer event never grants Pro to the new customer',
      () async {
        gateway.byUser['A'] = activeAnnual;
        await attach(controller, 'A');
        await attach(controller, 'B');
        gateway.emitOnStateRead = true;
        final reads = gateway.calls.where((call) => call == 'state').length;
        gateway.pushStale(activeAnnual);
        await pumpEventQueue();
        expect(controller.isPremium, isFalse);
        expect((await savedFor('B')).entitled, isFalse);
        expect(
          gateway.calls.where((call) => call == 'state').length,
          reads + 1,
          reason: 'SDK update callbacks must not cause a refresh loop',
        );
      },
    );

    test(
      'each account has its own Pro, on the device and in the store',
      () async {
        gateway.byUser['A'] = activeAnnual;
        await attach(controller, 'A');
        expect(controller.isPremium, isTrue);

        await attach(controller, 'B');
        expect(gateway.calls, containsAllInOrder(['switch:B', 'state']));
        expect(controller.isPremium, isFalse);
        // A's confirmed Pro is untouched and returns with A.
        expect(await savedFor('A'), activeAnnual);

        await controller.attach(await account('A'));
        expect(controller.isPremium, isTrue);
      },
    );

    test('signing out goes back to an anonymous customer', () async {
      gateway.byUser['A'] = activeAnnual;
      await attach(controller, 'A');
      await attach(controller, null);

      expect(gateway.calls, contains('switch:null'));
      expect(controller.isPremium, isFalse);
    });

    test('an account never inherits the previous customer while the switch '
        'cannot reach the store', () async {
      gateway.byUser['A'] = activeAnnual;
      await attach(controller, 'A');

      gateway.connectFailure = _offline;
      await attach(controller, 'B');

      // The store SDK is still on A; its answer must not be B's.
      expect(controller.isPremium, isFalse);
      expect((await savedFor('B')).entitled, isFalse);

      // A push for the old customer is ignored too.
      gateway.push(activeAnnual);
      await pumpEventQueue();
      expect(controller.isPremium, isFalse);

      // Back online, the switch is retried and B gets B's own answer.
      gateway
        ..connectFailure = null
        ..byUser['B'] = SubscriptionState.none;
      await controller.refresh();
      expect(gateway.user, 'B');
      expect(controller.isPremium, isFalse);
    });

    test('a slow answer for the previous account is dropped', () async {
      gateway.byUser['A'] = activeAnnual;
      // Attach A and, without waiting for the store, move on to B.
      await controller.attach(await account('A'));
      await controller.attach(await account('B'));
      await pumpEventQueue();

      expect(gateway.user, 'B');
      expect(controller.isPremium, isFalse);
      expect((await savedFor('B')).entitled, isFalse);
    });
  });

  group('buying', () {
    test('Pro is on as soon as the store takes the purchase', () async {
      await attach(controller, 'A');
      expect(controller.isPremium, isFalse);
      notifications = 0;

      final plans = await controller.loadPlans();
      await controller.purchase(plans.first);

      expect(gateway.calls.last, r'purchase:$rc_annual');
      expect(controller.isPremium, isTrue);
      expect(notifications, 1);
      expect(await savedFor('A'), activeAnnual);
    });

    test('a cancelled or failed purchase changes nothing', () async {
      await attach(controller, 'A');
      notifications = 0;
      for (final kind in [
        PurchaseFailureKind.cancelled,
        PurchaseFailureKind.pending,
        PurchaseFailureKind.store,
      ]) {
        gateway.purchaseFailure = PurchaseFailure(kind);
        await expectLater(
          controller.purchase(annualPlan),
          throwsA(isA<PurchaseFailure>().having((f) => f.kind, 'kind', kind)),
        );
      }
      expect(controller.isPremium, isFalse);
      expect(notifications, 0);
    });

    test(
      'a pending purchase turns Pro on when the store approves it',
      () async {
        await attach(controller, 'A');
        gateway.purchaseFailure = const PurchaseFailure(
          PurchaseFailureKind.pending,
        );
        await expectLater(
          controller.purchase(annualPlan),
          throwsA(isA<PurchaseFailure>()),
        );

        gateway.push(activeAnnual);
        await pumpEventQueue();
        expect(controller.isPremium, isTrue);
      },
    );

    test('plans can be loaded after an offline start', () async {
      gateway.connectFailure = _offline;
      await attach(controller, 'A');
      await expectLater(
        controller.loadPlans(),
        throwsA(
          isA<PurchaseFailure>().having(
            (f) => f.kind,
            'kind',
            PurchaseFailureKind.network,
          ),
        ),
      );

      gateway.connectFailure = null;
      expect(await controller.loadPlans(), hasLength(2));
      expect(gateway.user, 'A');
    });
  });

  group('restoring', () {
    test('finds an earlier purchase on a new phone', () async {
      await attach(controller, 'A');
      gateway.restored = activeAnnual;

      expect(await controller.restore(), isTrue);
      expect(controller.isPremium, isTrue);
      expect(await savedFor('A'), activeAnnual);
    });

    test('says so when there is nothing to restore', () async {
      await attach(controller, 'A');
      expect(await controller.restore(), isFalse);
      expect(controller.isPremium, isFalse);
    });
  });

  group('what the rest of the app sees', () {
    test('only the store grants Pro once payments are on', () async {
      await attach(controller, 'A');
      // A value carried in by a backup, or left from before the launch.
      expect(
        controller.statusFor(SubscriptionStatus.pro),
        SubscriptionStatus.free,
      );
      expect(
        controller.statusFor(SubscriptionStatus.free),
        SubscriptionStatus.free,
      );

      gateway.byUser['A'] = activeAnnual;
      await controller.refresh();
      for (final stored in SubscriptionStatus.values) {
        expect(controller.statusFor(stored), SubscriptionStatus.pro);
      }
    });

    test(
      'legacy tester access is free until the store confirms a purchase',
      () async {
        await attach(controller, 'A');
        final legacy = UserPreferences.fromJson({
          ...UserPreferences.fromCountry(Country.canada).toJson(),
          'subscriptionStatus': 'testerPro',
          'driverName': 'Original owner',
        });
        expect(legacy.subscriptionStatus, SubscriptionStatus.free);
        expect(legacy.toJson()['subscriptionStatus'], 'free');
        expect(legacy.driverName, 'Original owner');
        expect(legacy.country, Country.canada);
        expect(EntitlementService(legacy).isPro, isFalse);
        expect(EntitlementService(controller.applyTo(legacy)).isPro, isFalse);
        final unconfigured = SubscriptionController();
        addTearDown(unconfigured.dispose);
        expect(EntitlementService(unconfigured.applyTo(legacy)).isPro, isFalse);

        gateway.byUser['A'] = activeAnnual;
        await controller.refresh();
        expect(EntitlementService(controller.applyTo(legacy)).isPro, isTrue);
      },
    );

    test(
      'preferences are rewritten only when the status really differs',
      () async {
        await attach(controller, 'A');
        final free = UserPreferences.fromCountry(Country.usa);
        expect(identical(controller.applyTo(free), free), isTrue);

        final stale = free.copyWith(subscriptionStatus: SubscriptionStatus.pro);
        final corrected = controller.applyTo(stale);
        expect(corrected.subscriptionStatus, SubscriptionStatus.free);
        // Nothing else about the user's settings is touched.
        expect(
          corrected.toJson()..remove('subscriptionStatus'),
          stale.toJson()..remove('subscriptionStatus'),
        );
      },
    );
  });

  test('the confirmed state is account data: removed with the account, '
      'never part of preferences', () async {
    expect(accountDataKeys, contains(SubscriptionController.snapshotKey));

    gateway.byUser['A'] = activeAnnual;
    await attach(controller, 'A');
    final scope = await account('A');
    await scope.clear();
    expect((await savedFor('A')).entitled, isFalse);

    // Preferences travel in backups; they must not carry the paid-through
    // date or anything else from the store.
    final preferencesJson = jsonEncode(
      UserPreferences.fromCountry(Country.usa).toJson(),
    );
    expect(preferencesJson, isNot(contains('expiresAt')));
    expect(preferencesJson, isNot(contains('entitled')));
  });
}
