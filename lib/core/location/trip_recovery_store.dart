import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tracking_result.dart';

/// A trip that was still being recorded when the app stopped running.
class InterruptedTrip {
  const InterruptedTrip({
    required this.points,
    required this.carriedDistanceKm,
    required this.startedAt,
    required this.rawPointCount,
    required this.droppedPointCount,
  });

  final List<TrackingPoint> points;
  final double carriedDistanceKm;
  final DateTime startedAt;
  final int rawPointCount;
  final int droppedPointCount;
}

/// Keeps the trip currently being recorded on disk.
///
/// Detection used to hold an in-progress trip only in memory, so when the OS
/// reclaimed the app — routine on a long delivery block with another app in
/// front — hours of tracking disappeared with no error and no trace. The
/// checkpoint written here lets the next launch finish that trip instead.
class TripRecoveryStore {
  static const _tripKey = 'auto_detection_active_trip';
  static const _monitoringKey = 'auto_detection_monitoring';

  /// Points are written at most this often; a checkpoint on every GPS fix
  /// would mean disk writes every few metres.
  static const checkpointInterval = Duration(seconds: 30);

  Future<void> saveCheckpoint({
    required List<TrackingPoint> points,
    required double carriedDistanceKm,
    required DateTime startedAt,
    required int rawPointCount,
    required int droppedPointCount,
  }) async {
    if (points.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _tripKey,
        jsonEncode({
          'startedAt': startedAt.toIso8601String(),
          'carriedDistanceKm': carriedDistanceKm,
          'rawPointCount': rawPointCount,
          'droppedPointCount': droppedPointCount,
          'points': points.map((p) => p.toJson()).toList(),
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripRecovery] checkpoint failed: $e');
      }
    }
  }

  Future<InterruptedTrip?> loadCheckpoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tripKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final startedAt = DateTime.tryParse(
        decoded['startedAt'] as String? ?? '',
      );
      if (startedAt == null) return null;

      final rawPoints = decoded['points'];
      if (rawPoints is! List) return null;

      final points = <TrackingPoint>[];
      for (final item in rawPoints) {
        if (item is! Map) continue;
        final point = TrackingPoint.fromJson(Map<String, dynamic>.from(item));
        if (point != null) points.add(point);
      }
      if (points.isEmpty) return null;

      final carried = decoded['carriedDistanceKm'];
      final rawCount = decoded['rawPointCount'];
      final droppedCount = decoded['droppedPointCount'];

      return InterruptedTrip(
        points: points,
        carriedDistanceKm: carried is num ? carried.toDouble() : 0,
        startedAt: startedAt,
        rawPointCount: rawCount is num ? rawCount.toInt() : points.length,
        droppedPointCount: droppedCount is num ? droppedCount.toInt() : 0,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripRecovery] checkpoint unreadable: $e');
      }
      return null;
    }
  }

  Future<void> clearCheckpoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tripKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripRecovery] clear failed: $e');
      }
    }
  }

  /// Whether detection was running when the app last stopped. Used to bring
  /// monitoring back after a restart the user did not ask for.
  Future<void> setMonitoring(bool monitoring) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_monitoringKey, monitoring);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripRecovery] monitoring flag not saved: $e');
      }
    }
  }

  Future<bool> wasMonitoring() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_monitoringKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripRecovery] monitoring flag unreadable: $e');
      }
      return false;
    }
  }
}
