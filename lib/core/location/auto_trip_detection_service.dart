import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tracking_result.dart';
import '../../features/trips/models/trip.dart';
import '../../features/trips/services/trip_service.dart';
import '../../features/work_mode/services/work_mode_service.dart';
import '../notifications/trip_notification_service.dart';
import 'reverse_geocoding_service.dart';

enum AutoDetectionState { idle, monitoring, tracking }

enum AutoStopOutcome { stopped, tripSaved, noMovement }

typedef AutoTripStreamFactory = Stream<TrackingPoint> Function();
typedef AutoTripPositionProvider = Future<TrackingPoint?> Function();

class AutoTripDetectionService {
  AutoTripDetectionService({
    required AutoTripStreamFactory monitoringStreamFactory,
    AutoTripPositionProvider? initialPositionProvider,
  }) : _monitoringStreamFactory = monitoringStreamFactory,
       _initialPositionProvider = initialPositionProvider;

  final AutoTripStreamFactory _monitoringStreamFactory;
  final AutoTripPositionProvider? _initialPositionProvider;

  // ── Detection thresholds ────────────────────────────────────────────────
  static const double _maxAccuracyMeters =
      TrackingResult.defaultMaxAccuracyMeters;
  static const double _startMaxAccuracyMeters = 75;

  // Start detection: a trip starts after enough displacement, enough
  // cumulative movement, or two consecutive vehicle-speed samples.
  static const int _startWindowSeconds = 180; // 3-min rolling window
  static const double _startDisplacementMeters = 250; // A: first→last in window
  static const int _startOutsideAnchorPoints = 2;
  static const double _startTotalMovementMeters =
      350; // B: cumulative path in window
  static const double _startSpeedKmh = 15.0; // C: instant speed trigger
  static const int _startConsecutivePoints = 3; // N consecutive fast points

  // Stop detection: save the active trip after 3 minutes without meaningful
  // movement, then resume monitoring for the next trip.
  static const int _stopTimeoutSeconds = 180; // 3-min idle → stop
  static const double _stopMovementThresholdMeters =
      100; // meaningful move resets idle

  static const double _minimumAutoTripDistanceKm = 0.5;
  static const double _autoRouteSegmentMeters = 30;
  static const double _liveMapSegmentMeters = 75;
  static const int _stationaryRouteFreezeSeconds = 45;

  // Runtime caps and polling fallback. Polling keeps detection working when
  // Android does not deliver position stream events while monitoring.
  static const int _maxTrackingPoints = 2000;
  static const int _positionPollingSeconds = 8;
  // Monitoring buffer trimmed by time: keep last (window + 1 min headroom).
  static const int _windowRetentionSeconds = _startWindowSeconds + 60;

  // ── Reactive state ──────────────────────────────────────────────────────
  final ValueNotifier<AutoDetectionState> stateNotifier = ValueNotifier(
    AutoDetectionState.idle,
  );
  final ValueNotifier<List<TrackingPoint>> activeRouteNotifier = ValueNotifier(
    const [],
  );

  AutoDetectionState get state => stateNotifier.value;
  bool get isMonitoring => state != AutoDetectionState.idle;
  bool get isTripActive => state == AutoDetectionState.tracking;

  // Fires after each successful trip save so the UI can reload the trip list.
  VoidCallback? onTripSaved;

  // ── Monitoring phase ────────────────────────────────────────────────────
  StreamSubscription<TrackingPoint>? _subscription;
  Timer? _positionPollingTimer;
  bool _isPollingPosition = false;
  final List<TrackingPoint> _monitoringBuffer = [];
  int _consecutiveSpeedCount = 0;

  // ── Tracking phase ──────────────────────────────────────────────────────
  final List<TrackingPoint> _trackingPoints = [];
  DateTime? _lastMovementTime;
  TrackingPoint? _lastMovementPoint;
  int _tripRawPointCount = 0;
  int _tripDroppedPointCount = 0;

  // ── Services ────────────────────────────────────────────────────────────
  final _tripService = TripService();
  final _geocodingService = ReverseGeocodingService();
  final _workModeService = WorkModeService();

  // ── Public API ──────────────────────────────────────────────────────────

