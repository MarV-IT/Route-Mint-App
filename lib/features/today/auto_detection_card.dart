import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/location/auto_trip_detection_service.dart';
import '../../core/location/geolocator_tracking_provider.dart';
import '../../core/location/location_permission_service.dart';
import '../../core/notifications/trip_notification_service.dart';
import '../../core/preferences/user_preferences.dart';

class AutoDetectionCard extends StatefulWidget {
  const AutoDetectionCard({
    super.key,
    required this.strings,
    required this.preferences,
    required this.onTripSaved,
  });

  final AppStrings strings;
  final UserPreferences preferences;
  final VoidCallback onTripSaved;

  @override
  State<AutoDetectionCard> createState() => _AutoDetectionCardState();
}

class _AutoDetectionCardState extends State<AutoDetectionCard> {
  final _permissionService = LocationPermissionService();
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    appAutoDetectionService.onTripSaved = _onTripSaved;
  }

  @override
  void dispose() {
    if (appAutoDetectionService.onTripSaved == _onTripSaved) {
      appAutoDetectionService.onTripSaved = null;
    }
    super.dispose();
  }

  void _onTripSaved() {
    widget.onTripSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.detectedTripSavedForReview)),
      );
    }
  }

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
          await appAutoDetectionService.startMonitoring();
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
      final outcome = await appAutoDetectionService.stopMonitoring();
      if (!mounted) return;
      // tripSaved: _onTripSaved callback already fired inside stopMonitoring
      // via _finishTrip → onTripSaved?.call(). Don't double-call here.
      if (outcome == AutoStopOutcome.noMovement) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.strings.notEnoughMovementDetected)),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = widget.strings.trackingError);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final autoEnabled = widget.preferences.autoTripDetectionEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<AutoDetectionState>(
      valueListenable: appAutoDetectionService.stateNotifier,
      builder: (context, autoState, _) {
        final isActive = autoState != AutoDetectionState.idle;

        final (statusText, statusColor) = switch (true) {
          _ when !autoEnabled => (
            strings.enableAutoDetectionFirst,
            colorScheme.onSurfaceVariant,
          ),
          _ when autoState == AutoDetectionState.idle => (
            strings.autoDetectionOff,
            colorScheme.onSurfaceVariant,
          ),
          _ when autoState == AutoDetectionState.monitoring => (
            strings.watchingForMovement,
            colorScheme.primary,
          ),
          _ => (strings.tripDetectedTracking, colorScheme.primary),
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
                      isActive ? Icons.sensors : Icons.sensors_off,
                      size: 20,
                      color: isActive ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.autoTripDetection,
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
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ),
                if (autoEnabled) ...[
                  const SizedBox(height: 12),
                  if (isActive)
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _handleStop,
                      icon: const Icon(Icons.stop),
                      label: Text(strings.stopAutoDetection),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _handleStart,
                      icon: const Icon(Icons.sensors),
                      label: Text(strings.startAutoDetection),
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
