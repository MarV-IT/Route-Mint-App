import 'dart:convert';
import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../../app/app.dart';
import '../../features/trips/models/trip.dart';
import '../../shared/utils/distance_utils.dart';

class CsvExportService {
  static const _headers = [
    'Date', 'From', 'To', 'Category', 'Platform',
    'Distance', 'Distance Unit', 'Parking', 'Tolls',
    'Currency', 'Business Purpose', 'Notes',
  ];

  Future<void> exportTrips({
    required List<Trip> trips,
    required AppUnit unit,
    required String currencyCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final rows = <List<String>>[_headers];

    for (final trip in trips) {
      final distValue = fromKilometers(trip.distance, unit);
      final distUnit = unit == AppUnit.kilometers ? 'km' : 'mi';
      rows.add([
        _fmtDate(trip.date),
        trip.from,
        trip.to,
        trip.category,
        trip.platformName ?? '',
        distValue.toStringAsFixed(2),
        distUnit,
        trip.parkingExpense.toStringAsFixed(2),
        trip.tollsExpense.toStringAsFixed(2),
        currencyCode,
        trip.businessPurpose ?? '',
        trip.notes ?? '',
      ]);
    }

    final csv = rows.map(_encodeCsvRow).join('\r\n');
    final bytes = Uint8List.fromList(utf8.encode(csv));

    await Printing.sharePdf(
      bytes: bytes,
      filename: _buildFilename(startDate, endDate),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _encodeCsvRow(List<String> fields) =>
      fields.map(_escapeField).join(',');

  String _escapeField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String _buildFilename(DateTime startDate, DateTime endDate) {
    const months = [
      '', 'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december',
    ];
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return 'marv_route_trips_${months[startDate.month]}_${startDate.year}.csv';
    }
    final s = '${startDate.year}_${startDate.month.toString().padLeft(2, '0')}_${startDate.day.toString().padLeft(2, '0')}';
    final e = '${endDate.year}_${endDate.month.toString().padLeft(2, '0')}_${endDate.day.toString().padLeft(2, '0')}';
    return 'marv_route_trips_${s}_to_$e.csv';
  }
}
