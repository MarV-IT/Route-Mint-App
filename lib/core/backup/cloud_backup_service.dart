// Recommended Firestore security rules:
//
// match /users/{userId}/backups/{backupId} {
//   allow read, write: if request.auth != null
//                      && request.auth.uid == userId;
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../preferences/preferences_service.dart';
import '../preferences/user_preferences.dart';
import '../../features/trips/models/trip.dart';
import '../../features/trips/services/trip_service.dart';
import '../../features/work_mode/models/work_mode_settings.dart';
import '../../features/work_mode/services/work_mode_service.dart';

class CloudBackupService {
  static const _appName = 'Route Mint';
  static const _backupVersion = 1;

  final _prefsService = PreferencesService();
  final _tripService = TripService();
  final _workModeService = WorkModeService();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _backupRef {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    return _db
        .collection('users')
        .doc(uid)
        .collection('backups')
        .doc('latest');
  }

  Future<void> uploadBackupForCurrentUser() async {
    if (_uid == null) throw StateError('Not signed in');

    final preferences = await _prefsService.loadPreferences();
    final trips = await _tripService.loadTrips();
    final workModeSettings = await _workModeService.loadSettings();

    await _backupRef.set({
      'appName': _appName,
      'backupVersion': _backupVersion,
      'updatedAt': FieldValue.serverTimestamp(),
      'exportedAt': DateTime.now().toIso8601String(),
      'preferences': preferences.toJson(),
      'trips': trips.map((t) => t.toJson()).toList(),
      'workModeSettings': workModeSettings.toJson(),
    });
  }

  Future<void> restoreBackupForCurrentUser() async {
    if (_uid == null) throw StateError('Not signed in');

    final doc = await _backupRef.get();
    if (!doc.exists) throw StateError('No cloud backup found');

    final data = doc.data()!;

    final version = data['backupVersion'];
    if (version is int && version > _backupVersion) {
      throw StateError('Backup version $version is not supported');
    }

    final prefsJson = data['preferences'];
    if (prefsJson is Map<String, dynamic>) {
      await _prefsService.savePreferences(UserPreferences.fromJson(prefsJson));
    }

    final tripsJson = data['trips'];
    if (tripsJson is List<dynamic>) {
      final trips = <Trip>[];
      for (final item in tripsJson) {
        if (item is! Map<String, dynamic>) continue;
        try {
          trips.add(Trip.fromJson(item));
        } catch (_) {
          // Skip malformed entries without aborting the restore.
        }
      }
      await _tripService.saveTrips(trips);
    }

    final workJson = data['workModeSettings'];
    if (workJson is Map<String, dynamic>) {
      await _workModeService.saveSettings(WorkModeSettings.fromJson(workJson));
    }
  }

  Future<bool> hasCloudBackup() async {
    if (_uid == null) return false;
    try {
      return (await _backupRef.get()).exists;
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> getLastCloudBackupTime() async {
    if (_uid == null) return null;
    try {
      final doc = await _backupRef.get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final ts = data['updatedAt'];
      if (ts is Timestamp) return ts.toDate();
      // Fallback when updatedAt hasn't propagated yet (e.g. offline cache).
      final exported = data['exportedAt'];
      if (exported is String) return DateTime.tryParse(exported);
      return null;
    } catch (_) {
      return null;
    }
  }
}
