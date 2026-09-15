import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/preferences/preferences_service.dart';
import 'package:route_mint_app/core/preferences/user_preferences.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/core/storage/settings_service.dart';
import 'package:route_mint_app/features/expenses/models/expense_entry.dart';
import 'package:route_mint_app/features/expenses/services/expense_service.dart';
import 'package:route_mint_app/features/fuel/models/fuel_entry.dart';
import 'package:route_mint_app/features/fuel/services/fuel_service.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/services/trip_service.dart';
import 'package:route_mint_app/features/work_mode/models/work_mode_settings.dart';
import 'package:route_mint_app/features/work_mode/services/work_mode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
  });
  tearDown(AccountDataStore.resetForTesting);

  test(
    'logout and a new account never expose the previous account records',
    () async {
      await AccountDataStore.activate('account-a');
      await TripService().addTrip(_trip('a'));
      await FuelService().addFuelEntry(
        FuelEntry(
          id: 'fuel-a',
          date: DateTime(2026, 9, 15),
          volumeLiters: 20,
          totalCost: 30,
        ),
      );
      await ExpenseService().addExpenseEntry(
        ExpenseEntry(
          id: 'expense-a',
          date: DateTime(2026, 9, 15),
          category: 'parking',
          amount: 10,
        ),
      );
      await WorkModeService().saveSettings(
        const WorkModeSettings(isEnabled: true, shifts: []),
      );

      await AccountDataStore.activate(null);
      expect(await TripService().loadTrips(), isEmpty);
      expect(await FuelService().loadFuelEntries(), isEmpty);
      expect(await ExpenseService().loadExpenseEntries(), isEmpty);
      expect((await WorkModeService().loadSettings()).isEnabled, false);

      await AccountDataStore.activate('account-b');
      expect(await TripService().loadTrips(), isEmpty);
      expect(await FuelService().loadFuelEntries(), isEmpty);
      expect(await ExpenseService().loadExpenseEntries(), isEmpty);
      expect((await WorkModeService().loadSettings()).isEnabled, false);
      await TripService().addTrip(_trip('b'));

      await AccountDataStore.activate('account-a');
      expect((await TripService().loadTrips()).single.id, 'a');
      expect((await FuelService().loadFuelEntries()).single.id, 'fuel-a');
      expect(
        (await ExpenseService().loadExpenseEntries()).single.id,
        'expense-a',
      );
      expect((await WorkModeService().loadSettings()).isEnabled, true);
    },
  );

  test('guest records stay separate from both accounts', () async {
    await AccountDataStore.activate(null);
    await TripService().addTrip(_trip('guest'));
    await AccountDataStore.activate('account-a');
    expect(await TripService().loadTrips(), isEmpty);
    await TripService().addTrip(_trip('a'));
    await AccountDataStore.activate('account-b');
    expect(await TripService().loadTrips(), isEmpty);
    await AccountDataStore.activate(null);
    expect((await TripService().loadTrips()).single.id, 'guest');
  });

  test(
    'captured services keep writes and odometer changes with their owner',
    () async {
      await AccountDataStore.activate('account-a');
      final accountATrips = TripService();
      final accountAPreferences = PreferencesService();
      await accountAPreferences.savePreferences(
        UserPreferences.defaults().copyWith(vehicleOdometerKm: 1000.0),
      );
      await AccountDataStore.activate('account-b');
      final accountBPreferences = PreferencesService();
      await accountBPreferences.savePreferences(
        UserPreferences.defaults().copyWith(vehicleOdometerKm: 5000.0),
      );

      await accountATrips.addTrip(_trip('late-a', distance: 25));

      expect(await TripService().loadTrips(), isEmpty);
      expect(
        (await accountBPreferences.loadPreferences()).vehicleOdometerKm,
        5000,
      );
      expect(
        (await accountAPreferences.loadPreferences()).vehicleOdometerKm,
        1025,
      );
      await AccountDataStore.activate('account-a');
      expect((await TripService().loadTrips()).single.id, 'late-a');
    },
  );

  test(
    'new scopes inherit presentation but no personal or tracking data',
    () async {
      await AccountDataStore.activate('account-a');
      await PreferencesService().savePreferences(
        UserPreferences.defaults().copyWith(
          language: AppLanguage.ukrainian,
          unit: AppUnit.kilometers,
          onboardingCompleted: true,
          themeMode: AppThemeMode.dark,
          driverName: 'Driver A',
          businessName: 'Business A',
          vehicleName: 'Vehicle A',
          accountantPhone: '123',
          insurancePolicyNumber: '456',
          vehicleOdometerKm: 1000.0,
          lastOilChangeOdometerKm: 500.0,
          lastAutomaticCloudBackupAt: DateTime(2026, 9, 14),
          autoTripDetectionEnabled: true,
          subscriptionStatus: SubscriptionStatus.testerPro,
        ),
      );
      await SettingsService().saveLanguage(AppLanguage.ukrainian);
      final accountA = await AccountDataStore.current.getPreferences();
      await accountA.setString('auto_detection_active_trip', 'private route');
      await accountA.setBool('auto_detection_monitoring', true);

      await AccountDataStore.activate('account-b');
      final preferences = await PreferencesService().loadPreferences();
      expect(preferences.language, AppLanguage.ukrainian);
      expect(preferences.unit, AppUnit.kilometers);
      expect(preferences.themeMode, AppThemeMode.dark);
      expect(preferences.onboardingCompleted, true);
      expect(await SettingsService().loadLanguage(), AppLanguage.ukrainian);
      expect(preferences.driverName, isNull);
      expect(preferences.businessName, isNull);
      expect(preferences.vehicleName, isNull);
      expect(preferences.accountantPhone, isNull);
      expect(preferences.insurancePolicyNumber, isNull);
      expect(preferences.vehicleOdometerKm, isNull);
      expect(preferences.lastOilChangeOdometerKm, isNull);
      expect(preferences.lastAutomaticCloudBackupAt, isNull);
      expect(preferences.autoTripDetectionEnabled, false);
      expect(preferences.subscriptionStatus, SubscriptionStatus.free);
      final accountB = await AccountDataStore.current.getPreferences();
      expect(accountB.getString('auto_detection_active_trip'), isNull);
      expect(accountB.getBool('auto_detection_monitoring'), isNull);
    },
  );

  test(
    'legacy records migrate once only to the already authenticated owner',
    () async {
      final rawTrips = jsonEncode([_trip('legacy-a').toJson()]);
      SharedPreferences.setMockInitialValues({
        'trips': rawTrips,
        'user_preferences': jsonEncode(
          UserPreferences.defaults()
              .copyWith(driverName: 'Original driver')
              .toJson(),
        ),
        'auto_detection_monitoring': true,
        'firebase_auth_session_expected': true,
        'unrelated': 'preserved',
      });

      await AccountDataStore.activate('account-a', claimLegacy: true);
      expect((await TripService().loadTrips()).single.id, 'legacy-a');
      expect(
        (await PreferencesService().loadPreferences()).driverName,
        'Original driver',
      );
      final owner = AccountDataStore.current;
      final scoped = await owner.getPreferences();
      expect(scoped.getBool('auto_detection_monitoring'), true);
      expect(scoped.get('firebase_auth_session_expected'), isNull);
      final raw = await SharedPreferences.getInstance();
      expect(raw.getString('trips'), rawTrips);
      await owner.clear();

      // Simulate a new process; migration must not resurrect deleted records.
      AccountDataStore.resetForTesting();
      await AccountDataStore.activate('account-a', claimLegacy: true);
      expect(await TripService().loadTrips(), isEmpty);
      expect((await PreferencesService().loadPreferences()).driverName, isNull);
      await AccountDataStore.activate('account-b', claimLegacy: true);
      expect(await TripService().loadTrips(), isEmpty);
      expect(raw.getString('unrelated'), 'preserved');
    },
  );

  test(
    'signed-out legacy records are quarantined even on a later startup claim',
    () async {
      SharedPreferences.setMockInitialValues({
        'trips': jsonEncode([_trip('unknown-owner').toJson()]),
        'user_preferences': jsonEncode(
          UserPreferences.defaults()
              .copyWith(driverName: 'Unknown owner')
              .toJson(),
        ),
      });
      await AccountDataStore.activate(null);
      expect(await TripService().loadTrips(), isEmpty);
      expect((await PreferencesService().loadPreferences()).driverName, isNull);
      AccountDataStore.resetForTesting();
      await AccountDataStore.activate('new-account', claimLegacy: true);
      expect(await TripService().loadTrips(), isEmpty);
      expect((await PreferencesService().loadPreferences()).driverName, isNull);
    },
  );

  test(
    'clear deletes only captured owner keys, including future feature keys',
    () async {
      final raw = await SharedPreferences.getInstance();
      await raw.setBool('firebase_auth_session_expected', true);
      await raw.setString('unrelated', 'keep');
      await AccountDataStore.activate('account-a');
      await TripService().addTrip(_trip('a'));
      final accountA = AccountDataStore.current;
      await (await accountA.getPreferences()).setString(
        'future_feature',
        'private',
      );
      await AccountDataStore.activate('account-b');
      await TripService().addTrip(_trip('b'));
      await accountA.clear();
      expect((await accountA.getPreferences()).getKeys(), isEmpty);
      expect((await TripService().loadTrips()).single.id, 'b');
      expect(raw.getString('unrelated'), 'keep');
      expect(raw.getBool('firebase_auth_session_expected'), true);
    },
  );

  test(
    'only the migration owner can delete the retained legacy copy',
    () async {
      SharedPreferences.setMockInitialValues({
        'trips': jsonEncode([_trip('legacy').toJson()]),
        'unrelated': 'keep',
      });
      await AccountDataStore.activate('account-a', claimLegacy: true);
      final accountA = AccountDataStore.current;
      await AccountDataStore.activate('account-b');
      await AccountDataStore.clearLegacyDataForOwner(AccountDataStore.current);
      final raw = await SharedPreferences.getInstance();
      expect(raw.getString('trips'), isNotNull);
      await accountA.clear();
      await AccountDataStore.clearLegacyDataForOwner(accountA);
      expect(raw.getString('trips'), isNull);
      expect(raw.getString('unrelated'), 'keep');
      AccountDataStore.resetForTesting();
      await AccountDataStore.activate('account-a', claimLegacy: true);
      expect(await TripService().loadTrips(), isEmpty);
    },
  );

  test(
    'switches are ordered and a new session invalidates old scope identity',
    () async {
      await Future.wait([
        AccountDataStore.activate('account-a'),
        AccountDataStore.activate('account-b'),
      ]);
      expect(AccountDataStore.current.uid, 'account-b');
      final scope = AccountDataStore.current;
      await TripService().addTrip(_trip('b-trip'));
      await AccountDataStore.activate('account-b');
      expect(identical(scope, AccountDataStore.current), false);
      expect((await TripService().loadTrips()).single.id, 'b-trip');
    },
  );

  test('guest cannot claim legacy records', () {
    expect(
      () => AccountDataStore.activate(null, claimLegacy: true),
      throwsArgumentError,
    );
  });

  test('simultaneous Stop and logout save a trip and odometer once', () async {
    await AccountDataStore.activate('account-a');
    await PreferencesService().savePreferences(
      UserPreferences.defaults().copyWith(vehicleOdometerKm: 1000.0),
    );
    final trip = _trip('same-manual-trip', distance: 25);
    await Future.wait([
      TripService().addTrip(trip),
      TripService().addTrip(trip),
      TripService().addTrip(_trip('second-trip', distance: 5)),
    ]);
    expect(await TripService().loadTrips(), hasLength(2));
    expect(
      (await PreferencesService().loadPreferences()).vehicleOdometerKm,
      1030,
    );
  });
}

Trip _trip(String id, {double distance = 10}) => Trip(
  id: id,
  from: 'Home',
  to: 'Client',
  distance: distance,
  category: 'business',
  date: DateTime(2026, 9, 15),
);
