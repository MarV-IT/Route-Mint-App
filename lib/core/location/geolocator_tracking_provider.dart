import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import '../../features/trips/models/trip.dart';
import '../../features/trips/services/trip_service.dart';
import '../../features/work_mode/services/work_mode_service.dart';
import '../storage/account_data_store.dart';
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

/// Called before changing the active account or deleting its local data.
/// Both start gates close synchronously, and all final writes keep the scope
/// captured when the route began. No geocoding is needed to preserve the trip.
Future<void> prepareTrackingForAccountChange({
  ForegroundTripTrackingService? trackingService,
  AutoTripDetectionService? autoDetectionService,
}) async {
  final manual = trackingService ?? appTrackingService;
  final automatic = autoDetectionService ?? appAutoDetectionService;
  final owner = manual.ownerScope ?? AccountDataStore.current;
  final stoppingManual = manual.prepareForAccountChange();
  await Future.wait([
    automatic.prepareForAccountChange(),
    () async {
      final (result, _) = await stoppingManual;
      if (result == null) return;
      final start = result.points.first;
      final end = result.points.last;
      final workMode = WorkModeService(scope: owner);
      final workSettings = await workMode.loadSettings();
      final shift = workMode.matchingShiftAt(workSettings, result.startedAt);
      await TripService(scope: owner).addTrip(
        Trip(
          // The Stop button uses this same ID so simultaneous stop/logout
          // saves update one route instead of incrementing mileage twice.
          id: 'manual_${result.startedAt.microsecondsSinceEpoch}',
          from: 'Detected start',
          to: 'Detected end',
          distance: result.distanceKm,
          category: shift == null ? 'personal' : 'business',
          date: result.startedAt.toLocal(),
          platformName: shift?.platformName,
          detectionMode: TripDetectionMode.automatic,
          reviewStatus: TripReviewStatus.needsReview,
          startTime: result.startedAt.toLocal(),
          endTime: result.endedAt.toLocal(),
          startLatitude: start.latitude,
          startLongitude: start.longitude,
          endLatitude: end.latitude,
          endLongitude: end.longitude,
          routePoints: result.points
              .map(
                (point) => TripRoutePoint(
                  latitude: point.latitude,
                  longitude: point.longitude,
                  timestamp: point.timestamp.toLocal(),
                ),
              )
              .toList(growable: false),
          trackingDiagnostics: TripTrackingDiagnostics(
            rawPointCount: result.rawPointCount,
            validPointCount: result.validPointCount,
            droppedPointCount: result.droppedPointCount,
            averageAccuracyMeters: result.averageAccuracyMeters,
            maxGapSeconds: result.maxGapSeconds,
            durationSeconds: result.endedAt
                .difference(result.startedAt)
                .inSeconds,
          ),
        ),
      );
      manual.acknowledgeAccountChangeTrip(result);
    }(),
  ]);
}

/// Release the gates after the coordinator activates the next account scope.
void completeTrackingAccountChange({
  ForegroundTripTrackingService? trackingService,
  AutoTripDetectionService? autoDetectionService,
}) {
  (trackingService ?? appTrackingService).completeAccountChange();
  (autoDetectionService ?? appAutoDetectionService).completeAccountChange();
}

Future<TrackingPoint?> _geolocatorCurrentPosition() async {
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: _currentPositionSettings(),
  );
  return TrackingPoint(
    latitude: pos.latitude,
    longitude: pos.longitude,
    accuracyMeters: pos.accuracy,
    timestamp: pos.timestamp,
  );
}

LocationSettings _currentPositionSettings() {
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeLimit: const Duration(seconds: 15),
    );
  }
  if (Platform.isIOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      timeLimit: const Duration(seconds: 15),
    );
  }
  return const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    timeLimit: Duration(seconds: 15),
  );
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
      timestamp: pos.timestamp,
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
      timestamp: pos.timestamp,
    ),
  );
}
