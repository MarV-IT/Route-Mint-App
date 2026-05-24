enum TripDetectionMode { manual, automatic }

enum TripReviewStatus { reviewed, needsReview }

class TripRoutePoint {
  const TripRoutePoint({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });

  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };

  factory TripRoutePoint.fromJson(Map<String, dynamic> json) => TripRoutePoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timestamp: json['timestamp'] is String
        ? _parseLocalDateTime(json['timestamp'] as String)
        : null,
  );
}

class TripTrackingDiagnostics {
  const TripTrackingDiagnostics({
    required this.rawPointCount,
    required this.validPointCount,
    required this.droppedPointCount,
    required this.averageAccuracyMeters,
    required this.maxGapSeconds,
    required this.durationSeconds,
  });

  final int rawPointCount;
  final int validPointCount;
  final int droppedPointCount;
  final double averageAccuracyMeters;
  final int maxGapSeconds;
  final int durationSeconds;

  Map<String, dynamic> toJson() => {
    'rawPointCount': rawPointCount,
    'validPointCount': validPointCount,
    'droppedPointCount': droppedPointCount,
    'averageAccuracyMeters': averageAccuracyMeters,
    'maxGapSeconds': maxGapSeconds,
    'durationSeconds': durationSeconds,
  };

  factory TripTrackingDiagnostics.fromJson(Map<String, dynamic> json) =>
      TripTrackingDiagnostics(
        rawPointCount: _intOrDefault(json['rawPointCount']),
        validPointCount: _intOrDefault(json['validPointCount']),
        droppedPointCount: _intOrDefault(json['droppedPointCount']),
        averageAccuracyMeters: _doubleOrDefault(json['averageAccuracyMeters']),
        maxGapSeconds: _intOrDefault(json['maxGapSeconds']),
        durationSeconds: _intOrDefault(json['durationSeconds']),
      );
}

class Trip {
  final String id;
  final String from;
  final String to;
  final double distance;
  final String category;
  final DateTime date;
  final String? platformName;
  final double parkingExpense;
  final double tollsExpense;
  final String? businessPurpose;
  final String? notes;
  final TripDetectionMode detectionMode;
  final TripReviewStatus reviewStatus;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final List<TripRoutePoint> routePoints;
  final TripTrackingDiagnostics? trackingDiagnostics;

