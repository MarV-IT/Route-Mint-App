import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_mode_settings.dart';

class WorkModeService {
  static const String _key = 'work_mode_settings';

  Future<WorkModeSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) {
      return WorkModeSettings.defaults();
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return WorkModeSettings.defaults();

      return WorkModeSettings.fromJson(decoded);
    } catch (_) {
      return WorkModeSettings.defaults();
    }
  }

  Future<void> saveSettings(WorkModeSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
