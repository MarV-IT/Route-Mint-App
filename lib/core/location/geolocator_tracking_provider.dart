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
  const settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  );
  return Geolocator.getPositionStream(locationSettings: settings).map(
    (pos) => TrackingPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      timestamp: pos.timestamp,
    ),
  );
}
