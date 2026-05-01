import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'foreground_trip_tracking_service.dart';
import 'tracking_result.dart';

// App-level singleton wired to the device GPS.
// Using a top-level variable because ForegroundTripTrackingService
// is intentionally not a singleton to keep it testable.
final ForegroundTripTrackingService appTrackingService =
    ForegroundTripTrackingService(
  pointStreamFactory: _geolocatorStream,
);

Stream<TrackingPoint> _geolocatorStream() {
  final LocationSettings settings;
  if (Platform.isAndroid) {
    // AndroidSettings starts a foreground service so tracking continues
    // while the screen is off. The notification is dismissed automatically
    // when the stream subscription is cancelled (Stop Tracking).
    settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'MarV Route is tracking your trip',
        notificationText: 'Tracking continues while your screen is off.',
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
  } else {
    settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );
  }
  return Geolocator.getPositionStream(locationSettings: settings).map(
    (pos) => TrackingPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      timestamp: pos.timestamp,
    ),
  );
}
