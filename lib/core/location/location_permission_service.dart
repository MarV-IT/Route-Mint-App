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

  /// Runs [beforePermissionRequest] only when a native prompt is needed.
  /// Keeping the explanation at this decision avoids a second permission
  /// check unexpectedly asking for access without the user's agreement.
  Future<LocationPermissionStatus> checkAndRequest({
    Future<bool> Function()? beforePermissionRequest,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (beforePermissionRequest != null && !await beforePermissionRequest()) {
        return LocationPermissionStatus.denied;
      }
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
    }
  }
}
