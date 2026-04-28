import 'dart:async';

import 'tracking_result.dart';

typedef TrackingPointStreamFactory = Stream<TrackingPoint> Function();

class ForegroundTripTrackingService {
  ForegroundTripTrackingService({
    TrackingPointStreamFactory? pointStreamFactory,
    this.maxAccuracyMeters = TrackingResult.defaultMaxAccuracyMeters,
  }) : _pointStreamFactory = pointStreamFactory;

  final TrackingPointStreamFactory? _pointStreamFactory;
  final double maxAccuracyMeters;

  final List<TrackingPoint> _points = [];
  StreamSubscription<TrackingPoint>? _subscription;

  bool get isTracking => _subscription != null;

  void startTracking({TrackingPointStreamFactory? pointStreamFactory}) {
    if (isTracking) {
      return;
    }

    final factory = pointStreamFactory ?? _pointStreamFactory;
    if (factory == null) {
      throw StateError('A tracking point stream factory is required.');
    }

    _points.clear();
    _subscription = factory().listen((point) {
      if (point.isAccurateEnough(maxAccuracyMeters)) {
        _points.add(point);
      }
    });
  }

  Future<TrackingResult?> stopTracking() async {
    final subscription = _subscription;
    _subscription = null;

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
