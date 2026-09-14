import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tracking_result.dart';

typedef TrackingPointStreamFactory = Stream<TrackingPoint> Function();
typedef InitialPositionProvider = Future<TrackingPoint?> Function();
typedef StopPositionProvider = Future<TrackingPoint?> Function();

class ForegroundTripTrackingService {
  ForegroundTripTrackingService({
    TrackingPointStreamFactory? pointStreamFactory,
    InitialPositionProvider? initialPositionProvider,
    StopPositionProvider? stopPositionProvider,
    this.maxAccuracyMeters = TrackingResult.defaultMaxAccuracyMeters,
  }) : _pointStreamFactory = pointStreamFactory,
       _initialPositionProvider = initialPositionProvider,
       _stopPositionProvider = stopPositionProvider ?? initialPositionProvider;

  final TrackingPointStreamFactory? _pointStreamFactory;
  final InitialPositionProvider? _initialPositionProvider;
  final StopPositionProvider? _stopPositionProvider;
  final double maxAccuracyMeters;

  // Cap stored points to avoid oversized local JSON for long trips.
  static const int _maxStoredPoints = 1000;

  final List<TrackingPoint> _points = [];
  StreamSubscription<TrackingPoint>? _subscription;
  Timer? _positionPollingTimer;
  bool _isPollingPosition = false;
  int _rawPointCount = 0;
  int _droppedPointCount = 0;
  double _carriedDistanceKm = 0;
  DateTime? _startedAt;
  int _session = 0;
  Future<bool>? _starting;
  Future<(TrackingResult?, TrackingFailureReason?)>? _stopping;

