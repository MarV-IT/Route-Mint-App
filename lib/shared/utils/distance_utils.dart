import '../../app/app.dart';

String unitLabel(AppUnit unit) {
  return unit == AppUnit.kilometers ? 'km' : 'mi';
}

String formatDistance(double kmValue, AppUnit unit) {
  if (unit == AppUnit.kilometers) {
    return '${kmValue.toStringAsFixed(1)} km';
  }

  final milesValue = kmValue * 0.621371;
  return '${milesValue.toStringAsFixed(1)} mi';
}

/// Converts a user-entered [distance] in [storedUnit] to kilometres.
double toKilometers(double distance, AppUnit storedUnit) {
  if (storedUnit == AppUnit.kilometers) return distance;
  return distance / 0.621371; // miles → km
}

/// Converts a stored km value to the user's display unit.
double fromKilometers(double km, AppUnit unit) {
  if (unit == AppUnit.kilometers) return km;
  return km * 0.621371; // km → miles
}
