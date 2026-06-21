// Recommended Firestore security rules:
//
// match /users/{userId}/backups/{backupId} {
//   allow read, write: if request.auth != null
//                      && request.auth.uid == userId;
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../preferences/preferences_service.dart';
import '../preferences/user_preferences.dart';
import '../../features/expenses/models/expense_entry.dart';
import '../../features/expenses/services/expense_service.dart';
import '../../features/fuel/models/fuel_entry.dart';
import '../../features/fuel/services/fuel_service.dart';
import '../../features/trips/models/trip.dart';
import '../../features/trips/services/trip_service.dart';
import '../../features/work_mode/models/work_mode_settings.dart';
import '../../features/work_mode/services/work_mode_service.dart';

class CloudBackupStatus {
  const CloudBackupStatus({
    required this.uid,
    required this.exists,
    this.updatedAt,
    this.exportedAt,
    this.tripCount = 0,
    this.expenseCount = 0,
    this.fuelCount = 0,
    this.backupVersion,
  });

  final String uid;
  final bool exists;
  final DateTime? updatedAt;
  final DateTime? exportedAt;
  final int tripCount;
  final int expenseCount;
  final int fuelCount;
  final int? backupVersion;
}

class CloudRestoreResult {
  const CloudRestoreResult({
    required this.tripCount,
    required this.expenseCount,
    required this.fuelCount,
    required this.skippedTripCount,
    required this.skippedExpenseCount,
    required this.skippedFuelCount,
  });

  final int tripCount;
  final int expenseCount;
  final int fuelCount;
  final int skippedTripCount;
  final int skippedExpenseCount;
  final int skippedFuelCount;
}

class CloudBackupService {
  static const _appName = 'MarV Route';
  static const _backupVersion = 1;

  final _prefsService = PreferencesService();
  final _tripService = TripService();
  final _expenseService = ExpenseService();
  final _fuelService = FuelService();
  final _workModeService = WorkModeService();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _backupRef {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    return _db.collection('users').doc(uid).collection('backups').doc('latest');
  }

  /// Serializes a trip for the cloud backup with its per-point GPS route
  /// removed. Route polylines are the dominant size contributor and would push
  /// heavy users past Firestore's 1 MB document limit; they are cosmetic
  /// (map preview only), so the cloud copy keeps every trip record but not the
  /// polyline. Local storage still retains the full route.
  @visibleForTesting
  static Map<String, dynamic> tripToBackupJson(Trip trip) =>
      trip.copyWith(routePoints: const []).toJson();

  Future<void> uploadBackupForCurrentUser() async {
    if (_uid == null) throw StateError('Not signed in');

    final preferences = await _prefsService.loadPreferences();
    final trips = await _tripService.loadTrips();
    final expenseEntries = await _expenseService.loadExpenseEntries();
    final fuelEntries = await _fuelService.loadFuelEntries();
    final workModeSettings = await _workModeService.loadSettings();

    final payload = {
      'appName': _appName,
      'backupVersion': _backupVersion,
      'updatedAt': FieldValue.serverTimestamp(),
      'exportedAt': DateTime.now().toIso8601String(),
      'preferences': preferences.toJson(),
      'trips': trips.map(tripToBackupJson).toList(),
      'expenseEntries': expenseEntries.map((e) => e.toJson()).toList(),
      'fuelEntries': fuelEntries.map((e) => e.toJson()).toList(),
      'workModeSettings': workModeSettings.toJson(),
    };

    await _backupRef.set(payload);
    await _verifyServerBackup(
      tripCount: trips.length,
      expenseCount: expenseEntries.length,
      fuelCount: fuelEntries.length,
    );
  }

  Future<void> _verifyServerBackup({
    required int tripCount,
    required int expenseCount,
    required int fuelCount,
  }) async {
    final doc = await _backupRef.get(const GetOptions(source: Source.server));
    if (!doc.exists) throw StateError('Cloud backup was not saved');

    final data = doc.data();
    if (data == null) throw StateError('Cloud backup was not saved');

    final trips = data['trips'];
    final expenses = data['expenseEntries'];
    final fuel = data['fuelEntries'];
    if (trips is! List || trips.length != tripCount) {
      throw StateError('Cloud backup verification failed');
    }
    if (expenses is! List || expenses.length != expenseCount) {
      throw StateError('Cloud backup verification failed');
    }
    if (fuel is! List || fuel.length != fuelCount) {
      throw StateError('Cloud backup verification failed');
    }
  }

