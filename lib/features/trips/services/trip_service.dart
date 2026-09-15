import 'dart:convert';
import '../../../core/preferences/preferences_service.dart';
import '../../../core/storage/account_data_store.dart';
import '../models/trip.dart';

class TripService {
  TripService({AccountDataScope? scope})
    : _scope = scope ?? AccountDataStore.current {
    _preferencesService = PreferencesService(scope: _scope);
  }

  final AccountDataScope _scope;
  static const String _tripsKey = 'trips';
  static final Map<String, Future<void>> _pendingMutations = {};
  late final PreferencesService _preferencesService;

  Future<List<Trip>> loadTrips() async {
    final prefs = await _scope.getPreferences();
    final jsonString = prefs.getString(_tripsKey);
    if (jsonString == null) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List<dynamic>) return [];

      final trips = <Trip>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;

        try {
          trips.add(Trip.fromJson(item));
        } catch (_) {
          // Skip malformed saved entries without discarding the valid trips.
        }
      }

      return trips;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTrips(List<Trip> trips) => _mutate(() => _saveTrips(trips));

  Future<void> _saveTrips(List<Trip> trips) async {
    final prefs = await _scope.getPreferences();
    final jsonString = jsonEncode(trips.map((t) => t.toJson()).toList());
    await prefs.setString(_tripsKey, jsonString);
  }

  Future<void> addTrip(Trip trip) => _mutate(() async {
    final trips = await loadTrips();
    final existing = _findById(trips, trip.id);

    trips.removeWhere((t) => t.id == trip.id);
    trips.add(trip);

    await _saveTrips(trips);
    await _adjustOdometerBy(trip.distance - (existing?.distance ?? 0));
  });

  Future<void> updateTrip(Trip updatedTrip) => _mutate(() async {
    final trips = await loadTrips();
    final index = trips.indexWhere((t) => t.id == updatedTrip.id);
    if (index != -1) {
      final previousDistance = trips[index].distance;
      trips[index] = updatedTrip;
      await _saveTrips(trips);
      await _adjustOdometerBy(updatedTrip.distance - previousDistance);
    }
  });

  Future<void> deleteTrip(String id) => _mutate(() async {
    final trips = await loadTrips();
    final existing = _findById(trips, id);
    trips.removeWhere((t) => t.id == id);
    await _saveTrips(trips);
    if (existing != null) {
      await _adjustOdometerBy(-existing.distance);
    }
  });

  // Manual Stop and logout can both finish the same trip. Serialize across
  // service instances for this owner so deduplication and odometer changes
  // observe the preceding save, without blocking other accounts.
  Future<void> _mutate(Future<void> Function() operation) {
    final previous =
        _pendingMutations[_scope.namespace] ?? Future<void>.value();
    final next = previous.then((_) => operation());
    final settled = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pendingMutations[_scope.namespace] = settled;
    settled.then((_) {
      if (identical(_pendingMutations[_scope.namespace], settled)) {
        _pendingMutations.remove(_scope.namespace);
      }
    });
    return next;
  }

  Future<void> _adjustOdometerBy(double distanceDeltaKm) async {
    if (distanceDeltaKm == 0) return;
    final prefs = await _preferencesService.loadPreferences();
    final odometer = prefs.vehicleOdometerKm;
    if (odometer == null) return;
    final updatedOdometer = odometer + distanceDeltaKm;
    await _preferencesService.savePreferences(
      prefs.copyWith(
        vehicleOdometerKm: updatedOdometer < 0 ? 0.0 : updatedOdometer,
      ),
    );
  }

  Trip? _findById(List<Trip> trips, String id) {
    for (final trip in trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }
}
