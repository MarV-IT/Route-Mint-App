import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../features/trips/models/trip.dart';

class TripMapPreview extends StatelessWidget {
  const TripMapPreview({
    super.key,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    this.routePoints = const [],
  });

  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final List<TripRoutePoint> routePoints;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = _safeLatLng(startLatitude, startLongitude);
    final end = _safeLatLng(endLatitude, endLongitude);
    final anchorPoints = <LatLng>[
      if (start != null) start, // ignore: use_null_aware_elements
      if (end != null) end, // ignore: use_null_aware_elements
    ];

    if (anchorPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build valid route polyline from stored GPS points (if available).
    final validRoute = routePoints
        .map((p) => _safeLatLng(p.latitude, p.longitude))
        .nonNulls
        .toList(growable: false);
    final useTrackedRoute = validRoute.length >= 2;

    final polylinePoints =
        useTrackedRoute ? validRoute : (anchorPoints.length >= 2 ? anchorPoints : <LatLng>[]);
    final fitCoords = useTrackedRoute ? validRoute : anchorPoints;

    final hasPolyline = polylinePoints.length >= 2 &&
        !_samePoint(polylinePoints.first, polylinePoints.last);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: fitCoords.first,
            initialZoom: 15,
            initialCameraFit: fitCoords.length >= 2
                ? CameraFit.coordinates(
                    coordinates: fitCoords,
                    padding: const EdgeInsets.all(48),
                    maxZoom: 15,
                  )
                : null,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.routemint',
            ),
            PolylineLayer(
              polylines: [
                if (hasPolyline)
                  Polyline(
                    points: polylinePoints,
                    color: cs.primary,
                    strokeWidth: 3,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                if (start != null)
                  Marker(
                    point: start,
                    width: 18,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                if (end != null)
                  Marker(
                    point: end,
                    width: 30,
                    height: 30,
                    alignment: Alignment.bottomCenter,
                    child: Icon(Icons.location_on, color: cs.error, size: 30),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static LatLng? _safeLatLng(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return null;
    }
    if (!latitude.isFinite || !longitude.isFinite) {
      return null;
    }
    if (latitude < -90 || latitude > 90) {
      return null;
    }
    if (longitude < -180 || longitude > 180) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  static bool _samePoint(LatLng start, LatLng end) =>
      start.latitude == end.latitude && start.longitude == end.longitude;
}
