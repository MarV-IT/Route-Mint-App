import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fuel_entry.dart';

class FuelService {
  static const String _fuelEntriesKey = 'fuel_entries';

  Future<List<FuelEntry>> loadFuelEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_fuelEntriesKey);
    if (jsonString == null) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List<dynamic>) return [];

      final entries = <FuelEntry>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          entries.add(FuelEntry.fromJson(item));
        } catch (_) {
          // Skip malformed saved entries without discarding valid entries.
        }
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFuelEntries(List<FuelEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_fuelEntriesKey, jsonString);
  }

  Future<void> addFuelEntry(FuelEntry entry) async {
    final entries = await loadFuelEntries();
    entries.removeWhere((e) => e.id == entry.id);
    entries.add(entry);
    await saveFuelEntries(entries);
  }

  Future<void> updateFuelEntry(FuelEntry entry) async {
    final entries = await loadFuelEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
    await saveFuelEntries(entries);
  }

  Future<void> deleteFuelEntry(String id) async {
    final entries = await loadFuelEntries();
    entries.removeWhere((e) => e.id == id);
    await saveFuelEntries(entries);
  }
}
