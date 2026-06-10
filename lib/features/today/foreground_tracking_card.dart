import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/location/auto_trip_detection_service.dart';
import '../../core/location/geolocator_tracking_provider.dart';
import '../../core/location/location_permission_service.dart';
import '../../core/location/reverse_geocoding_service.dart';
import '../../core/location/tracking_result.dart';
import '../../core/notifications/trip_notification_service.dart';
import '../../core/preferences/user_preferences.dart';
import '../../features/trips/models/trip.dart';
import '../../features/trips/services/trip_service.dart';
import '../../features/work_mode/services/work_mode_service.dart';

class ForegroundTrackingCard extends StatefulWidget {
  const ForegroundTrackingCard({
    super.key,
    required this.strings,
    required this.preferences,
    required this.onTripSaved,
    this.compact = false,
  });

  final AppStrings strings;
  final UserPreferences preferences;
  final VoidCallback onTripSaved;
  final bool compact;

  @override
  State<ForegroundTrackingCard> createState() => _ForegroundTrackingCardState();
}

class _ForegroundTrackingCardState extends State<ForegroundTrackingCard> {
  final _permissionService = LocationPermissionService();
  final _tripService = TripService();
  final _geocodingService = ReverseGeocodingService();
  final _workModeService = WorkModeService();

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
          await TripNotificationService.instance.requestPermission();
          final started = await appTrackingService.startTracking();
          if (mounted && !started) {
            setState(() => _errorMessage = widget.strings.trackingError);
          }
        case LocationPermissionStatus.denied:
        case LocationPermissionStatus.permanentlyDenied:
          setState(
            () => _errorMessage = widget.strings.locationPermissionRequired,
          );
        case LocationPermissionStatus.serviceDisabled:
          setState(
            () => _errorMessage = widget.strings.locationServicesDisabled,
          );
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
      final (result, reason) = await appTrackingService.stopTracking();

      if (!mounted) {
        // Widget unmounted during stop — still persist the trip if valid.
        if (result != null) {
          final start = result.points.first;
          final end = result.points.last;
          final addresses = await Future.wait([
            _reverseGeocodeSafely(start.latitude, start.longitude),
            _reverseGeocodeSafely(end.latitude, end.longitude),
          ]);
          final workSettings = await _workModeService.loadSettings();
          await _tripService.addTrip(
            _buildTrip(
              result: result,
              from: addresses[0],
              to: addresses[1],
              fallbackStart: widget.strings.detectedStart,
              fallbackEnd: widget.strings.detectedEnd,
              platformName: _workModeService
                  .matchingShiftAt(workSettings, result.startedAt)
                  ?.platformName,
            ),
          );
          await TripNotificationService.instance.showTripSavedForReview(
            distanceKm: result.distanceKm,
          );
        }
        return;
      }

      if (result == null) {
        final msg = switch (reason) {
          TrackingFailureReason.noAccuratePoints =>
            widget.strings.noGpsPointsRecorded,
          TrackingFailureReason.tooFewPoints =>
            widget.strings.notEnoughMovementDetected,
          TrackingFailureReason.distanceTooShort =>
            widget.strings.notEnoughMovementDetected,
          null => widget.strings.notEnoughMovementDetected,
        };
        setState(() {
          _isBusy = false;
          _errorMessage = msg;
        });
        return;
      }

      setState(() => _isResolvingAddresses = true);

      final start = result.points.first;
      final end = result.points.last;

      final addresses = await Future.wait([
        _reverseGeocodeSafely(start.latitude, start.longitude),
        _reverseGeocodeSafely(end.latitude, end.longitude),
      ]);
      final workSettings = await _workModeService.loadSettings();
      final platformName = _workModeService
          .matchingShiftAt(workSettings, result.startedAt)
          ?.platformName;

      // Save before checking mounted so the trip is never dropped if the
      // user navigates away while geocoding is in progress.
      await _tripService.addTrip(
        _buildTrip(
          result: result,
          from: addresses[0],
          to: addresses[1],
          fallbackStart: widget.strings.detectedStart,
          fallbackEnd: widget.strings.detectedEnd,
          platformName: platformName,
        ),
      );
      await TripNotificationService.instance.showTripSavedForReview(
        distanceKm: result.distanceKm,
      );
      if (kDebugMode) {
        debugPrint(
          '[ForegroundTracking] trip saved — dist=${result.distanceKm.toStringAsFixed(3)} km, from=${addresses[0]}, to=${addresses[1]}',
        );
      }

      if (!mounted) return;

      setState(() {
        _isBusy = false;
        _isResolvingAddresses = false;
      });
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
    required String? platformName,
  }) {
    final start = result.points.first;
    final end = result.points.last;
    return Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      from: from ?? fallbackStart,
      to: to ?? fallbackEnd,
      distance: result.distanceKm,
      category: platformName == null ? 'personal' : 'business',
      date: result.startedAt.toLocal(),
      platformName: platformName,
      detectionMode: TripDetectionMode.automatic,
      reviewStatus: TripReviewStatus.needsReview,
      startTime: result.startedAt.toLocal(),
      endTime: result.endedAt.toLocal(),
      startLatitude: start.latitude,
      startLongitude: start.longitude,
      endLatitude: end.latitude,
      endLongitude: end.longitude,
      routePoints: result.points
          .map(
            (p) => TripRoutePoint(
              latitude: p.latitude,
              longitude: p.longitude,
              timestamp: p.timestamp.toLocal(),
            ),
          )
          .toList(growable: false),
      trackingDiagnostics: TripTrackingDiagnostics(
        rawPointCount: result.rawPointCount,
        validPointCount: result.validPointCount,
        droppedPointCount: result.droppedPointCount,
        averageAccuracyMeters: result.averageAccuracyMeters,
        maxGapSeconds: result.maxGapSeconds,
        durationSeconds: result.endedAt.difference(result.startedAt).inSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final autoEnabled = widget.preferences.autoTripDetectionEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<AutoDetectionState>(
      valueListenable: appAutoDetectionService.stateNotifier,
      builder: (context, autoState, _) {
        final autoIsActive = autoState != AutoDetectionState.idle;

        return ValueListenableBuilder<bool>(
          valueListenable: appTrackingService.isTrackingNotifier,
          builder: (context, isTracking, _) {
            final (statusText, statusColor) = switch (true) {
              _ when !autoEnabled => (
                strings.enableAutoDetectionFirst,
                colorScheme.onSurfaceVariant,
              ),
              _ when autoIsActive && !isTracking => (
                strings.autoDetectionActive,
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

            if (widget.compact) {
              return Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                          const Spacer(),
                          if (autoEnabled)
                            Tooltip(
                              message: isTracking
                                  ? strings.stopTracking
                                  : strings.startTracking,
                              child: IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                onPressed:
                                    (isTracking
                                        ? _isBusy
                                        : (autoIsActive || _isBusy))
                                    ? null
                                    : isTracking
                                    ? _handleStop
                                    : _handleStart,
                                icon: Icon(
                                  isTracking ? Icons.stop : Icons.gps_fixed,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.foregroundTracking,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
              );
            }

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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: statusColor),
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
                          onPressed: (autoIsActive || _isBusy)
                              ? null
                              : _handleStart,
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
      },
    );
  }

  Future<String?> _reverseGeocodeSafely(
    double latitude,
    double longitude,
  ) async {
    try {
      return await _geocodingService.reverseGeocode(latitude, longitude);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ForegroundTracking] reverse geocoding failed: $e');
      }
      return null;
    }
  }
}
