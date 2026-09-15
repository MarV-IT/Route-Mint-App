import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/backup/cloud_backup_service.dart';
import 'package:route_mint_app/core/backup/daily_cloud_backup_service.dart';
import 'package:route_mint_app/core/preferences/preferences_service.dart';
import 'package:route_mint_app/core/preferences/user_preferences.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {
  _User(this.uid);

  @override
  final String uid;
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? currentUser = _User('account-a');
}

class _Preferences extends PreferencesService {
  _Preferences(this.value);
  UserPreferences value;

  @override
  Future<UserPreferences> loadPreferences() async => value;

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    value = preferences;
  }
}

class _Backup extends CloudBackupService {
  final started = Completer<void>();
  final finished = Completer<void>();

  @override
  Future<void> uploadBackupForCurrentUser() {
    started.complete();
    return finished.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
    await AccountDataStore.activate('account-a');
  });

  tearDown(AccountDataStore.resetForTesting);

  test('backup completion preserves settings changed during upload', () async {
    final original = UserPreferences.defaults().copyWith(
      subscriptionStatus: SubscriptionStatus.pro,
    );
    final preferences = _Preferences(original);
    final backup = _Backup();
    final service = DailyCloudBackupService(
      auth: _Auth(),
      cloudBackupService: backup,
      preferencesService: preferences,
    );

    final saving = service.runIfDue(original);
    await backup.started.future;
    preferences.value = original.copyWith(
      language: AppLanguage.ukrainian,
      vehicleOdometerKm: 12345.0,
    );
    backup.finished.complete();
    final updated = await saving;

    expect(updated!.language, AppLanguage.ukrainian);
    expect(updated.vehicleOdometerKm, 12345);
    expect(updated.lastAutomaticCloudBackupAt, isNotNull);
    expect(preferences.value, same(updated));
  });

  test('failed upload leaves the backup due for retry', () async {
    final original = UserPreferences.defaults().copyWith(
      subscriptionStatus: SubscriptionStatus.pro,
    );
    final preferences = _Preferences(original);
    final backup = _Backup();
    final service = DailyCloudBackupService(
      auth: _Auth(),
      cloudBackupService: backup,
      preferencesService: preferences,
    );
    final saving = service.runIfDue(original);
    await backup.started.future;
    backup.finished.completeError(StateError('Offline'));
    expect(await saving, isNull);
    expect(preferences.value, same(original));
    expect(service.isDue(preferences.value), isTrue);
  });

  test('next backup uses local calendar days across clock changes', () {
    final service = DailyCloudBackupService();
    for (final now in [
      DateTime(2026, 3, 7, 23, 59),
      DateTime(2026, 10, 31, 23, 59),
      DateTime(2026, 12, 31, 23, 59),
    ]) {
      expect(
        service.nextBackupTime(now),
        DateTime(now.year, now.month, now.day + 1, 23, 59),
      );
    }
  });

  for (final nextUid in ['account-b', 'account-a']) {
    test('late upload cannot update a new session for $nextUid', () async {
      final original = UserPreferences.defaults().copyWith(
        subscriptionStatus: SubscriptionStatus.pro,
      );
      final accountA = PreferencesService();
      await accountA.savePreferences(original);
      final backup = _Backup();
      final auth = _Auth();
      final service = DailyCloudBackupService(
        auth: auth,
        cloudBackupService: backup,
      );
      final saving = service.runIfDue(original);
      await backup.started.future;

      auth.currentUser = null;
      await AccountDataStore.activate(null);
      auth.currentUser = _User(nextUid);
      await AccountDataStore.activate(nextUid);
      final nextAccount = PreferencesService();
      final second = original.copyWith(vehicleOdometerKm: 900.0);
      await nextAccount.savePreferences(second);
      backup.finished.complete();

      expect(await saving, isNull);
      expect(
        (await accountA.loadPreferences()).lastAutomaticCloudBackupAt,
        isNull,
      );
      final saved = await nextAccount.loadPreferences();
      expect(saved.lastAutomaticCloudBackupAt, isNull);
      expect(saved.vehicleOdometerKm, 900);
    });
  }

  test(
    'long-lived daily service uses storage of the current account',
    () async {
      await AccountDataStore.activate(null);
      final backup = _Backup();
      final auth = _Auth();
      final service = DailyCloudBackupService(
        auth: auth,
        cloudBackupService: backup,
      );
      await AccountDataStore.activate('account-a');
      final preferences = PreferencesService();
      final original = UserPreferences.defaults().copyWith(
        subscriptionStatus: SubscriptionStatus.pro,
        vehicleOdometerKm: 12345.0,
      );
      await preferences.savePreferences(original);

      final saving = service.runIfDue(original);
      await backup.started.future;
      backup.finished.complete();

      final updated = await saving;
      expect(updated!.vehicleOdometerKm, 12345);
      expect(
        (await preferences.loadPreferences()).lastAutomaticCloudBackupAt,
        updated.lastAutomaticCloudBackupAt,
      );
    },
  );
}
