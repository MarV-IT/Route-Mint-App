import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../preferences/preferences_service.dart';
import '../preferences/user_preferences.dart';
import '../subscription/entitlement_service.dart';
import 'cloud_backup_service.dart';

class DailyCloudBackupService {
  DailyCloudBackupService({
    CloudBackupService? cloudBackupService,
    PreferencesService? preferencesService,
    FirebaseAuth? auth,
  }) : _cloudBackupService = cloudBackupService ?? CloudBackupService(),
       _preferencesService = preferencesService ?? PreferencesService(),
       _auth = auth;

  final CloudBackupService _cloudBackupService;
  final PreferencesService _preferencesService;
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
    return todayBackup.add(const Duration(days: 1));
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
        ? todayBackup.subtract(const Duration(days: 1))
        : todayBackup;
    final lastBackup = preferences.lastAutomaticCloudBackupAt;
    return lastBackup == null || lastBackup.isBefore(dueFor);
  }

  Future<UserPreferences?> runIfDue(UserPreferences preferences) async {
    if (!isDue(preferences)) return null;

    try {
      await _cloudBackupService.uploadBackupForCurrentUser();
      final updated = preferences.copyWith(
        lastAutomaticCloudBackupAt: DateTime.now(),
      );
      await _preferencesService.savePreferences(updated);
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
