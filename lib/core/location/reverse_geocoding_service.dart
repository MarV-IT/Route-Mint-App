import 'package:geocoding/geocoding.dart';

class ReverseGeocodingService {
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      return _formatAddress(placemarks.first);
    } catch (_) {
      return null;
    }
  }

  String? _formatAddress(Placemark p) {
    final parts = <String>[];

    final street = p.street?.trim();
    if (street != null && street.isNotEmpty) {
      parts.add(street);
    } else {
      final name = p.name?.trim();
      if (name != null && name.isNotEmpty) parts.add(name);
    }

    final city = (p.locality?.trim().isNotEmpty == true)
        ? p.locality!.trim()
        : p.subLocality?.trim();
    if (city != null && city.isNotEmpty) parts.add(city);

    final state = p.administrativeArea?.trim();
    if (state != null && state.isNotEmpty) parts.add(state);

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}
