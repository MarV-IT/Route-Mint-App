import 'dart:math';
import 'package:geocoding/geocoding.dart';
import 'reverse_geocoding_service.dart';

class AddressSuggestion {
  const AddressSuggestion({
    required this.title,
    this.subtitle,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });

  final String title;
  final String? subtitle;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
}

abstract class AddressSearchService {
  Future<List<AddressSuggestion>> search(
    String query, {
    double? userLatitude,
    double? userLongitude,
  });
}

class GeocodingAddressSearchService implements AddressSearchService {
  GeocodingAddressSearchService() : _reverse = ReverseGeocodingService();

  final ReverseGeocodingService _reverse;

  @override
  Future<List<AddressSuggestion>> search(
    String query, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return [];

      final candidates = locations.take(5).toList();

      // Reverse geocode all candidates concurrently.
      final formatted = await Future.wait(
        candidates.map((loc) => _reverse.reverseGeocode(loc.latitude, loc.longitude)),
      );

      final suggestions = <AddressSuggestion>[];
      for (var i = 0; i < candidates.length; i++) {
        final loc = candidates[i];
        final title = formatted[i] ?? query;
        suggestions.add(AddressSuggestion(
          title: title,
          subtitle: (formatted[i] != null && formatted[i] != query) ? query : null,
          fullAddress: title,
          latitude: loc.latitude,
          longitude: loc.longitude,
        ));
      }

      if (userLatitude != null && userLongitude != null) {
        suggestions.sort((a, b) {
          final da = (a.latitude != null && a.longitude != null)
              ? _distanceKm(userLatitude, userLongitude, a.latitude!, a.longitude!)
              : double.maxFinite;
          final db = (b.latitude != null && b.longitude != null)
              ? _distanceKm(userLatitude, userLongitude, b.latitude!, b.longitude!)
              : double.maxFinite;
          return da.compareTo(db);
        });
      }

      return suggestions;
    } catch (_) {
      return [];
    }
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}
