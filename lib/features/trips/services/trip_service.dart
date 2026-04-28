import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';

class TripService {
  static const String _tripsKey = 'trips';

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

    trips.removeWhere((t) => t.id == trip.id);
    trips.add(trip);

    await saveTrips(trips);
  }

  Future<void> updateTrip(Trip updatedTrip) async {
    final trips = await loadTrips();
    final index = trips.indexWhere((t) => t.id == updatedTrip.id);
    if (index != -1) {
      trips[index] = updatedTrip;
      await saveTrips(trips);
    }
  }

  Future<void> deleteTrip(String id) async {
    final trips = await loadTrips();
    trips.removeWhere((t) => t.id == id);
    await saveTrips(trips);
  }
}
