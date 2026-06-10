class FuelEntry {
  const FuelEntry({
    required this.id,
    required this.date,
    required this.volumeLiters,
    required this.totalCost,
    this.odometerKm,
    this.stationName,
    this.notes,
  });

  final String id;
  final DateTime date;
  final double? odometerKm;
  final double volumeLiters;
  final double totalCost;
  final String? stationName;
  final String? notes;

  double get pricePerLiter => volumeLiters > 0 ? totalCost / volumeLiters : 0;

  double get pricePerGallon => pricePerLiter * 3.785411784;

  double? costPerKm(double? previousOdometerKm) {
    if (odometerKm == null || previousOdometerKm == null) return null;
    final distance = odometerKm! - previousOdometerKm;
    return distance > 0 ? totalCost / distance : null;
  }

  double? costPerMile(double? previousOdometerKm) {
    final perKm = costPerKm(previousOdometerKm);
    return perKm == null ? null : perKm / 0.621371;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'odometerKm': odometerKm,
    'volumeLiters': volumeLiters,
    'totalCost': totalCost,
    'stationName': stationName,
    'notes': notes,
  };

  factory FuelEntry.fromJson(Map<String, dynamic> json) => FuelEntry(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String).toLocal(),
    odometerKm: _doubleOrNull(json['odometerKm']),
    volumeLiters: (json['volumeLiters'] as num).toDouble(),
    totalCost: (json['totalCost'] as num).toDouble(),
    stationName: _stringOrNull(json['stationName']),
    notes: _stringOrNull(json['notes']),
  );

  FuelEntry copyWith({
    String? id,
    DateTime? date,
    Object? odometerKm = _sentinel,
    double? volumeLiters,
    double? totalCost,
    Object? stationName = _sentinel,
    Object? notes = _sentinel,
  }) => FuelEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    odometerKm: odometerKm == _sentinel
        ? this.odometerKm
        : odometerKm as double?,
    volumeLiters: volumeLiters ?? this.volumeLiters,
    totalCost: totalCost ?? this.totalCost,
    stationName: stationName == _sentinel
        ? this.stationName
        : stationName as String?,
    notes: notes == _sentinel ? this.notes : notes as String?,
  );
}

const Object _sentinel = Object();

double? _doubleOrNull(Object? value) => value is num ? value.toDouble() : null;

String? _stringOrNull(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
