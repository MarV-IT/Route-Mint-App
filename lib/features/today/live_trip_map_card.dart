import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/localization/app_strings.dart';
import '../../core/location/geolocator_tracking_provider.dart';
import '../../core/location/tracking_result.dart';

class LiveTripMapCard extends StatelessWidget {
  const LiveTripMapCard({
    super.key,
    required this.strings,
    this.bottomSpacing = 0,
  });

  final AppStrings strings;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TrackingPoint>>(
      valueListenable: appTrackingService.activeRouteNotifier,
      builder: (context, foregroundPoints, _) {
        return ValueListenableBuilder<List<TrackingPoint>>(
          valueListenable: appAutoDetectionService.activeRouteNotifier,
          builder: (context, autoPoints, _) {
            final points = autoPoints.isNotEmpty
                ? autoPoints
                : foregroundPoints;
            final route = points
                .map((p) => _safeLatLng(p.latitude, p.longitude))
                .nonNulls
                .toList(growable: false);

            if (route.isEmpty) return const SizedBox.shrink();

            final content = _LiveTripMapContent(strings: strings, route: route);
            if (bottomSpacing <= 0) return content;
            return Column(
              children: [
                content,
                SizedBox(height: bottomSpacing),
              ],
            );
          },
        );
      },
    );
  }

  static LatLng? _safeLatLng(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;
    return LatLng(latitude, longitude);
  }
}

class _LiveTripMapContent extends StatelessWidget {
  const _LiveTripMapContent({required this.strings, required this.route});

  final AppStrings strings;
  final List<LatLng> route;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = route.last;
    final hasPolyline =
        route.length >= 2 && !_samePoint(route.first, route.last);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.map_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  strings.liveTripMap,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: FlutterMap(
              key: ValueKey(
                '${current.latitude.toStringAsFixed(5)},${current.longitude.toStringAsFixed(5)},${route.length}',
              ),
              options: MapOptions(
                initialCenter: current,
                initialZoom: 16,
                initialCameraFit: route.length >= 2
                    ? CameraFit.coordinates(
                        coordinates: route,
                        padding: const EdgeInsets.all(48),
                        maxZoom: 16,
                      )
                    : null,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
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
                        points: route,
                        color: cs.primary,
                        strokeWidth: 4,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: current,
                      width: 34,
                      height: 34,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.navigation,
                          size: 18,
                          color: cs.onPrimary,
                        ),
                      ),
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
        ],
      ),
    );
  }

  static bool _samePoint(LatLng start, LatLng end) =>
      start.latitude == end.latitude && start.longitude == end.longitude;
}
