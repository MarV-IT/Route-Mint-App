import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/backup/cloud_backup_service.dart';
import 'package:route_mint_app/core/backup/daily_cloud_backup_service.dart';
import 'package:route_mint_app/core/preferences/preferences_service.dart';
import 'package:route_mint_app/core/preferences/user_preferences.dart';

class _User extends Fake implements User {}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
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
}
