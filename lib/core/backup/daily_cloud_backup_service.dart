import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../preferences/preferences_service.dart';
import '../preferences/user_preferences.dart';
import '../storage/account_data_store.dart';
import '../subscription/entitlement_service.dart';
import 'cloud_backup_service.dart';

class DailyCloudBackupService {
  DailyCloudBackupService({
    CloudBackupService? cloudBackupService,
    PreferencesService? preferencesService,
    FirebaseAuth? auth,
  }) : _cloudBackupService =
           cloudBackupService ?? CloudBackupService(auth: auth),
       _preferencesServiceOverride = preferencesService,
       _auth = auth;

  final CloudBackupService _cloudBackupService;
  final PreferencesService? _preferencesServiceOverride;
  final FirebaseAuth? _auth;

  User? get _currentUser {
    if (_auth != null) return _auth.currentUser;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser;
  }

  DateTime nextBackupTime([DateTime? now]) {
    final current = now ?? DateTime.now();
    final todayBackup = DateTime(
      current.year,
      current.month,
      current.day,
      23,
      59,
    );
    if (current.isBefore(todayBackup)) return todayBackup;
    return DateTime(current.year, current.month, current.day + 1, 23, 59);
  }

  bool isDue(UserPreferences preferences, [DateTime? now]) {
    if (!EntitlementService(preferences).canUseCloudBackup) return false;
    if (_currentUser == null) return false;

    final current = now ?? DateTime.now();
    final todayBackup = DateTime(
      current.year,
      current.month,
      current.day,
      23,
      59,
    );
    final dueFor = current.isBefore(todayBackup)
        ? DateTime(current.year, current.month, current.day - 1, 23, 59)
        : todayBackup;
    final lastBackup = preferences.lastAutomaticCloudBackupAt;
    return lastBackup == null || lastBackup.isBefore(dueFor);
  }

  Future<UserPreferences?> runIfDue(UserPreferences preferences) async {
    if (!isDue(preferences)) return null;
    final uid = _currentUser?.uid;
    final scope = AccountDataStore.current;
    if (uid == null || scope.uid != uid) return null;
    final preferencesService =
        _preferencesServiceOverride ?? PreferencesService(scope: scope);

    bool isCurrent() =>
        _currentUser?.uid == uid && identical(AccountDataStore.current, scope);

    try {
      await _cloudBackupService.uploadBackupForCurrentUser();
      if (!isCurrent()) return null;
      // An upload can wait for connectivity while the user edits settings.
      // Merge the completion time into the latest saved preferences.
      final current = await preferencesService.loadPreferences();
      if (!isCurrent()) return null;
      final updated = current.copyWith(
        lastAutomaticCloudBackupAt: DateTime.now(),
      );
      await preferencesService.savePreferences(updated);
      if (!isCurrent()) return null;
      if (kDebugMode) {
        debugPrint('[DailyCloudBackup] automatic cloud backup completed');
      }
      return updated;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DailyCloudBackup] automatic cloud backup failed: $e');
      }
      return null;
    }
  }
}
