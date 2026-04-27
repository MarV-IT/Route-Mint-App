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
///
/// Used by AddTripScreen before persisting a new Trip so that
/// Trip.distance is always stored in km regardless of the user's display unit.
double toKilometers(double distance, AppUnit storedUnit) {
  if (storedUnit == AppUnit.kilometers) return distance;
  return distance / 0.621371; // miles → km
}
