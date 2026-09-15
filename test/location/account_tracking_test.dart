import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/location/auto_trip_detection_service.dart';
import 'package:route_mint_app/core/location/foreground_trip_tracking_service.dart';
import 'package:route_mint_app/core/location/geolocator_tracking_provider.dart';
import 'package:route_mint_app/core/location/tracking_result.dart';
import 'package:route_mint_app/core/location/trip_recovery_store.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/services/trip_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedTrips extends TripService {
  _DelayedTrips({required super.scope});

  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> addTrip(Trip trip) async {
    entered.complete();
    await release.future;
    await super.addTrip(trip);
  }
}

final _start = DateTime(2026, 9, 15, 12);

TrackingPoint _point(int second) => TrackingPoint(
  latitude: 40 + second * 0.0001,
  longitude: -105,
  accuracyMeters: 8,
  timestamp: _start.add(Duration(seconds: second)),
);

Future<void> _checkpoint(TripRecoveryStore store) => store.saveCheckpoint(
  points: [_point(0), _point(40), _point(80)],
  carriedDistanceKm: 0,
  startedAt: _start,
  rawPointCount: 3,
  droppedPointCount: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AccountDataStore.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'checkpoints and monitoring flags stay with their original owner',
    () async {
      await AccountDataStore.activate('account-a');
      final oldStore = TripRecoveryStore();
      await _checkpoint(oldStore);
      await oldStore.setMonitoring(true);

      await AccountDataStore.activate('account-b');
      final newStore = TripRecoveryStore();
      expect(await newStore.loadCheckpoint(), isNull);
      expect(await newStore.wasMonitoring(), isFalse);

      await _checkpoint(newStore);
      await newStore.setMonitoring(true);
      await oldStore.clearCheckpoint();
      await oldStore.setMonitoring(false);
      expect(await newStore.loadCheckpoint(), isNotNull);
      expect(await newStore.wasMonitoring(), isTrue);

      await AccountDataStore.activate('account-a');
      expect(await TripRecoveryStore().loadCheckpoint(), isNull);
      expect(await TripRecoveryStore().wasMonitoring(), isFalse);
    },
  );

  test(
    'late recovery saves only to A and never calls B refresh callback',
    () async {
      await AccountDataStore.activate('account-a');
      final owner = AccountDataStore.current;
      final oldStore = TripRecoveryStore();
      await _checkpoint(oldStore);
      final trips = _DelayedTrips(scope: owner);
      final service = AutoTripDetectionService(
        monitoringStreamFactory: () => const Stream.empty(),
        tripService: trips,
      );
      var refreshCount = 0;
      service.onTripSaved = () => refreshCount++;

      final recovering = service.recoverInterruptedTrip();
      await trips.entered.future;
      await AccountDataStore.activate('account-b');
      trips.release.complete();
      expect(await recovering, isTrue);

      expect(await TripService().loadTrips(), isEmpty);
      expect(await TripService(scope: owner).loadTrips(), hasLength(1));
      expect(await oldStore.loadCheckpoint(), isNull);
      expect(refreshCount, 0);
    },
  );

  test(
    'switch waits for automatic save and blocks starts until activated',
    () async {
      await AccountDataStore.activate('account-a');
      final owner = AccountDataStore.current;
      final trips = _DelayedTrips(scope: owner);
      final stream = StreamController<TrackingPoint>();
      final service = AutoTripDetectionService(
        monitoringStreamFactory: () => stream.stream,
        tripService: trips,
      );
      await service.startMonitoring();
      for (final second in [0, 40, 80]) {
        stream.add(_point(second));
      }
      await Future<void>.delayed(Duration.zero);
      expect(service.isTripActive, isTrue);

      var prepared = false;
      final preparing = service.prepareForAccountChange().then((_) {
        prepared = true;
      });
      await trips.entered.future;
      await service.startMonitoring();
      expect(prepared, isFalse);
      expect(service.state, AutoDetectionState.idle);
      trips.release.complete();
      await preparing;
      expect(service.activeRouteNotifier.value, isEmpty);

      await AccountDataStore.activate('account-b');
      expect(await TripService().loadTrips(), isEmpty);
      expect(await TripService(scope: owner).loadTrips(), hasLength(1));
      service.completeAccountChange();
      await stream.close();
    },
  );

  test(
    'logout saves manual pending trip to A and clears it before B starts',
    () async {
      await AccountDataStore.activate('account-a');
      final owner = AccountDataStore.current;
      final first = StreamController<TrackingPoint>();
      final second = StreamController<TrackingPoint>();
      var streams = 0;
      final manual = ForegroundTripTrackingService(
        pointStreamFactory: () => streams++ == 0 ? first.stream : second.stream,
      );
      final automatic = AutoTripDetectionService(
        monitoringStreamFactory: () => const Stream.empty(),
      );
      await manual.startTracking();
      first.add(_point(0));
      first.add(_point(80));
      await Future<void>.delayed(Duration.zero);

      await prepareTrackingForAccountChange(
        trackingService: manual,
        autoDetectionService: automatic,
      );
      expect(manual.isTrackingNotifier.value, isFalse);
      expect(manual.hasPendingTripNotifier.value, isFalse);
      expect(manual.activeRouteNotifier.value, isEmpty);
      expect(await manual.startTracking(), isFalse);
      final oldTrips = await TripService(scope: owner).loadTrips();
      expect(oldTrips, hasLength(1));
      expect(oldTrips.single.reviewStatus, TripReviewStatus.needsReview);
      expect(oldTrips.single.routePoints, hasLength(2));

      await AccountDataStore.activate('account-b');
      expect(await TripService().loadTrips(), isEmpty);
      completeTrackingAccountChange(
        trackingService: manual,
        autoDetectionService: automatic,
      );
      expect(await manual.startTracking(), isTrue);
      first.add(_point(100));
      second.add(_point(200));
      await Future<void>.delayed(Duration.zero);
      expect(manual.activeRouteNotifier.value, hasLength(1));
      expect(
        manual.activeRouteNotifier.value.single.timestamp,
        _point(200).timestamp,
      );
      await manual.stopTracking();
      await first.close();
      await second.close();
    },
  );

  test(
    'manual switch retries retain the route until its save is acknowledged',
    () async {
      await AccountDataStore.activate('account-a');
      final stream = StreamController<TrackingPoint>();
      final manual = ForegroundTripTrackingService(
        pointStreamFactory: () => stream.stream,
      );
      await manual.startTracking();
      stream.add(_point(0));
      stream.add(_point(80));
      await Future<void>.delayed(Duration.zero);

      final (firstResult, _) = await manual.prepareForAccountChange();
      expect(firstResult, isNotNull);
      manual.completeAccountChange();
      expect(await manual.startTracking(), isFalse);

      final (retryResult, _) = await manual.prepareForAccountChange();
      expect(retryResult, same(firstResult));
      expect(manual.ownerScope?.uid, 'account-a');
      manual.acknowledgeAccountChangeTrip(retryResult!);
      final (afterSave, _) = await manual.prepareForAccountChange();
      expect(afterSave, isNull);
      manual.completeAccountChange();
      await stream.close();
    },
  );

  test(
    'initial GPS fix resolving after switch cannot populate B route',
    () async {
      await AccountDataStore.activate('account-a');
      final initial = Completer<TrackingPoint?>();
      final first = StreamController<TrackingPoint>();
      final second = StreamController<TrackingPoint>();
      var streams = 0;
      var initialCalls = 0;
      final service = ForegroundTripTrackingService(
        pointStreamFactory: () => streams++ == 0 ? first.stream : second.stream,
        initialPositionProvider: () => initialCalls++ == 0
            ? initial.future
            : Future<TrackingPoint?>.value(),
        stopPositionProvider: () async => null,
      );
      final oldStart = service.startTracking();
      await service.prepareForAccountChange();
      await AccountDataStore.activate('account-b');
      service.completeAccountChange();
      expect(await service.startTracking(), isTrue);
      initial.complete(_point(0));
      expect(await oldStart, isFalse);
      expect(service.activeRouteNotifier.value, isEmpty);
      expect(service.ownerScope?.uid, 'account-b');
      await service.stopTracking();
      await first.close();
      await second.close();
    },
  );
}
