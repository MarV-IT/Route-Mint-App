import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backup/cloud_backup_service.dart';
import '../location/geolocator_tracking_provider.dart';
import '../storage/account_data_store.dart';
import 'auth_service.dart';

/// Deletes the signed-in account together with every trace of its data: the
/// Firestore backup, the Firebase account itself, and all locally stored
/// records.
///
/// Google Play requires apps that let users create an account to also let
/// them delete it along with the data it holds.
class AccountDeletionService {
  AccountDeletionService({
    AuthService? authService,
    CloudBackupService? cloudBackupService,
    FlutterSecureStorage? secureStorage,
    AccountDataScope? scope,
  }) : _authServiceOverride = authService,
       _cloudBackupServiceOverride = cloudBackupService,
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _scope = scope ?? AccountDataStore.current;

  final AuthService? _authServiceOverride;
  final CloudBackupService? _cloudBackupServiceOverride;
  final FlutterSecureStorage _secureStorage;
  final AccountDataScope _scope;

  // Built lazily so [clearLocalData] works without an initialized Firebase.
  late final AuthService _authService = _authServiceOverride ?? AuthService();
  late final CloudBackupService _cloudBackupService =
      _cloudBackupServiceOverride ?? CloudBackupService();

  /// Every SharedPreferences key holding account-owned data. A new feature
  /// that persists user data must add its key here, otherwise that data
  /// would survive an account deletion.
  static const localDataKeys = <String>[
    ...accountDataKeys,
    'firebase_auth_session_expected',
  ];

  /// The cloud copy is removed first because the Firestore rules only allow
  /// the owner to delete it — once the Firebase account is gone, so is that
  /// permission. Local data is wiped last so a failed account deletion
  /// leaves the user's records intact.
  Future<void> deleteAccountAndData() async {
    void requireOwner() {
      if (!identical(_scope, AccountDataStore.current) ||
          _scope.uid == null ||
          _authService.rawCurrentUser?.uid != _scope.uid) {
        throw StateError('The account changed before deletion completed');
      }
    }

    requireOwner();
    try {
      await prepareTrackingForAccountChange();
      requireOwner();
      await _cloudBackupService.deleteBackupForCurrentUser();
      requireOwner();
      await _authService.deleteAccount();
      await clearLocalData();
    } finally {
      completeTrackingAccountChange();
    }
  }

  Future<void> clearLocalData() async {
    await _scope.clear();
    await AccountDataStore.clearLegacyDataForOwner(_scope);
    // Deletion may complete after Firebase has already selected the guest
    // scope; never clear another account's credentials or data.
    if (_scope.namespace == AccountDataStore.current.namespace) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('firebase_auth_session_expected');
      await _secureStorage.deleteAll();
    }
  }
}
