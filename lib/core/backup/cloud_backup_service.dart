// Recommended Firestore security rules:
//
// match /users/{userId}/backups/{backupId} {
//   allow read, write: if request.auth != null
//                      && request.auth.uid == userId;
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../storage/account_data_store.dart';
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
  CloudBackupService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  static const _appName = 'MarV Route';
  static const _backupVersion = 1;
  static const _serverReadTimeout = Duration(seconds: 10);

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  String? get _uid => (_auth ?? FirebaseAuth.instance).currentUser?.uid;

  _CloudBackupOperation _captureOperation() {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    final scope = AccountDataStore.current;
    if (scope.uid != uid) {
      throw StateError('Account data is not ready for this user');
    }
    return _CloudBackupOperation(
      uid: uid,
      scope: scope,
      reference: _db
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc('latest'),
    );
  }

  void _ensureCurrent(_CloudBackupOperation operation) {
    if (_uid != operation.uid ||
        !identical(AccountDataStore.current, operation.scope)) {
      throw StateError('Account changed during cloud backup');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _readServerBackup(
    _CloudBackupOperation operation,
  ) async {
    _ensureCurrent(operation);
    final document = await operation.reference
        .get(const GetOptions(source: Source.server))
        .timeout(_serverReadTimeout);
    _ensureCurrent(operation);
    return document;
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
    final operation = _captureOperation();

    final preferences = await operation.preferences.loadPreferences();
    final trips = await operation.trips.loadTrips();
    final expenseEntries = await operation.expenses.loadExpenseEntries();
    final fuelEntries = await operation.fuel.loadFuelEntries();
    final workModeSettings = await operation.workMode.loadSettings();

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

    _ensureCurrent(operation);
    await operation.reference.set(payload);
    _ensureCurrent(operation);
    await _verifyServerBackup(
      operation: operation,
      tripCount: trips.length,
      expenseCount: expenseEntries.length,
      fuelCount: fuelEntries.length,
    );
  }

  Future<void> _verifyServerBackup({
    required _CloudBackupOperation operation,
    required int tripCount,
    required int expenseCount,
    required int fuelCount,
  }) async {
    final doc = await _readServerBackup(operation);
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
    return _restore(_captureOperation());
  }

  Future<CloudRestoreResult> _restore(
    _CloudBackupOperation operation, {
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    _ensureCurrent(operation);
    final doc = document ?? await _readServerBackup(operation);
    _ensureCurrent(operation);
    if (!doc.exists) throw StateError('No cloud backup found');

    final data = doc.data()!;

    final version = data['backupVersion'];
    if (version is int && version > _backupVersion) {
      throw StateError('Backup version $version is not supported');
    }

    final prefsJson = data['preferences'];
    if (prefsJson is Map) {
      _ensureCurrent(operation);
      await operation.preferences.savePreferences(
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
      _ensureCurrent(operation);
      await operation.trips.saveTrips(trips);
      restoredTrips = trips.length;
    }

    final workJson = data['workModeSettings'];
    if (workJson is Map) {
      _ensureCurrent(operation);
      await operation.workMode.saveSettings(
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
      _ensureCurrent(operation);
      await operation.fuel.saveFuelEntries(fuelEntries);
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
      _ensureCurrent(operation);
      await operation.expenses.saveExpenseEntries(expenseEntries);
      restoredExpenses = expenseEntries.length;
    }

    _ensureCurrent(operation);
    return CloudRestoreResult(
      tripCount: restoredTrips,
      expenseCount: restoredExpenses,
      fuelCount: restoredFuel,
      skippedTripCount: skippedTrips,
      skippedExpenseCount: skippedExpenses,
      skippedFuelCount: skippedFuel,
    );
  }

  /// Removes the user's cloud backup. Must run while still signed in, since
  /// the Firestore rules key the document on the caller's uid.
  Future<void> deleteBackupForCurrentUser() async {
    final operation = _captureOperation();
    await operation.reference.delete();
    _ensureCurrent(operation);
  }

  Future<bool> hasCloudBackup() async {
    if (_uid == null) return false;
    try {
      return await hasCloudBackupOrThrow();
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasCloudBackupOrThrow() async {
    final operation = _captureOperation();
    final doc = await _readServerBackup(operation);
    return doc.exists;
  }

  Future<bool> restoreIfLocalDataIsEmpty() async {
    if (_uid == null) return false;
    final operation = _captureOperation();
    if (!await _isLocalDataEmpty(operation)) return false;

    // The caller must distinguish a verified absence from an offline failure:
    // uploading empty local data after a failed read could erase a cloud copy.
    final doc = await _readServerBackup(operation);
    _ensureCurrent(operation);
    if (!doc.exists) return false;
    // A resumed connection may return after the user has created local records.
    // Automatic recovery must not replace work saved while the read was pending.
    if (!await _isLocalDataEmpty(operation)) return false;

    await _restore(operation, document: doc);
    return true;
  }

  Future<bool> _isLocalDataEmpty(_CloudBackupOperation operation) async {
    final trips = await operation.trips.loadTrips();
    final expenses = await operation.expenses.loadExpenseEntries();
    final fuelEntries = await operation.fuel.loadFuelEntries();
    _ensureCurrent(operation);
    return trips.isEmpty && expenses.isEmpty && fuelEntries.isEmpty;
  }

  Future<DateTime?> getLastCloudBackupTime() async {
    if (_uid == null) return null;
    try {
      final operation = _captureOperation();
      final doc = await _readServerBackup(operation);
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
    final operation = _captureOperation();

    final doc = await _readServerBackup(operation);
    if (!doc.exists) {
      return CloudBackupStatus(uid: operation.uid, exists: false);
    }

    final data = doc.data() ?? <String, dynamic>{};
    final updatedAt = data['updatedAt'];
    final exportedAt = data['exportedAt'];
    final trips = data['trips'];
    final expenses = data['expenseEntries'];
    final fuel = data['fuelEntries'];
    final version = data['backupVersion'];

    return CloudBackupStatus(
      uid: operation.uid,
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

// A service can live longer than a sign-in session. Each operation must keep
// both its local storage and remote document bound to the same account.
class _CloudBackupOperation {
  _CloudBackupOperation({
    required this.uid,
    required this.scope,
    required this.reference,
  }) : preferences = PreferencesService(scope: scope),
       trips = TripService(scope: scope),
       expenses = ExpenseService(scope: scope),
       fuel = FuelService(scope: scope),
       workMode = WorkModeService(scope: scope);

  final String uid;
  final AccountDataScope scope;
  final DocumentReference<Map<String, dynamic>> reference;
  final PreferencesService preferences;
  final TripService trips;
  final ExpenseService expenses;
  final FuelService fuel;
  final WorkModeService workMode;
}
