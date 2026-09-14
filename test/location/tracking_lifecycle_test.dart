import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_mint_app/core/location/auto_trip_detection_service.dart';
import 'package:route_mint_app/core/location/foreground_trip_tracking_service.dart';
import 'package:route_mint_app/core/location/tracking_result.dart';
import 'package:route_mint_app/core/location/trip_recovery_store.dart';

TrackingPoint point(int second, {double? longitude}) => TrackingPoint(
  latitude: 0,
  longitude: longitude ?? second * 0.0001,
  accuracyMeters: 10,
  timestamp: DateTime(2026, 9, 1).add(Duration(seconds: second)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('manual trips retain distance and start beyond the route cap', () async {
    final controller = StreamController<TrackingPoint>();
    final service = ForegroundTripTrackingService(
      pointStreamFactory: () => controller.stream,
    );
    await service.startTracking();
    final points = List.generate(2200, point);
    for (final point in points) {
      controller.add(point);
    }
    await Future<void>.delayed(Duration.zero);
    final (result, reason) = await service.stopTracking();
    expect(reason, isNull);
    expect(result!.startedAt, points.first.timestamp);
    expect(result.points.length, lessThanOrEqualTo(1000));
    expect(
      result.distanceKm,
      closeTo(TrackingResult.calculateDistanceKm(points), 0.000001),
    );
    await controller.close();
  });

  test(
    'stopping during the initial fix cannot restart manual tracking',
    () async {
      final controller = StreamController<TrackingPoint>();
      final initial = Completer<TrackingPoint?>();
      var subscriptions = 0;
      final service = ForegroundTripTrackingService(
        pointStreamFactory: () {
          subscriptions++;
          return controller.stream;
        },
        initialPositionProvider: () => initial.future,
        stopPositionProvider: () async => null,
      );
      final firstStart = service.startTracking();
      final secondStart = service.startTracking();
      await service.stopTracking();
      initial.complete(point(0));
      expect(await firstStart, isFalse);
      expect(await secondStart, isFalse);
      expect(subscriptions, 1);
      expect(service.isTracking, isFalse);
      expect(service.activeRouteNotifier.value, isEmpty);
      await controller.close();
    },
  );

  test('a new manual trip waits until the old stop sample completes', () async {
    final first = StreamController<TrackingPoint>();
    final second = StreamController<TrackingPoint>();
    final stopPoint = Completer<TrackingPoint?>();
    var streams = 0;
    var stops = 0;
    final service = ForegroundTripTrackingService(
      pointStreamFactory: () => streams++ == 0 ? first.stream : second.stream,
      stopPositionProvider: () =>
          stops++ == 0 ? stopPoint.future : Future.value(),
    );
    await service.startTracking();
    first.add(point(0));
    await Future<void>.delayed(Duration.zero);
    final stopping = service.stopTracking();
    final starting = service.startTracking();
    expect(streams, 1);
    stopPoint.complete(point(100));
    expect((await stopping).$1, isNotNull);
    expect(await starting, isTrue);
    second.add(point(200));
    await Future<void>.delayed(Duration.zero);
    expect(
      service.activeRouteNotifier.value.single.timestamp,
      point(200).timestamp,
    );
    await service.stopTracking();
    await first.close();
    await second.close();
  });

  test('manual stream completion updates tracking state', () async {
    final controller = StreamController<TrackingPoint>();
    final service = ForegroundTripTrackingService(
      pointStreamFactory: () => controller.stream,
    );
    await service.startTracking();
    controller.add(point(0));
    controller.add(point(100));
    await controller.close();
    expect(service.isTracking, isFalse);
    expect(service.isTrackingNotifier.value, isFalse);
    expect(service.hasPendingTripNotifier.value, isTrue);
    expect(await service.startTracking(), isFalse);
    expect((await service.stopTracking()).$1, isNotNull);
    expect(service.hasPendingTripNotifier.value, isFalse);
  });

  test('manual tracking ignores delayed and duplicate fixes', () async {
    final controller = StreamController<TrackingPoint>();
    final service = ForegroundTripTrackingService(
      pointStreamFactory: () => controller.stream,
    );
    await service.startTracking();
    controller.add(point(0));
    controller.add(point(100));
    controller.add(point(50, longitude: 3));
    controller.add(point(100));
    await Future<void>.delayed(Duration.zero);
    final (result, _) = await service.stopTracking();
    expect(result!.points, hasLength(2));
    expect(result.distanceKm, closeTo(1.11195, 0.00001));
    await controller.close();
  });

  test(
    'stopping during the initial fix leaves automatic detection stopped',
    () async {
      final controller = StreamController<TrackingPoint>();
      final initial = Completer<TrackingPoint?>();
      final service = AutoTripDetectionService(
        monitoringStreamFactory: () => controller.stream,
        initialPositionProvider: () => initial.future,
      );
      final starting = service.startMonitoring();
      await service.stopMonitoring();
      initial.complete(point(0));
      await starting;
      expect(service.state, AutoDetectionState.idle);
      expect(await TripRecoveryStore().wasMonitoring(), isFalse);
      await controller.close();
    },
  );

  test(
    'automatic location errors stop monitoring without an unhandled error',
    () async {
      final controller = StreamController<TrackingPoint>();
      final service = AutoTripDetectionService(
        monitoringStreamFactory: () => controller.stream,
      );
      await service.startMonitoring();
      controller.addError(StateError('Location permission revoked'));
      await Future<void>.delayed(Duration.zero);
      await service.stopMonitoring();
      expect(service.state, AutoDetectionState.idle);
      expect(await TripRecoveryStore().wasMonitoring(), isFalse);
      await controller.close();
    },
  );

  test('automatic detection clears state when stream creation fails', () async {
    final service = AutoTripDetectionService(
      monitoringStreamFactory: () => throw StateError('Location disabled'),
    );
    await expectLater(service.startMonitoring(), throwsStateError);
    expect(service.state, AutoDetectionState.idle);
  });

  test('invalid native coordinates and negative accuracy are rejected', () {
    for (final invalid in [
      (double.nan, 0.0, 10.0),
      (91.0, 0.0, 10.0),
      (0.0, 181.0, 10.0),
      (0.0, 0.0, -1.0),
    ]) {
      expect(
        TrackingPoint(
          latitude: invalid.$1,
          longitude: invalid.$2,
          accuracyMeters: invalid.$3,
          timestamp: DateTime(2026),
        ).isAccurateEnough(200),
        isFalse,
      );
    }
    expect(
      TrackingPoint.fromJson({'latitude': 0, 'longitude': 0, 'timestamp': 123}),
      isNull,
    );
  });
}
