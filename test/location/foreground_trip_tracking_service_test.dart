import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/location/auto_trip_detection_service.dart';
import 'package:route_mint_app/core/location/foreground_trip_tracking_service.dart';
import 'package:route_mint_app/core/location/tracking_result.dart';

void main() {
  group('TrackingResult', () {
    test('ignores poor accuracy points', () {
      final start = DateTime(2026, 4, 27, 9);
      final result = TrackingResult.fromPoints([
        TrackingPoint(
          latitude: 40,
          longitude: -105,
          accuracyMeters: 20,
          timestamp: start,
        ),
        TrackingPoint(
          latitude: 40.5,
          longitude: -105,
          accuracyMeters: 250,
          timestamp: start.add(const Duration(minutes: 5)),
        ),
        TrackingPoint(
          latitude: 41,
          longitude: -105,
          accuracyMeters: 20,
          timestamp: start.add(const Duration(minutes: 10)),
        ),
      ]);

      expect(result, isNotNull);
      expect(result!.points, hasLength(2));
      expect(result.points.every((point) => point.accuracyMeters <= 100), true);
    });

    test('returns null with fewer than two valid points', () {
      final start = DateTime(2026, 4, 27, 9);
      final result = TrackingResult.fromPoints([
        TrackingPoint(
          latitude: 40,
          longitude: -105,
          accuracyMeters: 20,
          timestamp: start,
        ),
        TrackingPoint(
          latitude: 41,
          longitude: -105,
          accuracyMeters: 250,
          timestamp: start.add(const Duration(minutes: 10)),
        ),
      ]);

      expect(result, isNull);
    });

    test('calculates distance in kilometers', () {
      final start = DateTime(2026, 4, 27, 9);
      final result = TrackingResult.fromPoints([
        TrackingPoint(
          latitude: 0,
          longitude: 0,
          accuracyMeters: 10,
          timestamp: start,
        ),
        TrackingPoint(
          latitude: 0,
          longitude: 1,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(minutes: 10)),
        ),
      ]);

      expect(result, isNotNull);
      expect(result!.distanceKm, closeTo(111.195, 0.001));
    });

    test('ignores stationary GPS jitter after real movement', () {
      final start = DateTime(2026, 4, 27, 9);
      final points = <TrackingPoint>[
        TrackingPoint(
          latitude: 0,
          longitude: 0,
          accuracyMeters: 10,
          timestamp: start,
        ),
        TrackingPoint(
          latitude: 0,
          longitude: 0.003,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(minutes: 2)),
        ),
      ];

      for (var i = 0; i < 80; i++) {
        points.add(
          TrackingPoint(
            latitude: 0,
            longitude: i.isEven ? 0.00318 : 0.003,
            accuracyMeters: 10,
            timestamp: start.add(Duration(minutes: 3, seconds: i * 5)),
          ),
        );
      }

      var rawDistanceKm = 0.0;
      for (var i = 1; i < points.length; i++) {
        rawDistanceKm += TrackingResult.distanceBetweenKm(
          points[i - 1],
          points[i],
        );
      }
      final result = TrackingResult.fromPoints(points);

      expect(rawDistanceKm, greaterThan(1.8));
      expect(result, isNotNull);
      expect(result!.points, hasLength(2));
      expect(result.distanceKm, closeTo(0.334, 0.02));
    });

    test('does not save a trip made only from stationary jitter', () {
      final start = DateTime(2026, 4, 27, 9);
      final points = List.generate(30, (i) {
        return TrackingPoint(
          latitude: 0,
          longitude: i.isEven ? 0 : 0.00018,
          accuracyMeters: 10,
          timestamp: start.add(Duration(seconds: i * 10)),
        );
      });

      final result = TrackingResult.fromPoints(points);

      expect(result, isNull);
    });

    test('records GPS quality diagnostics', () {
      final start = DateTime(2026, 4, 27, 9);
      final result = TrackingResult.fromPoints(
        [
          TrackingPoint(
            latitude: 0,
            longitude: 0,
            accuracyMeters: 10,
            timestamp: start,
          ),
          TrackingPoint(
            latitude: 0,
            longitude: 0.003,
            accuracyMeters: 30,
            timestamp: start.add(const Duration(seconds: 45)),
          ),
        ],
        rawPointCountOverride: 3,
        droppedPointCountOverride: 1,
      );

      expect(result, isNotNull);
      expect(result!.rawPointCount, 3);
      expect(result.validPointCount, 2);
      expect(result.droppedPointCount, 1);
      expect(result.averageAccuracyMeters, 20);
      expect(result.maxGapSeconds, 45);
    });
  });

  group('ForegroundTripTrackingService', () {
    test('stopTracking cancels the stream', () async {
      final controller = StreamController<TrackingPoint>();
      var cancelled = false;
      controller.onCancel = () {
        cancelled = true;
      };

      final service = ForegroundTripTrackingService(
        pointStreamFactory: () => controller.stream,
      );
      await service.startTracking();

      expect(service.isTracking, true);

      final (result, reason) = await service.stopTracking();

      expect(result, isNull);
      expect(reason, TrackingFailureReason.noAccuratePoints);
      expect(service.isTracking, false);
      expect(cancelled, true);
    });

    test('samples stop position before calculating result', () async {
      final controller = StreamController<TrackingPoint>();
      final start = DateTime(2026, 4, 27, 9);

      final service = ForegroundTripTrackingService(
        pointStreamFactory: () => controller.stream,
        initialPositionProvider: () async => TrackingPoint(
          latitude: 0,
          longitude: 0,
          accuracyMeters: 10,
          timestamp: start,
        ),
        stopPositionProvider: () async => TrackingPoint(
          latitude: 0,
          longitude: 0.003,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(minutes: 5)),
        ),
      );

      await service.startTracking();
      final (result, reason) = await service.stopTracking();

      expect(reason, isNull);
      expect(result, isNotNull);
      expect(result!.points, hasLength(2));
      expect(result.distanceKm, greaterThan(0.2));
    });
  });

  group('AutoTripDetectionService', () {
    test(
      'seeds monitoring with the current position and starts tracking',
      () async {
        final monitoringController = StreamController<TrackingPoint>();
        final start = DateTime(2026, 4, 27, 9);

        final service = AutoTripDetectionService(
          monitoringStreamFactory: () => monitoringController.stream,
          initialPositionProvider: () async => TrackingPoint(
            latitude: 0,
            longitude: 0,
            accuracyMeters: 10,
            timestamp: start,
          ),
        );

        await service.startMonitoring();
        monitoringController.add(
          TrackingPoint(
            latitude: 0,
            longitude: 0.0023,
            accuracyMeters: 10,
            timestamp: start.add(const Duration(seconds: 30)),
          ),
        );
        monitoringController.add(
          TrackingPoint(
            latitude: 0,
            longitude: 0.0030,
            accuracyMeters: 10,
            timestamp: start.add(const Duration(seconds: 45)),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(service.state, AutoDetectionState.tracking);

        await service.stopMonitoring();
        unawaited(monitoringController.close());
      },
    );

    test(
      'returns noMovement when monitoring points are below trip distance',
      () async {
        final monitoringController = StreamController<TrackingPoint>();

        final service = AutoTripDetectionService(
          monitoringStreamFactory: () => monitoringController.stream,
        );

        await service.startMonitoring();
        final outcome = await service.stopMonitoring();

        expect(outcome, AutoStopOutcome.noMovement);

        unawaited(monitoringController.close());
      },
    );

    test('does not start tracking from compact stationary GPS drift', () async {
      final monitoringController = StreamController<TrackingPoint>.broadcast();
      final start = DateTime(2026, 4, 27, 9);

      final service = AutoTripDetectionService(
        monitoringStreamFactory: () => monitoringController.stream,
      );

      await service.startMonitoring();
      final points = [
        (0.00000, 0.00000),
        (0.00040, 0.00000),
        (0.00040, 0.00040),
        (0.00000, 0.00040),
        (-0.00040, 0.00040),
        (-0.00040, 0.00000),
        (0.00000, -0.00040),
      ];
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        monitoringController.add(
          TrackingPoint(
            latitude: point.$1,
            longitude: point.$2,
            accuracyMeters: 10,
            timestamp: start.add(Duration(seconds: i * 20)),
          ),
        );
      }
      await Future<void>.delayed(Duration.zero);

      expect(service.state, AutoDetectionState.monitoring);

      service.stateNotifier.value = AutoDetectionState.idle;
      unawaited(monitoringController.close());
    });

    test('does not start tracking for a short 200 meter reposition', () async {
      final monitoringController = StreamController<TrackingPoint>.broadcast();
      final start = DateTime(2026, 4, 27, 9);

      final service = AutoTripDetectionService(
        monitoringStreamFactory: () => monitoringController.stream,
        initialPositionProvider: () async => TrackingPoint(
          latitude: 0,
          longitude: 0,
          accuracyMeters: 10,
          timestamp: start,
        ),
      );

      await service.startMonitoring();
      monitoringController.add(
        TrackingPoint(
          latitude: 0,
          longitude: 0.0012,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(seconds: 30)),
        ),
      );
      monitoringController.add(
        TrackingPoint(
          latitude: 0,
          longitude: 0.0018,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(seconds: 60)),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.state, AutoDetectionState.monitoring);

      await service.stopMonitoring();
      unawaited(monitoringController.close());
    });

    test('returns to monitoring after three idle minutes', () async {
      final monitoringController = StreamController<TrackingPoint>.broadcast();
      final start = DateTime(2026, 4, 27, 9);

      final service = AutoTripDetectionService(
        monitoringStreamFactory: () => monitoringController.stream,
        initialPositionProvider: () async => TrackingPoint(
          latitude: 0,
          longitude: 0,
          accuracyMeters: 10,
          timestamp: start,
        ),
      );

      await service.startMonitoring();
      monitoringController.add(
        TrackingPoint(
          latitude: 0,
          longitude: 0.0023,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(seconds: 30)),
        ),
      );
      monitoringController.add(
        TrackingPoint(
          latitude: 0,
          longitude: 0.0030,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(seconds: 45)),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.state, AutoDetectionState.tracking);

      monitoringController.add(
        TrackingPoint(
          latitude: 0,
          longitude: 0.0030,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(seconds: 224)),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.state, AutoDetectionState.tracking);

      monitoringController.add(
        TrackingPoint(
          latitude: 0,
          longitude: 0.0030,
          accuracyMeters: 10,
          timestamp: start.add(const Duration(seconds: 225)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.state, AutoDetectionState.monitoring);

      await service.stopMonitoring();
      unawaited(monitoringController.close());
    });
  });
}
