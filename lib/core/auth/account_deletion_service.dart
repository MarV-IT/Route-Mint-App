import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backup/cloud_backup_service.dart';
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
  }) : _authServiceOverride = authService,
       _cloudBackupServiceOverride = cloudBackupService,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final AuthService? _authServiceOverride;
  final CloudBackupService? _cloudBackupServiceOverride;
  final FlutterSecureStorage _secureStorage;

  // Built lazily so [clearLocalData] works without an initialized Firebase.
  late final AuthService _authService = _authServiceOverride ?? AuthService();
  late final CloudBackupService _cloudBackupService =
      _cloudBackupServiceOverride ?? CloudBackupService();

  /// Every SharedPreferences key holding account-owned data. A new feature
  /// that persists user data must add its key here, otherwise that data
  /// would survive an account deletion.
  static const localDataKeys = <String>[
    'user_preferences',
    'trips',
    'expense_entries',
    'fuel_entries',
    'work_mode_settings',
    'app_unit',
    'app_language',
    'app_country',
    'firebase_auth_session_expected',
  ];

  /// The cloud copy is removed first because the Firestore rules only allow
  /// the owner to delete it — once the Firebase account is gone, so is that
  /// permission. Local data is wiped last so a failed account deletion
  /// leaves the user's records intact.
  Future<void> deleteAccountAndData() async {
    await _cloudBackupService.deleteBackupForCurrentUser();
    await _authService.deleteAccount();
    await clearLocalData();
  }

  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in localDataKeys) {
      await prefs.remove(key);
    }
    await _secureStorage.deleteAll();
  }
}
