import 'dart:math' as math;

enum TrackingFailureReason {
  /// GPS stream produced zero points that passed the accuracy filter.
  noAccuratePoints,

  /// Only one accurate point was collected — need at least two.
  tooFewPoints,

  /// Enough accurate points, but the total distance is below the minimum.
  distanceTooShort,
}

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
    required this.rawPointCount,
    required this.validPointCount,
    required this.droppedPointCount,
    required this.averageAccuracyMeters,
    required this.maxGapSeconds,
  });

  final List<TrackingPoint> points;
  final double distanceKm;
  final DateTime startedAt;
  final DateTime endedAt;
  final int rawPointCount;
  final int validPointCount;
  final int droppedPointCount;
  final double averageAccuracyMeters;
  final int maxGapSeconds;

  // 200 m gives reliable results on real devices; tighter values reject
  // too many points when the phone uses network/cell-tower positioning.
  static const double defaultMaxAccuracyMeters = 200;
  static const double defaultMinimumDistanceKm = 0.2;
  // Ignore tiny GPS jitter while keeping dense enough points to follow turns.
  // The route simplifier also collapses short back-and-forth drift while parked.
  static const double defaultMinimumSegmentDistanceMeters = 5;

  static TrackingResult? fromPoints(
    Iterable<TrackingPoint> points, {
    double maxAccuracyMeters = defaultMaxAccuracyMeters,
    double minimumDistanceKm = defaultMinimumDistanceKm,
    double minimumSegmentDistanceMeters = defaultMinimumSegmentDistanceMeters,
    int? rawPointCountOverride,
    int? droppedPointCountOverride,
  }) {
    final rawPoints = points.toList(growable: false);
    final validPoints = rawPoints
        .where((point) => point.isAccurateEnough(maxAccuracyMeters))
        .toList(growable: false);

    if (validPoints.length < 2) {
      return null;
    }

    final routePoints = simplifyRoutePoints(
      validPoints,
      minimumSegmentDistanceMeters: minimumSegmentDistanceMeters,
    );
    if (routePoints.length < 2) {
      return null;
    }

    final distanceKm = calculateDistanceKm(routePoints);
    if (distanceKm < minimumDistanceKm) {
      return null;
    }

    return TrackingResult(
      points: routePoints,
      distanceKm: distanceKm,
      startedAt: validPoints.first.timestamp,
      endedAt: validPoints.last.timestamp,
      rawPointCount: rawPointCountOverride ?? rawPoints.length,
      validPointCount: validPoints.length,
      droppedPointCount:
          droppedPointCountOverride ?? rawPoints.length - validPoints.length,
      averageAccuracyMeters: _averageAccuracy(validPoints),
      maxGapSeconds: _maxGapSeconds(validPoints),
    );
  }

  static List<TrackingPoint> simplifyRoutePoints(
    List<TrackingPoint> points, {
    double minimumSegmentDistanceMeters = defaultMinimumSegmentDistanceMeters,
  }) {
    if (points.length < 2) {
      return points;
    }

    final simplified = <TrackingPoint>[points.first];
    for (var i = 1; i < points.length; i++) {
      final point = points[i];
      final segmentMeters = distanceBetweenKm(simplified.last, point) * 1000;
      if (segmentMeters < minimumSegmentDistanceMeters) {
        continue;
      }

      if (simplified.length >= 2) {
        final previousAnchor = simplified[simplified.length - 2];
        final backtrackMeters = distanceBetweenKm(previousAnchor, point) * 1000;
        if (backtrackMeters < minimumSegmentDistanceMeters) {
          simplified.removeLast();
          continue;
        }
      }

      simplified.add(point);
    }
    return List<TrackingPoint>.unmodifiable(simplified);
  }

  static double calculateDistanceKm(
    List<TrackingPoint> points, {
    double minimumSegmentDistanceMeters = 0,
  }) {
    final routePoints = simplifyRoutePoints(
      points,
      minimumSegmentDistanceMeters: minimumSegmentDistanceMeters,
    );
    if (routePoints.length < 2) {
      return 0;
    }

    var distanceKm = 0.0;
    for (var i = 1; i < routePoints.length; i++) {
      distanceKm += distanceBetweenKm(routePoints[i - 1], routePoints[i]);
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

  static double _averageAccuracy(List<TrackingPoint> points) {
    if (points.isEmpty) return 0;
    final total = points.fold<double>(
      0,
      (sum, point) => sum + point.accuracyMeters,
    );
    return total / points.length;
  }

  static int _maxGapSeconds(List<TrackingPoint> points) {
    if (points.length < 2) return 0;
    var maxGap = 0;
    for (var i = 1; i < points.length; i++) {
      final gap = points[i].timestamp
          .difference(points[i - 1].timestamp)
          .inSeconds
          .abs();
      if (gap > maxGap) maxGap = gap;
    }
    return maxGap;
  }
}
