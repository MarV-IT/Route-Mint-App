import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';

class TripService {
  static const String _tripsKey = 'trips';

  Future<List<Trip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_tripsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((item) => Trip.fromJson(item as Map<String, dynamic>))
        .toList();
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
}