  // Listenable so the UI (card, cross-tab banner) can react without polling.
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);
  // Kept true if the OS ends the GPS stream, so the UI can still save the
  // recorded route instead of offering to start over and discard it.
  final ValueNotifier<bool> hasPendingTripNotifier = ValueNotifier(false);
  final ValueNotifier<List<TrackingPoint>> activeRouteNotifier = ValueNotifier(
    const [],
  );

  bool get isTracking => _subscription != null;

  static const int _positionPollingSeconds = 8;

  Future<bool> startTracking({
    TrackingPointStreamFactory? pointStreamFactory,
  }) async {
    final stopping = _stopping;
    if (stopping != null) await stopping;
    final starting = _starting;
    if (starting != null) return starting;
    if (isTracking) return true;
    if (hasPendingTripNotifier.value) return false;

    final operation = _startTracking(pointStreamFactory: pointStreamFactory);
    _starting = operation;
    try {
      return await operation;
    } finally {
      if (identical(_starting, operation)) _starting = null;
    }
  }

  Future<bool> _startTracking({
    TrackingPointStreamFactory? pointStreamFactory,
  }) async {
    final factory = pointStreamFactory ?? _pointStreamFactory;
    if (factory == null) {
      if (kDebugMode) {
        debugPrint(
          '[ForegroundTracking] startTracking failed — no stream factory',
        );
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint(
        '[ForegroundTracking] startTracking called — instance=$hashCode',
      );
    }

    _points.clear();
    _rawPointCount = 0;
    _droppedPointCount = 0;
    _carriedDistanceKm = 0;
    _startedAt = null;
    activeRouteNotifier.value = const [];
    final session = ++_session;

    // Subscribe while the app is still in the foreground. Waiting for the
    // first fix before starting Android's foreground service can miss that
    // opportunity if the user immediately locks the screen.
    try {
      _subscription = factory().listen(
        (point) {
          if (session == _session && isTracking) _recordPoint(point);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (kDebugMode) {
            debugPrint('[ForegroundTracking] stream error: $error');
          }
          _streamEnded(session);
        },
        onDone: () => _streamEnded(session),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ForegroundTracking] stream start failed: $error');
      }
      return false;
    }
    isTrackingNotifier.value = true;
    _startPositionPolling();

    // Seed the session with the current position immediately so we have at
    // least one point even before the stream's distanceFilter threshold fires.
    final positionProvider = _initialPositionProvider;
    if (positionProvider != null) {
      try {
        final initial = await positionProvider();
        if (session != _session || !isTracking) return false;
        if (initial != null) {
          _recordPoint(initial);
        }
      } catch (e) {
        // Initial position failure is non-fatal; the stream will still
        // collect points as the device moves.
        if (kDebugMode) {
          debugPrint(
            '[ForegroundTracking] initial getCurrentPosition failed: $e',
          );
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[ForegroundTracking] tracking started — stream subscription created',
      );
    }
    return session == _session && isTracking;
  }

  Future<(TrackingResult?, TrackingFailureReason?)> stopTracking() {
    return _stopping ??= _stopTracking().whenComplete(() => _stopping = null);
  }

  Future<(TrackingResult?, TrackingFailureReason?)> _stopTracking() async {
    final subscription = _subscription;
    ++_session;
    _starting = null;
    _subscription = null;
    _stopPositionPolling();
    isTrackingNotifier.value = false; // update UI immediately, before await

    if (subscription != null) {
      await subscription.cancel();
    }
    if (subscription != null || _points.isNotEmpty) await _addStopPosition();

    if (kDebugMode) {
      debugPrint(
        '[ForegroundTracking] stop — instance=$hashCode, '
        '${_points.length} accurate points collected',
      );
    }

    final result = TrackingResult.fromPoints(
      _points,
      maxAccuracyMeters: maxAccuracyMeters,
      rawPointCountOverride: _rawPointCount,
      droppedPointCountOverride: _droppedPointCount,
      carriedDistanceKm: _carriedDistanceKm,
      startedAtOverride: _startedAt,
    );

    TrackingFailureReason? reason;
    if (result == null) {
      if (_points.isEmpty) {
        reason = TrackingFailureReason.noAccuratePoints;
      } else if (_points.length < 2) {
        reason = TrackingFailureReason.tooFewPoints;
      } else {
        reason = TrackingFailureReason.distanceTooShort;
      }
      if (kDebugMode) {
        debugPrint('[ForegroundTracking] result=null reason=$reason');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          '[ForegroundTracking] result dist=${result.distanceKm.toStringAsFixed(3)} km, '
          'points=${result.points.length}',
        );
      }
    }

    _points.clear();
    activeRouteNotifier.value = const [];
    hasPendingTripNotifier.value = false;
    return (result, reason);
  }

  void _streamEnded(int session) {
    if (session != _session) return;
    final subscription = _subscription;
    _subscription = null;
    _stopPositionPolling();
    isTrackingNotifier.value = false;
    if (subscription != null) unawaited(subscription.cancel());
  }

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
    if (provider == null || !isTracking || _isPollingPosition) return;

    _isPollingPosition = true;
    final session = _session;
    try {
      final point = await provider();
      if (point == null || session != _session || !isTracking) return;
      _recordPoint(point);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ForegroundTracking] polling getCurrentPosition failed: $e',
        );
      }
    } finally {
      if (session == _session) _isPollingPosition = false;
    }
  }

  void _recordPoint(TrackingPoint point) {
    _rawPointCount++;
    if (point.isAccurateEnough(maxAccuracyMeters) &&
        (_points.isEmpty || point.timestamp.isAfter(_points.last.timestamp))) {
      _startedAt ??= point.timestamp;
      _points.add(point);
      hasPendingTripNotifier.value = true;
      if (_points.length > _maxStoredPoints) {
        final removeCount = _maxStoredPoints ~/ 4;
        _carriedDistanceKm += TrackingResult.calculateDistanceKm(
          _points.sublist(0, removeCount + 1),
          minimumSegmentDistanceMeters:
              TrackingResult.defaultMinimumSegmentDistanceMeters,
        );
        _points.removeRange(0, removeCount);
      }
      activeRouteNotifier.value = List<TrackingPoint>.unmodifiable(_points);
      if (kDebugMode) {
        debugPrint(
          '[ForegroundTracking] point added — count=${_points.length}, '
          'accuracy=${point.accuracyMeters.toStringAsFixed(1)} m',
        );
      }
    } else {
      _droppedPointCount++;
      if (kDebugMode) {
        debugPrint(
          '[ForegroundTracking] point ignored — '
          'accuracy=${point.accuracyMeters.toStringAsFixed(1)} m (max=$maxAccuracyMeters m)',
        );
      }
    }
  }

  Future<void> _addStopPosition() async {
    final provider = _stopPositionProvider;
    if (provider == null) return;

    try {
      final point = await provider();
      if (point == null) return;

      final last = _points.isNotEmpty ? _points.last : null;
      if (last != null &&
          last.latitude == point.latitude &&
          last.longitude == point.longitude &&
          last.timestamp == point.timestamp) {
        return;
      }

      _recordPoint(point);
      if (kDebugMode) {
        debugPrint('[ForegroundTracking] stop position sampled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ForegroundTracking] stop getCurrentPosition failed: $e');
      }
    }
  }
}
