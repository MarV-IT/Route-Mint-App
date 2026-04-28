import 'dart:math' as math;

class TrackingPoint {
  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;

  bool isAccurateEnough(double maxAccuracyMeters) =>
      accuracyMeters.isFinite && accuracyMeters <= maxAccuracyMeters;
}

class TrackingResult {
  const TrackingResult({
    required this.points,
    required this.distanceKm,
    required this.startedAt,
    required this.endedAt,
  });

  final List<TrackingPoint> points;
  final double distanceKm;
  final DateTime startedAt;
  final DateTime endedAt;

  static const double defaultMaxAccuracyMeters = 100;
  static const double defaultMinimumDistanceKm = 0.2;

  static TrackingResult? fromPoints(
    Iterable<TrackingPoint> points, {
    double maxAccuracyMeters = defaultMaxAccuracyMeters,
    double minimumDistanceKm = defaultMinimumDistanceKm,
  }) {
    final validPoints = points
        .where((point) => point.isAccurateEnough(maxAccuracyMeters))
        .toList(growable: false);

    if (validPoints.length < 2) {
      return null;
    }

    final distanceKm = calculateDistanceKm(validPoints);
    if (distanceKm < minimumDistanceKm) {
      return null;
    }

    return TrackingResult(
      points: validPoints,
      distanceKm: distanceKm,
      startedAt: validPoints.first.timestamp,
      endedAt: validPoints.last.timestamp,
    );
  }

  static double calculateDistanceKm(List<TrackingPoint> points) {
    if (points.length < 2) {
      return 0;
    }

    var distanceKm = 0.0;
    for (var i = 1; i < points.length; i++) {
      distanceKm += distanceBetweenKm(points[i - 1], points[i]);
    }
    return distanceKm;
  }

  static double distanceBetweenKm(TrackingPoint start, TrackingPoint end) {
    const earthRadiusKm = 6371.0088;
    final lat1 = _degreesToRadians(start.latitude);
    final lat2 = _degreesToRadians(end.latitude);
    final deltaLat = _degreesToRadians(end.latitude - start.latitude);
    final deltaLon = _degreesToRadians(end.longitude - start.longitude);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
