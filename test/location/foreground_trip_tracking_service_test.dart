import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
      service.startTracking();

      expect(service.isTracking, true);

      final result = await service.stopTracking();

      expect(result, isNull);
      expect(service.isTracking, false);
      expect(cancelled, true);
    });
  });
}