  Future<void> startMonitoring() async {
    if (state != AutoDetectionState.idle) return;
    _resetAll();
    _subscription = _monitoringStreamFactory().listen(_onPositionPoint);
    stateNotifier.value = AutoDetectionState.monitoring;
    await _addInitialMonitoringPoint();
    _startPositionPolling();
    if (kDebugMode) {
      debugPrint('[AutoDetection] monitoring started — instance=$hashCode');
    }
  }

  /// Stops monitoring (and finalises any active trip).
  Future<AutoStopOutcome> stopMonitoring() async {
    if (state == AutoDetectionState.idle) return AutoStopOutcome.stopped;

    final wasTracking = state == AutoDetectionState.tracking;

    // Flip state first so stale stream callbacks are ignored.
    stateNotifier.value = AutoDetectionState.idle;

    final sub = _subscription;
    _subscription = null;
    _stopPositionPolling();
    await sub?.cancel();

    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] stopMonitoring — wasTracking=$wasTracking, '
        'trackingPoints=${_trackingPoints.length}',
      );
    }

    if (!wasTracking) {
      final saved = await _finishTrip(fromMonitoringBuffer: true);
      _resetAll();
      return saved ? AutoStopOutcome.tripSaved : AutoStopOutcome.noMovement;
    }

    final saved = await _finishTrip();
    _resetAll();
    return saved ? AutoStopOutcome.tripSaved : AutoStopOutcome.noMovement;
  }

  // ── Monitoring stream handler ───────────────────────────────────────────

  void _onPositionPoint(TrackingPoint point) {
    switch (state) {
      case AutoDetectionState.monitoring:
        _onMonitoringPoint(point);
      case AutoDetectionState.tracking:
        _onTrackingPoint(point);
      case AutoDetectionState.idle:
        return;
    }
  }

  void _onMonitoringPoint(TrackingPoint point) {
    if (state != AutoDetectionState.monitoring) return;

    if (!point.isAccurateEnough(_maxAccuracyMeters)) {
      if (kDebugMode) {
        debugPrint(
          '[AutoDetection] monitoring point rejected — '
          'accuracy=${point.accuracyMeters.toStringAsFixed(1)} m '
          '(max=$_maxAccuracyMeters m)',
        );
      }
      return;
    }

    _monitoringBuffer.add(point);

    // Time-based trim: keep only the last (window + headroom) seconds.
    // This replaces the old count-based cap which was far too small for
    // fast movement with distanceFilter=10.
    final cutoff = point.timestamp.subtract(
      const Duration(seconds: _windowRetentionSeconds),
    );
    _monitoringBuffer.removeWhere((p) => p.timestamp.isBefore(cutoff));

    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] monitoring point — '
        'buffer=${_monitoringBuffer.length} pts, '
        'accuracy=${point.accuracyMeters.toStringAsFixed(1)} m, '
        'ts=${point.timestamp.toIso8601String()}',
      );
    }

    if (_shouldStartTrip(point)) {
      _transitionToTracking();
    }
  }

  bool _shouldStartTrip(TrackingPoint latest) {
    final windowCutoff = latest.timestamp.subtract(
      const Duration(seconds: _startWindowSeconds),
    );
    final window = _monitoringBuffer
        .where((p) => !p.timestamp.isBefore(windowCutoff))
        .toList(growable: false);
    final startQualityWindow = window
        .where((p) => p.accuracyMeters <= _startMaxAccuracyMeters)
        .toList(growable: false);

    if (startQualityWindow.length < 2) {
      if (kDebugMode) {
        debugPrint(
          '[AutoDetection] shouldStart: window too small '
          '(${startQualityWindow.length} start-quality pts in last '
          '${_startWindowSeconds}s)',
        );
      }
      return false;
    }

    final firstPoint = startQualityWindow.first;
    if (!_hasLeftStartAnchor(startQualityWindow, firstPoint)) {
      if (kDebugMode) {
        debugPrint('[AutoDetection] shouldStart: still inside start anchor');
      }
      _consecutiveSpeedCount = 0;
      return false;
    }

    // Condition A: displacement first→last >= _startDisplacementMeters
    final displacementM =
        TrackingResult.distanceBetweenKm(firstPoint, startQualityWindow.last) *
        1000;
    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] shouldStart A: displacement='
        '${displacementM.toStringAsFixed(0)} m '
        '(threshold=${_startDisplacementMeters.toStringAsFixed(0)} m)',
      );
    }
    if (displacementM >= _startDisplacementMeters) {
      if (kDebugMode) debugPrint('[AutoDetection] start trigger: displacement');
      return true;
    }

    // Condition B: cumulative path >= _startTotalMovementMeters
    final totalM =
        TrackingResult.calculateDistanceKm(startQualityWindow) * 1000;
    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] shouldStart B: total movement='
        '${totalM.toStringAsFixed(0)} m '
        '(threshold=${_startTotalMovementMeters.toStringAsFixed(0)} m)',
      );
    }
    if (totalM >= _startTotalMovementMeters) {
      if (kDebugMode) {
        debugPrint('[AutoDetection] start trigger: total movement');
      }
      return true;
    }

    // Condition C: speed >= _startSpeedKmh for N consecutive point pairs.
    // Use inMilliseconds to avoid zero-rounding on sub-second intervals.
    if (startQualityWindow.length >= 2) {
      final prev = startQualityWindow[startQualityWindow.length - 2];
      final current = startQualityWindow.last;
      final dtMs = current.timestamp.difference(prev.timestamp).inMilliseconds;
      if (dtMs > 0) {
        final km = TrackingResult.distanceBetweenKm(prev, current);
        final kmh = km / (dtMs / 3600000.0);
        if (kDebugMode) {
          debugPrint(
            '[AutoDetection] shouldStart C: speed='
            '${kmh.toStringAsFixed(1)} km/h '
            '(threshold=$_startSpeedKmh, '
            'consecutive=$_consecutiveSpeedCount/$_startConsecutivePoints)',
          );
        }
        if (kmh >= _startSpeedKmh) {
          _consecutiveSpeedCount++;
          if (_consecutiveSpeedCount >= _startConsecutivePoints) {
            if (kDebugMode) debugPrint('[AutoDetection] start trigger: speed');
            return true;
          }
        } else {
          _consecutiveSpeedCount = 0;
        }
      }
    }

    return false;
  }

  bool _hasLeftStartAnchor(List<TrackingPoint> window, TrackingPoint anchor) {
    var outsideCount = 0;
    for (final point in window) {
      final meters = TrackingResult.distanceBetweenKm(anchor, point) * 1000;
      if (meters >= _startDisplacementMeters) {
        outsideCount++;
      }
    }
    return outsideCount >= _startOutsideAnchorPoints;
  }

  Future<void> _addInitialMonitoringPoint() async {
    final provider = _initialPositionProvider;
    if (provider == null || state != AutoDetectionState.monitoring) return;

    try {
      final point = await provider();
      if (point == null || state != AutoDetectionState.monitoring) return;
      _onMonitoringPoint(point);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AutoDetection] initial getCurrentPosition failed: $e');
      }
    }
  }

  // ── Tracking stream handler ─────────────────────────────────────────────

  void _startPositionPolling() {
    if (_initialPositionProvider == null || _positionPollingTimer != null) {
      return;
    }

    _positionPollingTimer = Timer.periodic(
      const Duration(seconds: _positionPollingSeconds),
      (_) => _pollCurrentPosition(),
    );
  }

  void _stopPositionPolling() {
    _positionPollingTimer?.cancel();
    _positionPollingTimer = null;
    _isPollingPosition = false;
  }

  Future<void> _pollCurrentPosition() async {
    final provider = _initialPositionProvider;
    if (provider == null ||
        state == AutoDetectionState.idle ||
        _isPollingPosition) {
      return;
    }

    _isPollingPosition = true;
    try {
      final point = await provider();
      if (point == null || state == AutoDetectionState.idle) return;

      if (state == AutoDetectionState.monitoring) {
        _onMonitoringPoint(point);
      } else if (state == AutoDetectionState.tracking) {
        _onTrackingPoint(point);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AutoDetection] polling getCurrentPosition failed: $e');
      }
    } finally {
      _isPollingPosition = false;
    }
  }

  void _onTrackingPoint(TrackingPoint point) {
    if (state != AutoDetectionState.tracking) return;
    _tripRawPointCount++;

    if (!point.isAccurateEnough(_maxAccuracyMeters)) {
      _tripDroppedPointCount++;
      if (kDebugMode) {
        debugPrint(
          '[AutoDetection] tracking point rejected — '
          'accuracy=${point.accuracyMeters.toStringAsFixed(1)} m',
        );
      }
      return;
    }

    final prev = _lastMovementPoint;
    if (prev != null && _lastMovementTime != null) {
      final meters = TrackingResult.distanceBetweenKm(prev, point) * 1000;
      final idleSec = point.timestamp.difference(_lastMovementTime!).inSeconds;
      if (idleSec >= _stationaryRouteFreezeSeconds &&
          meters < _stopMovementThresholdMeters) {
        if (kDebugMode) {
          debugPrint(
            '[AutoDetection] stationary GPS drift suppressed - '
            'idle=${idleSec}s, drift=${meters.toStringAsFixed(0)} m',
          );
        }
        if (idleSec >= _stopTimeoutSeconds) {
          if (kDebugMode) {
            debugPrint(
              '[AutoDetection] stop condition met - '
              'idle for ${idleSec}s',
            );
          }
          _autoStopTrip();
        }
        return;
      }
    }

    _trackingPoints.add(point);
    if (_trackingPoints.length > _maxTrackingPoints) {
      _trackingPoints.removeRange(0, _maxTrackingPoints ~/ 4);
    }
    _publishActiveRoute();

    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] tracking point — '
        'count=${_trackingPoints.length}, '
        'accuracy=${point.accuracyMeters.toStringAsFixed(1)} m',
      );
    }

    // Update movement timestamp when meaningful displacement occurs.
    if (prev != null) {
      final meters = TrackingResult.distanceBetweenKm(prev, point) * 1000;
      if (meters >= _stopMovementThresholdMeters) {
        _lastMovementTime = point.timestamp;
        _lastMovementPoint = point;
        if (kDebugMode) {
          debugPrint(
            '[AutoDetection] idle timer reset — '
            'moved ${meters.toStringAsFixed(0)} m',
          );
        }
      } else if (kDebugMode && _lastMovementTime != null) {
        final idleSec = point.timestamp
            .difference(_lastMovementTime!)
            .inSeconds;
        debugPrint(
          '[AutoDetection] stationary for ${idleSec}s '
          '(timeout=${_stopTimeoutSeconds}s, '
          'last move=${meters.toStringAsFixed(0)} m)',
        );
      }
    } else {
      _lastMovementTime = point.timestamp;
      _lastMovementPoint = point;
    }

    final lastMove = _lastMovementTime;
    if (lastMove != null) {
      final idleSec = point.timestamp.difference(lastMove).inSeconds;
      if (idleSec >= _stopTimeoutSeconds) {
        if (kDebugMode) {
          debugPrint(
            '[AutoDetection] stop condition met — '
            'idle for ${idleSec}s',
          );
        }
        _autoStopTrip(); // fire-and-forget; state guard prevents re-entry
      }
    }
  }

  // ── State transitions ───────────────────────────────────────────────────

  void _transitionToTracking() {
    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] transitioning to tracking — '
        'seeding ${_monitoringBuffer.length} monitoring points',
      );
    }

    // Seed active trip from the monitoring window so the route starts from
    // when movement was first detected, not from the threshold-fire point.
    _trackingPoints
      ..clear()
      ..addAll(_monitoringBuffer);
    _tripRawPointCount = _trackingPoints.length;
    _tripDroppedPointCount = 0;
    _publishActiveRoute();
    _lastMovementPoint = _trackingPoints.isNotEmpty
        ? _trackingPoints.last
        : null;
    _lastMovementTime = _lastMovementPoint?.timestamp ?? DateTime.now();

    stateNotifier.value = AutoDetectionState.tracking;

    // Keep the existing foreground location stream alive. Starting a new
    // location foreground service while the screen is off can be throttled by
    // Android, which may cut the route short mid-trip.

    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] tracking active — '
        '${_trackingPoints.length} initial points',
      );
    }
  }

  Future<void> _autoStopTrip() async {
    if (state != AutoDetectionState.tracking) return;

    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] auto-stop — '
        '${_trackingPoints.length} tracking points',
      );
    }

    // Flip to monitoring first to block re-entry from additional GPS points.
    stateNotifier.value = AutoDetectionState.monitoring;

    await _finishTrip();

    // Continue monitoring on the same foreground stream unless stopMonitoring()
    // was called in the meantime.
    if (state == AutoDetectionState.monitoring) {
      _resetMonitoringBuffers();
      if (kDebugMode) {
        debugPrint('[AutoDetection] resumed monitoring after auto-stop');
      }
    }
  }

  // ── Trip persistence ────────────────────────────────────────────────────

  /// Returns true if a trip meeting the minimum distance threshold was saved.
  Future<bool> _finishTrip({bool fromMonitoringBuffer = false}) async {
    final sourcePoints = fromMonitoringBuffer
        ? _monitoringBuffer
        : _trackingPoints;
    final points = List<TrackingPoint>.from(sourcePoints);
    _trackingPoints.clear();
    activeRouteNotifier.value = const [];

    if (kDebugMode) {
      debugPrint('[AutoDetection] _finishTrip — ${points.length} points');
    }

    final result = TrackingResult.fromPoints(
      points,
      maxAccuracyMeters: _maxAccuracyMeters,
      minimumDistanceKm: _minimumAutoTripDistanceKm,
      minimumSegmentDistanceMeters: _autoRouteSegmentMeters,
      rawPointCountOverride: fromMonitoringBuffer
          ? points.length
          : _tripRawPointCount,
      droppedPointCountOverride: fromMonitoringBuffer
          ? 0
          : _tripDroppedPointCount,
    );

    if (result == null) {
      if (kDebugMode) {
        if (points.isEmpty) {
          debugPrint('[AutoDetection] result=null — no accurate points');
        } else if (points.length < 2) {
          debugPrint(
            '[AutoDetection] result=null — '
            'too few points (${points.length})',
          );
        } else {
          final distM = TrackingResult.calculateDistanceKm(points) * 1000;
          debugPrint(
            '[AutoDetection] result=null — '
            'distance=${distM.toStringAsFixed(0)} m below minimum '
            '(${(_minimumAutoTripDistanceKm * 1000).toStringAsFixed(0)} m)',
          );
        }
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] result dist='
        '${result.distanceKm.toStringAsFixed(3)} km, '
        'points=${result.points.length}',
      );
    }

    final start = result.points.first;
    final end = result.points.last;

    final addresses = await Future.wait([
      _reverseGeocodeSafely(start.latitude, start.longitude),
      _reverseGeocodeSafely(end.latitude, end.longitude),
    ]);

    final tripId = DateTime.now().millisecondsSinceEpoch.toString();
    final workSettings = await _workModeService.loadSettings();
    final matchedShift = _workModeService.matchingShiftAt(
      workSettings,
      result.startedAt,
    );
    if (kDebugMode) {
      debugPrint(
        '[AutoDetection] saving trip id=$tripId '
        'from=${addresses[0]} to=${addresses[1]}',
      );
    }

    await _tripService.addTrip(
      Trip(
        id: tripId,
        from: addresses[0] ?? 'Detected start',
        to: addresses[1] ?? 'Detected end',
        distance: result.distanceKm,
        category: matchedShift == null ? 'personal' : 'business',
        date: result.startedAt.toLocal(),
        platformName: matchedShift?.platformName,
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
          durationSeconds: result.endedAt
              .difference(result.startedAt)
              .inSeconds,
        ),
      ),
    );
    await TripNotificationService.instance.showTripSavedForReview(
      distanceKm: result.distanceKm,
    );

    if (kDebugMode) {
      debugPrint('[AutoDetection] trip saved id=$tripId');
    }
    onTripSaved?.call();
    return true;
  }

  // ── Reset helpers ───────────────────────────────────────────────────────

  void _resetMonitoringBuffers() {
    _monitoringBuffer.clear();
    _consecutiveSpeedCount = 0;
  }

  void _resetAll() {
    _monitoringBuffer.clear();
    _consecutiveSpeedCount = 0;
    _trackingPoints.clear();
    activeRouteNotifier.value = const [];
    _lastMovementTime = null;
    _lastMovementPoint = null;
    _tripRawPointCount = 0;
    _tripDroppedPointCount = 0;
  }

  void _publishActiveRoute() {
    final visibleRoute = TrackingResult.simplifyRoutePoints(
      _trackingPoints,
      minimumSegmentDistanceMeters: _liveMapSegmentMeters,
    );
    activeRouteNotifier.value = List<TrackingPoint>.unmodifiable(visibleRoute);
  }

  Future<String?> _reverseGeocodeSafely(
    double latitude,
    double longitude,
  ) async {
    try {
      return await _geocodingService.reverseGeocode(latitude, longitude);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AutoDetection] reverse geocoding failed: $e');
      }
      return null;
    }
  }
}
