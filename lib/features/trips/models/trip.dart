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
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        distance: (json['distance'] as num).toDouble(),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        platformName: json['platformName'] as String?,
        parkingExpense: (json['parkingExpense'] as num?)?.toDouble() ?? 0,
        tollsExpense: (json['tollsExpense'] as num?)?.toDouble() ?? 0,
        businessPurpose: json['businessPurpose'] as String?,
        notes: json['notes'] as String?,
      );

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
  }) =>
      Trip(
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
      );

  @override
  String toString() =>
      'Trip(id: $id, from: $from, to: $to, distance: $distance, '
      'category: $category, date: $date, platformName: $platformName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Sentinel for copyWith to distinguish null from "not provided"
const Object _sentinel = Object();
