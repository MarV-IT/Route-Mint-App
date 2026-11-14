import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/services/trip_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'review_fakes.dart';

Trip trip(String id) => Trip(
  id: id,
  from: 'A',
  to: 'B',
  distance: 5,
  category: 'business',
  date: DateTime(2026, 11, 12),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'only new successful saves count; restore, edit, delete and retry do not',
    () async {
      final h = ReviewHarness();
      await h.start();
      await AccountDataStore.activate('A');
      final service = TripService(reviewService: h.service);
      await service.saveTrips([trip('imported')]);
      await service.addTrip(trip('imported'));
      expect(h.service.state.completedTrips, 0);
      await Future.wait([
        service.addTrip(trip('new')),
        service.addTrip(trip('new')),
      ]);
      expect(h.service.state.completedTrips, 1);
      await service.updateTrip(trip('new'));
      await service.deleteTrip('new');
      expect(h.service.state.completedTrips, 1);
      await service.addTrip(trip('new'));
      expect(h.service.state.completedTrips, 1);
      await service.saveTrips([]);
      expect(h.service.state.completedTrips, 1);
    },
  );

  test(
    'account switching keeps installation counters without moving trips',
    () async {
      final h = ReviewHarness();
      await h.start();
      await AccountDataStore.activate('A');
      final a = TripService(reviewService: h.service);
      await a.addTrip(trip('same'));
      await AccountDataStore.activate('B');
      final b = TripService(reviewService: h.service);
      expect(await b.loadTrips(), isEmpty);
      await b.addTrip(trip('same'));
      await AccountDataStore.activate('A');
      expect((await a.loadTrips()).single.id, 'same');
      expect(h.service.state.completedTrips, 2);
    },
  );

  test(
    'rating storage failure never changes successful trip-save outcome',
    () async {
      final h = ReviewHarness();
      await h.start();
      await AccountDataStore.activate('A');
      h.store.failWrite = true;
      final service = TripService(reviewService: h.service);
      await service.addTrip(trip('saved'));
      expect((await service.loadTrips()).single.id, 'saved');
      expect(h.service.state.completedTrips, 0);
      expect(h.service.eligible, false);
    },
  );
}
