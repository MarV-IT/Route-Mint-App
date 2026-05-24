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

  // Listenable so the UI (card, cross-tab banner) can react without polling.
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);
  final ValueNotifier<List<TrackingPoint>> activeRouteNotifier = ValueNotifier(
    const [],
  );

  bool get isTracking => _subscription != null;

  static const int _positionPollingSeconds = 8;

  Future<bool> startTracking({
    TrackingPointStreamFactory? pointStreamFactory,
  }) async {
    if (isTracking) return true;

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
    activeRouteNotifier.value = const [];

    // Seed the session with the current position immediately so we have at
    // least one point even before the stream's distanceFilter threshold fires.
    final positionProvider = _initialPositionProvider;
    if (positionProvider != null) {
      try {
        final initial = await positionProvider();
        if (initial != null) {
          _rawPointCount++;
          if (initial.isAccurateEnough(maxAccuracyMeters)) {
            _points.add(initial);
            activeRouteNotifier.value = List<TrackingPoint>.unmodifiable(
              _points,
            );
            if (kDebugMode) {
              debugPrint(
                '[ForegroundTracking] initial point added — '
                'lat=${initial.latitude.toStringAsFixed(5)}, '
                'lon=${initial.longitude.toStringAsFixed(5)}, '
                'accuracy=${initial.accuracyMeters.toStringAsFixed(1)} m',
              );
            }
          } else {
            _droppedPointCount++;
            if (kDebugMode) {
              debugPrint(
                '[ForegroundTracking] initial point accuracy too low — '
                '${initial.accuracyMeters.toStringAsFixed(1)} m (max=$maxAccuracyMeters m)',
              );
            }
          }
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

    _subscription = factory().listen(
      _recordPoint,
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('[ForegroundTracking] stream error: $error');
        }
      },
    );
    _startPositionPolling();

    isTrackingNotifier.value = true;
    if (kDebugMode) {
      debugPrint(
        '[ForegroundTracking] tracking started — stream subscription created',
      );
    }
    return true;
  }

  Future<(TrackingResult?, TrackingFailureReason?)> stopTracking() async {
    final subscription = _subscription;
    _subscription = null;
    _stopPositionPolling();
    isTrackingNotifier.value = false; // update UI immediately, before await

    await _addStopPosition();

    if (subscription != null) {
      await subscription.cancel();
    }

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
    return (result, reason);
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
    try {
      final point = await provider();
      if (point == null || !isTracking) return;
      _recordPoint(point);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ForegroundTracking] polling getCurrentPosition failed: $e',
        );
      }
    } finally {
      _isPollingPosition = false;
    }
  }

  void _recordPoint(TrackingPoint point) {
    _rawPointCount++;
    if (point.isAccurateEnough(maxAccuracyMeters)) {
      _points.add(point);
      if (_points.length > _maxStoredPoints) {
        _points.removeRange(0, _maxStoredPoints ~/ 4);
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
