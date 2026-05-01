import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/location/geolocator_tracking_provider.dart';
import '../../core/location/location_permission_service.dart';
import '../../core/location/reverse_geocoding_service.dart';
import '../../core/location/tracking_result.dart';
import '../../core/preferences/user_preferences.dart';
import '../../features/trips/models/trip.dart';
import '../../features/trips/services/trip_service.dart';

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
  final _geocodingService = ReverseGeocodingService();

  // _isTracking is derived from appTrackingService.isTrackingNotifier —
  // no local copy needed, reducing the surface for state drift.
  bool _isBusy = false;
  bool _isResolvingAddresses = false;
  String? _errorMessage;

  Future<void> _handleStart() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final status = await _permissionService.checkAndRequest();
      if (!mounted) return;
      switch (status) {
        case LocationPermissionStatus.granted:
          appTrackingService.startTracking();
        case LocationPermissionStatus.denied:
        case LocationPermissionStatus.permanentlyDenied:
          setState(() => _errorMessage = widget.strings.locationPermissionRequired);
        case LocationPermissionStatus.serviceDisabled:
          setState(() => _errorMessage = widget.strings.locationServicesDisabled);
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = widget.strings.trackingError);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleStop() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      // isTrackingNotifier.value = false fires synchronously inside stopTracking(),
      // before the subscription cancel await. The card rebuilds showing
      // "Resolving…" (via _isBusy) rather than flashing "Not tracking".
      final result = await appTrackingService.stopTracking();

      if (!mounted) {
        // Widget unmounted during stop — still persist the trip if valid.
        if (result != null) {
          final start = result.points.first;
          final end = result.points.last;
          final addresses = await Future.wait([
            _geocodingService.reverseGeocode(start.latitude, start.longitude),
            _geocodingService.reverseGeocode(end.latitude, end.longitude),
          ]);
          await _tripService.addTrip(_buildTrip(
            result: result,
            from: addresses[0],
            to: addresses[1],
            fallbackStart: widget.strings.detectedStart,
            fallbackEnd: widget.strings.detectedEnd,
          ));
        }
        return;
      }

      if (result == null) {
        setState(() {
          _isBusy = false;
          _errorMessage = widget.strings.notEnoughMovementDetected;
        });
        return;
      }

      setState(() => _isResolvingAddresses = true);

      final start = result.points.first;
      final end = result.points.last;

      final addresses = await Future.wait([
        _geocodingService.reverseGeocode(start.latitude, start.longitude),
        _geocodingService.reverseGeocode(end.latitude, end.longitude),
      ]);

      if (!mounted) return;

      setState(() {
        _isBusy = false;
        _isResolvingAddresses = false;
      });

      await _tripService.addTrip(_buildTrip(
        result: result,
        from: addresses[0],
        to: addresses[1],
        fallbackStart: widget.strings.detectedStart,
        fallbackEnd: widget.strings.detectedEnd,
      ));

      if (!mounted) return;
      widget.onTripSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.detectedTripSavedForReview)),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isResolvingAddresses = false;
          _errorMessage = widget.strings.trackingError;
        });
      }
    }
  }

  Trip _buildTrip({
    required TrackingResult result,
    required String? from,
    required String? to,
    required String fallbackStart,
    required String fallbackEnd,
  }) {
    final start = result.points.first;
    final end = result.points.last;
    return Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      from: from ?? fallbackStart,
      to: to ?? fallbackEnd,
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
      routePoints: result.points
          .map((p) => TripRoutePoint(
                latitude: p.latitude,
                longitude: p.longitude,
                timestamp: p.timestamp,
              ))
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final autoEnabled = widget.preferences.autoTripDetectionEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: appTrackingService.isTrackingNotifier,
      builder: (context, isTracking, _) {
        final (statusText, statusColor) = switch (true) {
          _ when !autoEnabled => (
              strings.enableAutoDetectionFirst,
              colorScheme.onSurfaceVariant,
            ),
          _ when isTracking => (
              strings.trackingContinuesScreenOff,
              colorScheme.primary,
            ),
          _ when _isResolvingAddresses || _isBusy => (
              strings.resolvingAddresses,
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
                      isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                      size: 20,
                      color: isTracking ? colorScheme.primary : null,
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
                  if (isTracking)
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _handleStop,
                      icon: const Icon(Icons.stop),
                      label: Text(strings.stopTracking),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _handleStart,
                      icon: const Icon(Icons.gps_fixed),
                      label: Text(strings.startTracking),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
