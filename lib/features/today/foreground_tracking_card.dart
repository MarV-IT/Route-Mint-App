import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/location/geolocator_tracking_provider.dart';
import '../../core/location/location_permission_service.dart';
import '../../core/preferences/user_preferences.dart';
import '../../features/trips/models/trip.dart';
import '../../features/trips/services/trip_service.dart';

// Minimum total displacement in meters for a trip to be saved.
const double _minTripMeters = 20;

class ForegroundTrackingCard extends StatefulWidget {
  const ForegroundTrackingCard({
    super.key,
    required this.strings,
    required this.preferences,
    required this.onTripSaved,
  });

  final AppStrings strings;
  final UserPreferences preferences;
  final VoidCallback onTripSaved;

  @override
  State<ForegroundTrackingCard> createState() => _ForegroundTrackingCardState();
}

class _ForegroundTrackingCardState extends State<ForegroundTrackingCard> {
  final _permissionService = LocationPermissionService();
  final _tripService = TripService();

  bool _isTracking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isTracking = appTrackingService.isTracking;
  }

  Future<void> _handleStart() async {
    final status = await _permissionService.checkAndRequest();

    switch (status) {
      case LocationPermissionStatus.granted:
        appTrackingService.startTracking();
        if (mounted) {
          setState(() {
            _isTracking = true;
            _errorMessage = null;
          });
        }
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.permanentlyDenied:
        if (mounted) {
          setState(
            () => _errorMessage = widget.strings.locationPermissionRequired,
          );
        }
      case LocationPermissionStatus.serviceDisabled:
        if (mounted) {
          setState(
            () => _errorMessage = widget.strings.locationServicesDisabled,
          );
        }
    }
  }

  Future<void> _handleStop() async {
    final result = await appTrackingService.stopTracking();

    if (!mounted) return;

    setState(() => _isTracking = false);

    if (result == null || result.distanceKm * 1000 < _minTripMeters) {
      setState(
        () => _errorMessage = widget.strings.notEnoughMovementDetected,
      );
      return;
    }

    setState(() => _errorMessage = null);

    final start = result.points.first;
    final end = result.points.last;

    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      from: widget.strings.detectedStart,
      to: widget.strings.detectedEnd,
      distance: result.distanceKm,
      category: 'personal',
      date: result.startedAt,
      detectionMode: TripDetectionMode.automatic,
      reviewStatus: TripReviewStatus.needsReview,
      startTime: result.startedAt,
      endTime: result.endedAt,
      startLatitude: start.latitude,
      startLongitude: start.longitude,
      endLatitude: end.latitude,
      endLongitude: end.longitude,
    );

    await _tripService.addTrip(trip);

    if (!mounted) return;

    widget.onTripSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.strings.detectedTripSavedForReview)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final autoEnabled = widget.preferences.autoTripDetectionEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    final (statusText, statusColor) = switch (true) {
      _ when !autoEnabled => (
          strings.enableAutoDetectionFirst,
          colorScheme.onSurfaceVariant,
        ),
      _ when _isTracking => (
          strings.trackingKeepAppOpen,
          colorScheme.primary,
        ),
      _ when _errorMessage != null => (
          _errorMessage!,
          colorScheme.error,
        ),
      _ => (strings.notTracking, colorScheme.onSurfaceVariant),
    };

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                  size: 20,
                  color: _isTracking ? colorScheme.primary : null,
                ),
                const SizedBox(width: 8),
                Text(
                  strings.foregroundTracking,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                  ),
            ),
            if (autoEnabled) ...[
              const SizedBox(height: 12),
              if (_isTracking)
                FilledButton.icon(
                  onPressed: _handleStop,
                  icon: const Icon(Icons.stop),
                  label: Text(strings.stopTracking),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _handleStart,
                  icon: const Icon(Icons.gps_fixed),
                  label: Text(strings.startTracking),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