  const Trip({
    required this.id,
    required this.from,
    required this.to,
    required this.distance,
    required this.category,
    required this.date,
    this.platformName,
    this.parkingExpense = 0,
    this.tollsExpense = 0,
    this.businessPurpose,
    this.notes,
    this.detectionMode = TripDetectionMode.manual,
    this.reviewStatus = TripReviewStatus.reviewed,
    this.startTime,
    this.endTime,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.routePoints = const [],
    this.trackingDiagnostics,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': from,
    'to': to,
    'distance': distance,
    'category': category,
    'date': date.toIso8601String(),
    'platformName': platformName,
    'parkingExpense': parkingExpense,
    'tollsExpense': tollsExpense,
    'businessPurpose': businessPurpose,
    'notes': notes,
    'detectionMode': detectionMode.name,
    'reviewStatus': reviewStatus.name,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'startLatitude': startLatitude,
    'startLongitude': startLongitude,
    'endLatitude': endLatitude,
    'endLongitude': endLongitude,
    'routePoints': routePoints.map((p) => p.toJson()).toList(),
    'trackingDiagnostics': trackingDiagnostics?.toJson(),
  };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final date = _parseLocalDateTime(json['date'] as String)!;
    return Trip(
      id: json['id'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      distance: (json['distance'] as num).toDouble(),
      category: json['category'] as String,
      date: date,
      platformName: _stringOrNull(json['platformName']),
      parkingExpense: _doubleOrDefault(json['parkingExpense']),
      tollsExpense: _doubleOrDefault(json['tollsExpense']),
      businessPurpose: _stringOrNull(json['businessPurpose']),
      notes: _stringOrNull(json['notes']),
      detectionMode: TripDetectionMode.values.firstWhere(
        (m) => m.name == json['detectionMode'],
        orElse: () => TripDetectionMode.manual,
      ),
      reviewStatus: TripReviewStatus.values.firstWhere(
        (s) => s.name == json['reviewStatus'],
        orElse: () => TripReviewStatus.reviewed,
      ),
      startTime: json['startTime'] is String
          ? _parseLocalDateTime(json['startTime'] as String)
          : date,
      endTime: json['endTime'] is String
          ? _parseLocalDateTime(json['endTime'] as String)
          : null,
      startLatitude: _doubleOrNull(json['startLatitude']),
      startLongitude: _doubleOrNull(json['startLongitude']),
      endLatitude: _doubleOrNull(json['endLatitude']),
      endLongitude: _doubleOrNull(json['endLongitude']),
      routePoints: _parseRoutePoints(json['routePoints']),
      trackingDiagnostics: _parseTrackingDiagnostics(
        json['trackingDiagnostics'],
      ),
    );
  }

  Trip copyWith({
    String? id,
    String? from,
    String? to,
    double? distance,
    String? category,
    DateTime? date,
    Object? platformName = _sentinel,
    double? parkingExpense,
    double? tollsExpense,
    Object? businessPurpose = _sentinel,
    Object? notes = _sentinel,
    TripDetectionMode? detectionMode,
    TripReviewStatus? reviewStatus,
    Object? startTime = _sentinel,
    Object? endTime = _sentinel,
    Object? startLatitude = _sentinel,
    Object? startLongitude = _sentinel,
    Object? endLatitude = _sentinel,
    Object? endLongitude = _sentinel,
    List<TripRoutePoint>? routePoints,
    Object? trackingDiagnostics = _sentinel,
  }) => Trip(
    id: id ?? this.id,
    from: from ?? this.from,
    to: to ?? this.to,
    distance: distance ?? this.distance,
    category: category ?? this.category,
    date: date ?? this.date,
    platformName: platformName == _sentinel
        ? this.platformName
        : platformName as String?,
    parkingExpense: parkingExpense ?? this.parkingExpense,
    tollsExpense: tollsExpense ?? this.tollsExpense,
    businessPurpose: businessPurpose == _sentinel
        ? this.businessPurpose
        : businessPurpose as String?,
    notes: notes == _sentinel ? this.notes : notes as String?,
    detectionMode: detectionMode ?? this.detectionMode,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    startTime: startTime == _sentinel ? this.startTime : startTime as DateTime?,
    endTime: endTime == _sentinel ? this.endTime : endTime as DateTime?,
    startLatitude: startLatitude == _sentinel
        ? this.startLatitude
        : startLatitude as double?,
    startLongitude: startLongitude == _sentinel
        ? this.startLongitude
        : startLongitude as double?,
    endLatitude: endLatitude == _sentinel
        ? this.endLatitude
        : endLatitude as double?,
    endLongitude: endLongitude == _sentinel
        ? this.endLongitude
        : endLongitude as double?,
    routePoints: routePoints ?? this.routePoints,
    trackingDiagnostics: trackingDiagnostics == _sentinel
        ? this.trackingDiagnostics
        : trackingDiagnostics as TripTrackingDiagnostics?,
  );

  @override
  String toString() =>
      'Trip(id: $id, from: $from, to: $to, distance: $distance, '
      'category: $category, date: $date, platformName: $platformName, '
      'detectionMode: $detectionMode, reviewStatus: $reviewStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Sentinel for copyWith to distinguish null from "not provided"
const Object _sentinel = Object();

String? _stringOrNull(Object? value) => value is String ? value : null;

double _doubleOrDefault(Object? value) => value is num ? value.toDouble() : 0;

double? _doubleOrNull(Object? value) => value is num ? value.toDouble() : null;

int _intOrDefault(Object? value) => value is num ? value.toInt() : 0;

List<TripRoutePoint> _parseRoutePoints(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(TripRoutePoint.fromJson)
      .toList(growable: false);
}

TripTrackingDiagnostics? _parseTrackingDiagnostics(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  return TripTrackingDiagnostics.fromJson(value);
}

DateTime? _parseLocalDateTime(String value) =>
    DateTime.tryParse(value)?.toLocal();
