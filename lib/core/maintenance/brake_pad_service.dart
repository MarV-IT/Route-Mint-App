import '../preferences/user_preferences.dart';

class BrakePadService {
  double? nextBrakePadChangeDueAtKm(UserPreferences prefs) {
    final last = prefs.lastBrakePadChangeOdometerKm;
    final interval = prefs.brakePadChangeIntervalKm;
    if (last == null || interval == null) return null;
    return last + interval;
  }

  double? distanceUntilBrakePadChangeKm(UserPreferences prefs) {
    final odometer = prefs.vehicleOdometerKm;
    final due = nextBrakePadChangeDueAtKm(prefs);
    if (odometer == null || due == null) return null;
    return due - odometer;
  }

  bool isBrakePadChangeDue(UserPreferences prefs) {
    final remaining = distanceUntilBrakePadChangeKm(prefs);
    if (remaining == null) return false;
    return remaining <= 0;
  }

  bool shouldWarnBrakePadChangeSoon(UserPreferences prefs) {
    final remaining = distanceUntilBrakePadChangeKm(prefs);
    final threshold = prefs.brakePadReminderThresholdKm;
    if (remaining == null || threshold == null) return false;
    return remaining > 0 && remaining <= threshold;
  }
}
