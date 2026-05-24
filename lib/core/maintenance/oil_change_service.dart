import '../preferences/user_preferences.dart';

class OilChangeService {
  double? nextOilChangeDueAtKm(UserPreferences prefs) {
    final last = prefs.lastOilChangeOdometerKm;
    final interval = prefs.oilChangeIntervalKm;
    if (last == null || interval == null) return null;
    return last + interval;
  }

  double? distanceUntilOilChangeKm(UserPreferences prefs) {
    final odometer = prefs.vehicleOdometerKm;
    final due = nextOilChangeDueAtKm(prefs);
    if (odometer == null || due == null) return null;
    return due - odometer;
  }

  bool isOilChangeDue(UserPreferences prefs) {
    final remaining = distanceUntilOilChangeKm(prefs);
    if (remaining == null) return false;
    return remaining <= 0;
  }

  bool shouldWarnOilChangeSoon(UserPreferences prefs) {
    final remaining = distanceUntilOilChangeKm(prefs);
    final threshold = prefs.oilChangeReminderThresholdKm;
    if (remaining == null || threshold == null) return false;
    return remaining > 0 && remaining <= threshold;
  }
}
