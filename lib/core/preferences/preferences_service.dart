import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_preferences.dart';

class PreferencesService {
  static const String _key = 'user_preferences';

  Future<UserPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(preferences.toJson()));
  }
}
