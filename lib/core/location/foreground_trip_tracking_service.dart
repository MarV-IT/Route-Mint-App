import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tracking_result.dart';

typedef TrackingPointStreamFactory = Stream<TrackingPoint> Function();

class ForegroundTripTrackingService {
  ForegroundTripTrackingService({
    TrackingPointStreamFactory? pointStreamFactory,
    this.maxAccuracyMeters = TrackingResult.defaultMaxAccuracyMeters,
  }) : _pointStreamFactory = pointStreamFactory;

  final TrackingPointStreamFactory? _pointStreamFactory;
  final double maxAccuracyMeters;

  // Cap stored points to avoid oversized local JSON for long trips.
  static const int _maxStoredPoints = 1000;

  final List<TrackingPoint> _points = [];
  StreamSubscription<TrackingPoint>? _subscription;

  // Listenable so the UI (card, cross-tab banner) can react without polling.
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);

  bool get isTracking => _subscription != null;

  void startTracking({TrackingPointStreamFactory? pointStreamFactory}) {
    if (isTracking) return;

    final factory = pointStreamFactory ?? _pointStreamFactory;
    if (factory == null) {
      throw StateError('A tracking point stream factory is required.');
    }

    _points.clear();
    _subscription = factory().listen((point) {
      if (point.isAccurateEnough(maxAccuracyMeters)) {
        _points.add(point);
        if (_points.length > _maxStoredPoints) {
          // Drop the oldest 25 % to avoid churning on every point.
          _points.removeRange(0, _maxStoredPoints ~/ 4);
        }
      }
    });
    isTrackingNotifier.value = true;
  }

  Future<TrackingResult?> stopTracking() async {
    final subscription = _subscription;
    _subscription = null;
    isTrackingNotifier.value = false; // update UI immediately, before await

    if (subscription != null) {
      await subscription.cancel();
    }

    final result = TrackingResult.fromPoints(
      _points,
      maxAccuracyMeters: maxAccuracyMeters,
    );
    _points.clear();
    return result;
  }
}