  Future<CloudRestoreResult> restoreBackupForCurrentUser() async {
    if (_uid == null) throw StateError('Not signed in');

    final doc = await _backupRef.get(const GetOptions(source: Source.server));
    if (!doc.exists) throw StateError('No cloud backup found');

    final data = doc.data()!;

    final version = data['backupVersion'];
    if (version is int && version > _backupVersion) {
      throw StateError('Backup version $version is not supported');
    }

    final prefsJson = data['preferences'];
    if (prefsJson is Map) {
      await _prefsService.savePreferences(
        UserPreferences.fromJson(Map<String, dynamic>.from(prefsJson)),
      );
    }

    final tripsJson = data['trips'];
    var restoredTrips = 0;
    var skippedTrips = 0;
    if (tripsJson is List<dynamic>) {
      final trips = <Trip>[];
      for (final item in tripsJson) {
        if (item is! Map) {
          skippedTrips++;
          continue;
        }
        try {
          trips.add(Trip.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          skippedTrips++;
          // Skip malformed entries without aborting the restore.
        }
      }
      await _tripService.saveTrips(trips);
      restoredTrips = trips.length;
    }

    final workJson = data['workModeSettings'];
    if (workJson is Map) {
      await _workModeService.saveSettings(
        WorkModeSettings.fromJson(Map<String, dynamic>.from(workJson)),
      );
    }

    final fuelJson = data['fuelEntries'];
    var restoredFuel = 0;
    var skippedFuel = 0;
    if (fuelJson is List<dynamic>) {
      final fuelEntries = <FuelEntry>[];
      for (final item in fuelJson) {
        if (item is! Map) {
          skippedFuel++;
          continue;
        }
        try {
          fuelEntries.add(FuelEntry.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          skippedFuel++;
          // Skip malformed entries without aborting the restore.
        }
      }
      await _fuelService.saveFuelEntries(fuelEntries);
      restoredFuel = fuelEntries.length;
    }

    final expenseJson = data['expenseEntries'];
    var restoredExpenses = 0;
    var skippedExpenses = 0;
    if (expenseJson is List<dynamic>) {
      final expenseEntries = <ExpenseEntry>[];
      for (final item in expenseJson) {
        if (item is! Map) {
          skippedExpenses++;
          continue;
        }
        try {
          expenseEntries.add(
            ExpenseEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          skippedExpenses++;
          // Skip malformed entries without aborting the restore.
        }
      }
      await _expenseService.saveExpenseEntries(expenseEntries);
      restoredExpenses = expenseEntries.length;
    }

    return CloudRestoreResult(
      tripCount: restoredTrips,
      expenseCount: restoredExpenses,
      fuelCount: restoredFuel,
      skippedTripCount: skippedTrips,
      skippedExpenseCount: skippedExpenses,
      skippedFuelCount: skippedFuel,
    );
  }

  Future<bool> hasCloudBackup() async {
    if (_uid == null) return false;
    try {
      return (await _backupRef.get(
        const GetOptions(source: Source.server),
      )).exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasCloudBackupOrThrow() async {
    if (_uid == null) throw StateError('Not signed in');
    return (await _backupRef.get(
      const GetOptions(source: Source.server),
    )).exists;
  }

  Future<bool> restoreIfLocalDataIsEmpty() async {
    if (_uid == null) return false;

    final trips = await _tripService.loadTrips();
    final expenses = await _expenseService.loadExpenseEntries();
    final fuelEntries = await _fuelService.loadFuelEntries();
    if (trips.isNotEmpty || expenses.isNotEmpty || fuelEntries.isNotEmpty) {
      return false;
    }

    final hasBackup = await hasCloudBackup();
    if (!hasBackup) return false;

    await restoreBackupForCurrentUser();
    return true;
  }

  Future<DateTime?> getLastCloudBackupTime() async {
    if (_uid == null) return null;
    try {
      final doc = await _backupRef.get(const GetOptions(source: Source.server));
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

  Future<CloudBackupStatus> getServerBackupStatus() async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');

    final doc = await _backupRef.get(const GetOptions(source: Source.server));
    if (!doc.exists) {
      return CloudBackupStatus(uid: uid, exists: false);
    }

    final data = doc.data() ?? <String, dynamic>{};
    final updatedAt = data['updatedAt'];
    final exportedAt = data['exportedAt'];
    final trips = data['trips'];
    final expenses = data['expenseEntries'];
    final fuel = data['fuelEntries'];
    final version = data['backupVersion'];

    return CloudBackupStatus(
      uid: uid,
      exists: true,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      exportedAt: exportedAt is String ? DateTime.tryParse(exportedAt) : null,
      tripCount: trips is List ? trips.length : 0,
      expenseCount: expenses is List ? expenses.length : 0,
      fuelCount: fuel is List ? fuel.length : 0,
      backupVersion: version is int ? version : null,
    );
  }
}
