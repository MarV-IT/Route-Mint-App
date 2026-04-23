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
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return WorkModeSettings.fromJson(json);
  } catch (e) {
    return WorkModeSettings.defaults();
  }
}

  Future<void> saveSettings(WorkModeSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
