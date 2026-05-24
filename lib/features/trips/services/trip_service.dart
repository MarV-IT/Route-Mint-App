import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/preferences/preferences_service.dart';
import '../models/trip.dart';

class TripService {
  static const String _tripsKey = 'trips';
  final _preferencesService = PreferencesService();

  Future<List<Trip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> saveTrips(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(trips.map((t) => t.toJson()).toList());
    await prefs.setString(_tripsKey, jsonString);
  }

  Future<void> addTrip(Trip trip) async {
    final trips = await loadTrips();
    final existing = _findById(trips, trip.id);

    trips.removeWhere((t) => t.id == trip.id);
    trips.add(trip);

    await saveTrips(trips);
    await _adjustOdometerBy(trip.distance - (existing?.distance ?? 0));
  }

  Future<void> updateTrip(Trip updatedTrip) async {
    final trips = await loadTrips();
    final index = trips.indexWhere((t) => t.id == updatedTrip.id);
    if (index != -1) {
      final previousDistance = trips[index].distance;
      trips[index] = updatedTrip;
      await saveTrips(trips);
      await _adjustOdometerBy(updatedTrip.distance - previousDistance);
    }
  }

  Future<void> deleteTrip(String id) async {
    final trips = await loadTrips();
    final existing = _findById(trips, id);
    trips.removeWhere((t) => t.id == id);
    await saveTrips(trips);
    if (existing != null) {
      await _adjustOdometerBy(-existing.distance);
    }
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
