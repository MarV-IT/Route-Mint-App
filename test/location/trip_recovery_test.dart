import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/location/tracking_result.dart';
import 'package:route_mint_app/core/location/trip_recovery_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrackingPoint point(double lat, double lon, {int second = 0}) => TrackingPoint(
  latitude: lat,
  longitude: lon,
  accuracyMeters: 8,
  timestamp: DateTime(2026, 8, 31, 15, 30).add(Duration(seconds: second)),
);

/// Points spaced roughly 90 m apart along a line.
List<TrackingPoint> line(int count, {double startLat = 43.6}) => [
  for (var i = 0; i < count; i++)
    point(startLat + i * 0.0008, -116.2, second: i * 5),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('carried distance', () {
    test('is added to the distance of the retained points', () {
      final points = line(20);
      final withoutCarry = TrackingResult.fromPoints(points)!;
      final withCarry = TrackingResult.fromPoints(
        points,
        carriedDistanceKm: 40,
      )!;

      expect(
        withCarry.distanceKm,
        closeTo(withoutCarry.distanceKm + 40, 0.0001),
      );
    });

    test('lets a trimmed trip clear the minimum it would otherwise miss', () {
      // Two points a few metres apart: far too short on their own, but the
      // trip already covered 30 km before the buffer was trimmed.
      final tail = [point(43.6, -116.2), point(43.60005, -116.2, second: 5)];

      expect(TrackingResult.fromPoints(tail, minimumDistanceKm: 0.5), isNull);
      expect(
        TrackingResult.fromPoints(
          tail,
          minimumDistanceKm: 0.5,
          carriedDistanceKm: 30,
        )?.distanceKm,
        closeTo(30, 0.01),
      );
    });

    test('startedAtOverride keeps the real start after trimming', () {
      final realStart = DateTime(2026, 8, 31, 15, 30);
      final result = TrackingResult.fromPoints(
        line(10),
        startedAtOverride: realStart,
      )!;

      expect(result.startedAt, realStart);
    });
  });

  group('TrackingPoint serialization', () {
    test('round-trips through JSON', () {
      final original = point(43.61234, -116.21234, second: 42);
      final restored = TrackingPoint.fromJson(original.toJson())!;

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.accuracyMeters, original.accuracyMeters);
      expect(restored.timestamp, original.timestamp);
    });

    test('returns null for malformed data instead of throwing', () {
      expect(TrackingPoint.fromJson(const {}), isNull);
      expect(
        TrackingPoint.fromJson(const {'latitude': 'x', 'longitude': 1}),
        isNull,
      );
    });
  });

  group('TripRecoveryStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('restores a checkpoint with its carried distance and start', () async {
      final store = TripRecoveryStore();
      final started = DateTime(2026, 8, 31, 15, 30);

      await store.saveCheckpoint(
        points: line(5),
        carriedDistanceKm: 52.5,
        startedAt: started,
        rawPointCount: 8000,
        droppedPointCount: 12,
      );

      final restored = (await store.loadCheckpoint())!;
      expect(restored.points, hasLength(5));
      expect(restored.carriedDistanceKm, 52.5);
      expect(restored.startedAt, started);
      expect(restored.rawPointCount, 8000);
      expect(restored.droppedPointCount, 12);
    });

    test('a recovered checkpoint can still become a saveable trip', () async {
      final store = TripRecoveryStore();
      await store.saveCheckpoint(
        points: line(20),
        carriedDistanceKm: 61,
        startedAt: DateTime(2026, 8, 31, 15, 30),
        rawPointCount: 20,
        droppedPointCount: 0,
      );

      final restored = (await store.loadCheckpoint())!;
      final result = TrackingResult.fromPoints(
        restored.points,
        minimumDistanceKm: 0.5,
        carriedDistanceKm: restored.carriedDistanceKm,
        startedAtOverride: restored.startedAt,
      );

      expect(result, isNotNull);
      expect(result!.distanceKm, greaterThan(61));
      expect(result.startedAt, DateTime(2026, 8, 31, 15, 30));
    });

    test('saves nothing when there are no points', () async {
      final store = TripRecoveryStore();
      await store.saveCheckpoint(
        points: const [],
        carriedDistanceKm: 0,
        startedAt: DateTime(2026, 8, 31),
        rawPointCount: 0,
        droppedPointCount: 0,
      );

      expect(await store.loadCheckpoint(), isNull);
    });

    test('clearCheckpoint removes it', () async {
      final store = TripRecoveryStore();
      await store.saveCheckpoint(
        points: line(3),
        carriedDistanceKm: 1,
        startedAt: DateTime(2026, 8, 31),
        rawPointCount: 3,
        droppedPointCount: 0,
      );
      await store.clearCheckpoint();

      expect(await store.loadCheckpoint(), isNull);
    });

    test('survives a corrupted payload', () async {
      SharedPreferences.setMockInitialValues({
        'auto_detection_active_trip': '{not json',
      });

      expect(await TripRecoveryStore().loadCheckpoint(), isNull);
    });

    test('remembers whether monitoring was running', () async {
      final store = TripRecoveryStore();
      expect(await store.wasMonitoring(), isFalse);

      await store.setMonitoring(true);
      expect(await store.wasMonitoring(), isTrue);

      await store.setMonitoring(false);
      expect(await store.wasMonitoring(), isFalse);
    });
  });
}
