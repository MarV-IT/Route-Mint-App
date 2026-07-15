import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'auto_trip_detection_service.dart';
import 'foreground_trip_tracking_service.dart';
import 'tracking_result.dart';

// App-level singleton wired to the device GPS.
final ForegroundTripTrackingService appTrackingService =
    ForegroundTripTrackingService(
      pointStreamFactory: geolocatorTrackingStream,
      initialPositionProvider: _geolocatorCurrentPosition,
      stopPositionProvider: _geolocatorCurrentPosition,
    );

final AutoTripDetectionService appAutoDetectionService =
    AutoTripDetectionService(
      monitoringStreamFactory: geolocatorMonitoringStream,
      initialPositionProvider: _geolocatorCurrentPosition,
    );

Future<TrackingPoint?> _geolocatorCurrentPosition() async {
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: _currentPositionSettings(),
  ).timeout(const Duration(seconds: 15));
  return TrackingPoint(
    latitude: pos.latitude,
    longitude: pos.longitude,
    accuracyMeters: pos.accuracy,
    timestamp: DateTime.now(),
  );
}

LocationSettings _currentPositionSettings() {
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }
  if (Platform.isIOS) {
    return AppleSettings(accuracy: LocationAccuracy.bestForNavigation);
  }
  return const LocationSettings(accuracy: LocationAccuracy.bestForNavigation);
}

/// Background updates require the `location` UIBackgroundModes entry in
/// Info.plist; without it iOS terminates the stream when the app is
/// backgrounded (and CoreLocation rejects allowBackgroundLocationUpdates).
AppleSettings _appleStreamSettings({required int distanceFilter}) =>
    AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: distanceFilter,
      activityType: ActivityType.automotiveNavigation,
      allowBackgroundLocationUpdates: true,
      showBackgroundLocationIndicator: true,
      pauseLocationUpdatesAutomatically: false,
    );

Stream<TrackingPoint> geolocatorMonitoringStream() {
  final LocationSettings settings;
  if (Platform.isAndroid) {
    settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 3),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'MarV Route is watching for trips',
        notificationText:
            'Trip detection is active. A notification is shown while monitoring.',
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
  } else if (Platform.isIOS) {
    settings = _appleStreamSettings(distanceFilter: 5);
  } else {
    settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }
  return Geolocator.getPositionStream(locationSettings: settings).map(
    (pos) => TrackingPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      timestamp: DateTime.now(),
    ),
  );
}

Stream<TrackingPoint> geolocatorTrackingStream() {
  final LocationSettings settings;
  if (Platform.isAndroid) {
    // AndroidSettings starts a foreground service so tracking continues
    // while the screen is off. The notification is dismissed automatically
    // when the stream subscription is cancelled (Stop Tracking).
    settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
      intervalDuration: const Duration(seconds: 2),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'MarV Route is tracking your trip',
        notificationText: 'Tracking continues while your screen is off.',
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
  } else if (Platform.isIOS) {
    settings = _appleStreamSettings(distanceFilter: 3);
  } else {
    settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }
  return Geolocator.getPositionStream(locationSettings: settings).map(
    (pos) => TrackingPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      timestamp: DateTime.now(),
    ),
  );
}
