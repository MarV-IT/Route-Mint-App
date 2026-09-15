import 'dart:convert';
import '../../../core/storage/account_data_store.dart';
import '../models/work_shift.dart';
import '../models/work_mode_settings.dart';

class WorkModeService {
  WorkModeService({AccountDataScope? scope})
    : _scope = scope ?? AccountDataStore.current;

  final AccountDataScope _scope;
  static const String _key = 'work_mode_settings';

  Future<WorkModeSettings> loadSettings() async {
    final prefs = await _scope.getPreferences();
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
    final prefs = await _scope.getPreferences();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  WorkShift? matchingShiftAt(WorkModeSettings settings, DateTime dateTime) {
    if (!settings.isEnabled) return null;

    final localTime = dateTime.toLocal();
    final currentMinutes = localTime.hour * 60 + localTime.minute;

    for (final shift in settings.shifts) {
      final startMinutes = shift.startHour * 60 + shift.startMinute;
      final endMinutes = shift.endHour * 60 + shift.endMinute;

      final isOvernight = endMinutes < startMinutes;
      final isMatch = isOvernight
          ? currentMinutes >= startMinutes || currentMinutes < endMinutes
          : currentMinutes >= startMinutes && currentMinutes < endMinutes;

      if (isMatch) return shift;
    }

    return null;
  }
}
