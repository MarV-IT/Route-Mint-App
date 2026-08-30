import 'package:geolocator/geolocator.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationPermissionService {
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Opens the system screen where location services are switched on. The app
  /// cannot enable them itself, so this is the only way to get the user there.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<LocationPermissionStatus> checkAndRequest() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      default:
        return LocationPermissionStatus.granted;
    }
  }
}
