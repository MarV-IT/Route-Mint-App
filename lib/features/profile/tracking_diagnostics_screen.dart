import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/device/battery_optimization_service.dart';
import '../../core/localization/app_strings.dart';
import '../../core/location/auto_trip_detection_service.dart';
import '../../core/location/geolocator_tracking_provider.dart';
import '../../core/notifications/trip_notification_service.dart';
import '../trips/models/trip.dart';
import '../trips/services/trip_service.dart';

class TrackingDiagnosticsScreen extends StatefulWidget {
  const TrackingDiagnosticsScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  State<TrackingDiagnosticsScreen> createState() =>
      _TrackingDiagnosticsScreenState();
}

class _TrackingDiagnosticsScreenState extends State<TrackingDiagnosticsScreen> {
  final _batteryService = BatteryOptimizationService();
  final _tripService = TripService();

  bool _isLoading = true;
  bool? _locationServicesEnabled;
  LocationPermission? _locationPermission;
  bool? _notificationsEnabled;
  bool? _batteryUnrestricted;
  Position? _lastPosition;
  Position? _currentPosition;
  Object? _gpsError;
  int _needsReviewCount = 0;
  int _gpsRiskCount = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _gpsError = null;
    });

    try {
      final locationServices = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final notifications = await TripNotificationService.instance
          .areNotificationsEnabled();
      final battery = await _batteryService.isIgnoringBatteryOptimizations();
      final last = await Geolocator.getLastKnownPosition();
      final trips = await _tripService.loadTrips();
      final needsReview = trips
          .where((trip) => trip.reviewStatus == TripReviewStatus.needsReview)
          .length;
      final gpsRisk = trips.where(_hasGpsRisk).length;

      Position? current;
      Object? gpsError;
      if (locationServices &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse)) {
        try {
          current = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[TrackingDiagnostics] current position failed: $e');
          }
          gpsError = e;
        }
      }

      if (!mounted) return;
      setState(() {
        _locationServicesEnabled = locationServices;
        _locationPermission = permission;
        _notificationsEnabled = notifications;
        _batteryUnrestricted = battery;
        _lastPosition = last;
        _currentPosition = current;
        _gpsError = gpsError;
        _needsReviewCount = needsReview;
        _gpsRiskCount = gpsRisk;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TrackingDiagnostics] refresh failed: $e');
      }
      if (!mounted) return;
      setState(() {
        _gpsError = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotifications() async {
    await TripNotificationService.instance.requestPermission();
    final enabled = await TripNotificationService.instance
        .areNotificationsEnabled();
    if (enabled != true) {
      await TripNotificationService.instance.openNotificationSettings();
    }
    await _refresh();
  }

  Future<void> _sendTestNotification() async {
    final shown = await TripNotificationService.instance.showTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shown
              ? widget.strings.testNotificationSent
              : widget.strings.notificationTestHint,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> _openBatterySettings() async {
    await _batteryService.openBatteryOptimizationSettings();
  }

  bool _hasGpsRisk(Trip trip) {
    final diagnostics = trip.trackingDiagnostics;
    if (diagnostics == null) return false;
    return diagnostics.maxGapSeconds > 90 ||
        diagnostics.averageAccuracyMeters > 100;
  }

  String _permissionText(LocationPermission? permission) {
    final s = widget.strings;
    return switch (permission) {
      LocationPermission.always => s.alwaysPermission,
      LocationPermission.whileInUse => s.whileInUsePermission,
      LocationPermission.denied => s.denied,
      LocationPermission.deniedForever => s.deniedForever,
      LocationPermission.unableToDetermine => s.unknown,
      null => s.unknown,
    };
  }

  String _positionText(Position? position) {
    if (position == null) return widget.strings.noPointYet;
    final time = position.timestamp.toLocal();
    final timeText =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    return '${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)} • '
        '${position.accuracy.toStringAsFixed(0)} m • $timeText';
  }

  String _autoDetectionStateText(AutoDetectionState state) {
    final s = widget.strings;
    return switch (state) {
      AutoDetectionState.idle => s.autoDetectionOff,
      AutoDetectionState.monitoring => s.watchingForMovement,
      AutoDetectionState.tracking => s.tripDetectedTracking,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final currentGps = _currentPosition ?? _lastPosition;
    final permissionOk =
        _locationPermission == LocationPermission.always ||
        _locationPermission == LocationPermission.whileInUse;
    final isReady =
        _locationServicesEnabled == true &&
        permissionOk &&
        _notificationsEnabled == true &&
        _batteryUnrestricted == true;

    return Scaffold(
      appBar: AppBar(title: Text(s.trackingDiagnostics)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: isReady
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isReady
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: isReady
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.trackingReliabilityMode,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: isReady
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isReady
                                ? s.readyForScreenOffTracking
                                : s.screenOffTrackingRisk,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isReady
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.reliabilityModeExplanation,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isReady
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onErrorContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!isReady || _needsReviewCount > 0 || _gpsRiskCount > 0) ...[
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.whatNeedsAttention,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_locationServicesEnabled != true)
                        _issueLine(
                          Icons.location_off_outlined,
                          s.locationServices,
                        ),
                      if (!permissionOk)
                        _issueLine(Icons.gps_not_fixed, s.locationPermission),
                      if (_notificationsEnabled != true)
                        _issueLine(
                          Icons.notifications_off_outlined,
                          s.tripSavedNotifications,
                        ),
                      if (_batteryUnrestricted != true)
                        _issueLine(
                          Icons.battery_alert_outlined,
                          s.batteryOptimization,
                        ),
                      if (_needsReviewCount > 0)
                        _issueLine(
                          Icons.rate_review_outlined,
                          s.detectedTripsNeedReview(_needsReviewCount),
                        ),
                      if (_gpsRiskCount > 0)
                        _issueLine(
                          Icons.warning_amber_outlined,
                          s.tripsHaveGpsIssues(_gpsRiskCount),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.reliabilityChecklist,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _statusTile(
                      icon: Icons.location_on_outlined,
                      label: s.locationServices,
                      value: _locationServicesEnabled == true
                          ? s.ready
                          : s.requiredForScreenOffTracking,
                      ok: _locationServicesEnabled == true,
                    ),
                    _statusTile(
                      icon: Icons.gps_fixed,
                      label: s.locationPermission,
                      value: permissionOk
                          ? _permissionText(_locationPermission)
                          : s.requiredForScreenOffTracking,
                      ok: permissionOk,
                      trailing: permissionOk
                          ? null
                          : TextButton(
                              onPressed: _openLocationSettings,
                              child: Text(s.fixNow),
                            ),
                    ),
                    _statusTile(
                      icon: Icons.notifications_active_outlined,
                      label: s.tripSavedNotifications,
                      value: _notificationsEnabled == true
                          ? s.ready
                          : s.recommendedForTripAlerts,
                      ok: _notificationsEnabled == true,
                      trailing: _notificationsEnabled == true
                          ? null
                          : TextButton(
                              onPressed: _requestNotifications,
                              child: Text(s.fixNow),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        s.notificationTestHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _sendTestNotification,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(s.sendTestNotification),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _statusTile(
                      icon: Icons.battery_saver_outlined,
                      label: s.batteryOptimization,
                      value: _batteryUnrestricted == true
                          ? s.unrestricted
                          : s.requiredForScreenOffTracking,
                      ok: _batteryUnrestricted == true,
                      trailing: _batteryUnrestricted == true
                          ? null
                          : TextButton(
                              onPressed: _openBatterySettings,
                              child: Text(s.fixNow),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.liveTrackingState,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<AutoDetectionState>(
                      valueListenable: appAutoDetectionService.stateNotifier,
                      builder: (context, state, _) => _statusTile(
                        icon: Icons.sensors_outlined,
                        label: s.autoTripDetection,
                        value: _autoDetectionStateText(state),
                        ok: state != AutoDetectionState.idle,
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: appTrackingService.isTrackingNotifier,
                      builder: (context, isTracking, _) => _statusTile(
                        icon: Icons.route_outlined,
                        label: s.manualTracking,
                        value: isTracking ? s.tracking : s.notTrackingStatus,
                        ok: isTracking,
                      ),
                    ),
                    _statusTile(
                      icon: Icons.my_location_outlined,
                      label: s.lastGpsFix,
                      value: _positionText(currentGps),
                      ok: currentGps != null && currentGps.accuracy <= 100,
                    ),
                    if (_gpsError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          s.trackingError,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ? null : _refresh,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(s.refreshDiagnostics),
            ),
          ],
        ),
      ),
    );
  }

  Widget _issueLine(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String label,
    required String value,
    required bool ok,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = ok ? colorScheme.primary : colorScheme.error;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: Text(value),
      trailing: trailing,
    );
  }
}
