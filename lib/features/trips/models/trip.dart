enum TripDetectionMode { manual, automatic }

enum TripReviewStatus { reviewed, needsReview }

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
  };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
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
          ? DateTime.tryParse(json['startTime'] as String)
          : date,
      endTime: json['endTime'] is String
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
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
