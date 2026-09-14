import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/location/auto_trip_detection_service.dart';
import 'package:route_mint_app/core/location/tracking_result.dart';
import 'package:route_mint_app/core/location/trip_recovery_store.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/services/trip_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingTrips extends TripService {
  @override
  Future<void> addTrip(Trip trip) async =>
      throw StateError('Storage unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final start = DateTime(2026, 9, 13, 12);
  final points = List.generate(
    12,
    (index) => TrackingPoint(
      latitude: 40 + index * 0.001,
      longitude: -105,
      accuracyMeters: 8,
      timestamp: start.add(Duration(seconds: index * 10)),
    ),
  );

  Future<void> checkpoint(TripRecoveryStore store, DateTime startedAt) =>
      store.saveCheckpoint(
        points: points,
        carriedDistanceKm: 0,
        startedAt: startedAt,
        rawPointCount: points.length,
        droppedPointCount: 0,
      );

  test('failed recovery leaves the checkpoint for the next attempt', () async {
    final store = TripRecoveryStore();
    await checkpoint(store, start);
    final service = AutoTripDetectionService(
      monitoringStreamFactory: () => const Stream.empty(),
      tripService: _FailingTrips(),
    );
    await expectLater(service.recoverInterruptedTrip(), throwsStateError);
    expect((await store.loadCheckpoint())?.startedAt, start);
  });

  test('recovering the same checkpoint twice creates one trip', () async {
    final store = TripRecoveryStore();
    final service = AutoTripDetectionService(
      monitoringStreamFactory: () => const Stream.empty(),
    );
    await checkpoint(store, start);
    expect(await service.recoverInterruptedTrip(), isTrue);
    expect(await store.loadCheckpoint(), isNull);
    // Simulate process termination after writing the trip but before cleanup.
    await checkpoint(store, start);
    expect(await service.recoverInterruptedTrip(), isTrue);
    final trips = await TripService().loadTrips();
    expect(trips, hasLength(1));
    expect(trips.single.distance, greaterThan(1));
  });

  test('old trip cleanup cannot remove a newer checkpoint', () async {
    final store = TripRecoveryStore();
    final next = start.add(const Duration(hours: 1));
    await checkpoint(store, start);
    final writing = checkpoint(store, next);
    final clearing = store.clearCheckpoint(startedAt: start);
    await Future.wait([writing, clearing]);
    expect((await store.loadCheckpoint())?.startedAt, next);
  });
}
