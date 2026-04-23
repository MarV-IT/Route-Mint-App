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
