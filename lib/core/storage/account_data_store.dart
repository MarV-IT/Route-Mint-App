import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local keys that belong to one account, never to the Firebase session.
const accountDataKeys = <String>[
  'user_preferences',
  'trips',
  'expense_entries',
  'fuel_entries',
  'work_mode_settings',
  'app_unit',
  'app_language',
  'app_country',
  'auto_detection_active_trip',
  'auto_detection_monitoring',
];

/// An immutable storage owner. Services retain this scope so an operation
/// started before logout cannot write into the next signed-in account.
class AccountDataScope {
  const AccountDataScope._(this.uid, this.namespace);

  final String? uid;
  final String namespace;

  Future<ScopedPreferences> getPreferences() async =>
      ScopedPreferences._(await SharedPreferences.getInstance(), this);

  Future<void> clear() async {
    final preferences = await getPreferences();
    await preferences.clear();
  }
}

/// A small SharedPreferences view that never exposes another owner's keys.
class ScopedPreferences {
  ScopedPreferences._(this._preferences, this.scope);

  final SharedPreferences _preferences;
  final AccountDataScope scope;

  String _key(String key) => '${scope.namespace}$key';

  Object? get(String key) => _preferences.get(_key(key));
  String? getString(String key) => _preferences.getString(_key(key));
  bool? getBool(String key) => _preferences.getBool(_key(key));
  bool containsKey(String key) => _preferences.containsKey(_key(key));

  Set<String> getKeys() => scope.namespace.isEmpty
      ? _preferences.getKeys().where(accountDataKeys.contains).toSet()
      : _preferences
            .getKeys()
            .where((key) => key.startsWith(scope.namespace))
            .map((key) => key.substring(scope.namespace.length))
            .toSet();

  Future<bool> setString(String key, String value) =>
      _requireWrite(_preferences.setString(_key(key), value));
  Future<bool> setBool(String key, bool value) =>
      _requireWrite(_preferences.setBool(_key(key), value));
  Future<bool> remove(String key) =>
      _requireWrite(_preferences.remove(_key(key)));

  Future<bool> clear() async {
    for (final key in getKeys()) {
      await remove(key);
    }
    return true;
  }
}

/// Selects account storage before constructing the app's account-owned services.
class AccountDataStore {
  AccountDataStore._();

  static const accountDataKeys = _accountDataKeys;
  static const _legacyOwnerKey = 'account_data_v1_legacy_owner';
  static const _legacyCompletedKey = 'account_data_v1_legacy_completed';
  static const _quarantinedOwner = 'unassigned';
  static const _presentationFields = <String>[
    'country',
    'currencyCode',
    'unit',
    'language',
    'onboardingCompleted',
    'themeMode',
  ];

  // The unscoped fallback supports existing standalone service tests. Production
  // startup must await activate() before any account-owned services are created.
  static AccountDataScope _current = const AccountDataScope._(null, '');
  static Future<void> _activation = Future<void>.value();

  static AccountDataScope get current => _current;

  /// Legacy data is claimed only when startup has already identified its signed
  /// in owner. Once observed signed out, it stays quarantined: a later signup
  /// must never inherit the previous user's trips or profile.
  static Future<void> activate(String? uid, {bool claimLegacy = false}) {
    if (uid != null && uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'Account UID cannot be empty');
    }
    if (claimLegacy && uid == null) {
      throw ArgumentError(
        'Only an authenticated account can claim legacy data',
      );
    }
    final next = _activation.then((_) => _activate(uid, claimLegacy));
    // A failed write must be retryable without poisoning the activation queue.
    _activation = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  static Future<void> _activate(String? uid, bool claimLegacy) async {
    final namespace = uid == null
        ? 'account_data_v1:guest:'
        : 'account_data_v1:user:${base64Url.encode(utf8.encode(uid))}:';
    final preferences = await SharedPreferences.getInstance();
    final scope = AccountDataScope._(uid, namespace);
    var legacyOwner = preferences.getString(_legacyOwnerKey);
    if (legacyOwner == null) {
      legacyOwner = uid != null && claimLegacy ? namespace : _quarantinedOwner;
      // Reserve the owner first so even an interrupted migration cannot be
      // claimed by a different account on the next app launch.
      await _requireWrite(preferences.setString(_legacyOwnerKey, legacyOwner));
    }
    if (legacyOwner == namespace &&
        preferences.getBool(_legacyCompletedKey) != true) {
      for (final key in accountDataKeys) {
        final value = preferences.get(key);
        final destination = '$namespace$key';
        if (value != null && !preferences.containsKey(destination)) {
          await _copyValue(preferences, destination, value);
        }
      }
      // Retain raw data until all writes succeeded. The completion marker
      // prevents old records from reappearing after a scoped clear or deletion.
      await _requireWrite(preferences.setBool(_legacyCompletedKey, true));
    }

    final scopedPreferences = ScopedPreferences._(preferences, scope);
    if (!scopedPreferences.containsKey('user_preferences')) {
      final previous = preferences.getString(
        '${_current.namespace}user_preferences',
      );
      final presentation = _presentationPreferences(
        previous ?? preferences.getString('user_preferences'),
      );
      await scopedPreferences.setString(
        'user_preferences',
        jsonEncode(presentation),
      );
    }
    for (final key in ['app_unit', 'app_language', 'app_country']) {
      if (scopedPreferences.containsKey(key)) continue;
      final value =
          preferences.getString('${_current.namespace}$key') ??
          preferences.getString(key);
      if (value != null) await scopedPreferences.setString(key, value);
    }
    // Each activation represents a new session, even after a rapid logout and
    // return to the same UID. Old async operations must fail identity checks.
    // Publish only a completely prepared scope, after every required write.
    _current = scope;
  }

  /// Removes the retained migration backup during an explicit account deletion.
  /// The owner decision remains so old data can never be migrated again.
  static Future<void> clearLegacyDataForOwner(AccountDataScope scope) async {
    if (scope.uid == null || scope.namespace.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(_legacyOwnerKey) != scope.namespace) return;
    await _requireWrite(preferences.setBool(_legacyCompletedKey, true));
    for (final key in accountDataKeys) {
      await _requireWrite(preferences.remove(key));
    }
  }

  static Map<String, dynamic> _presentationPreferences(String? raw) {
    if (raw == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, dynamic>{};
      return {
        for (final key in _presentationFields)
          if (decoded.containsKey(key)) key: decoded[key],
      };
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _current = const AccountDataScope._(null, '');
    _activation = Future<void>.value();
  }
}

// Separate alias prevents the static constant from shadowing the public list.
const _accountDataKeys = accountDataKeys;

Future<bool> _requireWrite(Future<bool> operation) async {
  if (!await operation) {
    throw StateError('Could not persist account data');
  }
  return true;
}

Future<void> _copyValue(
  SharedPreferences preferences,
  String key,
  Object value,
) async {
  final Future<bool> operation;
  if (value is String) {
    operation = preferences.setString(key, value);
  } else if (value is bool) {
    operation = preferences.setBool(key, value);
  } else if (value is int) {
    operation = preferences.setInt(key, value);
  } else if (value is double) {
    operation = preferences.setDouble(key, value);
  } else if (value is List<String>) {
    operation = preferences.setStringList(key, value);
  } else {
    throw StateError('Unsupported account preference type');
  }
  await _requireWrite(operation);
}
