import 'dart:convert';
import '../storage/account_data_store.dart';
import 'user_preferences.dart';

class PreferencesService {
  PreferencesService({AccountDataScope? scope})
    : _scope = scope ?? AccountDataStore.current;

  final AccountDataScope _scope;
  static const String _key = 'user_preferences';

  Future<UserPreferences> loadPreferences() async {
    final prefs = await _scope.getPreferences();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return UserPreferences.defaults();

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserPreferences.fromJson(json);
    } catch (_) {
      // Corrupt data — return defaults rather than crashing.
      return UserPreferences.defaults();
    }
  }

  Future<void> savePreferences(UserPreferences preferences) async {
    final prefs = await _scope.getPreferences();
    await prefs.setString(_key, jsonEncode(preferences.toJson()));
  }
}
