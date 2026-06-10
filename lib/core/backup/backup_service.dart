import 'dart:convert';
import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../preferences/preferences_service.dart';
import '../preferences/user_preferences.dart';
import '../../features/trips/models/trip.dart';
import '../../features/trips/services/trip_service.dart';
import '../../features/expenses/models/expense_entry.dart';
import '../../features/expenses/services/expense_service.dart';
import '../../features/fuel/models/fuel_entry.dart';
import '../../features/fuel/services/fuel_service.dart';
import '../../features/work_mode/models/work_mode_settings.dart';
import '../../features/work_mode/services/work_mode_service.dart';

class BackupService {
  static const _appName = 'MarV Route';
  // Legacy name accepted on import for backward compatibility.
  static const _appNameLegacy = 'Route Mint';
  static const _backupVersion = 1;

  final _prefsService = PreferencesService();
  final _tripService = TripService();
  final _expenseService = ExpenseService();
  final _fuelService = FuelService();
  final _workModeService = WorkModeService();

  // ─── Export ───────────────────────────────────────────────────────────────

  Future<void> exportBackup() async {
    final preferences = await _prefsService.loadPreferences();
    final trips = await _tripService.loadTrips();
    final expenseEntries = await _expenseService.loadExpenseEntries();
    final fuelEntries = await _fuelService.loadFuelEntries();
    final workModeSettings = await _workModeService.loadSettings();

    final data = <String, dynamic>{
      'appName': _appName,
      'backupVersion': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'preferences': preferences.toJson(),
      'trips': trips.map((t) => t.toJson()).toList(),
      'expenseEntries': expenseEntries.map((e) => e.toJson()).toList(),
      'fuelEntries': fuelEntries.map((e) => e.toJson()).toList(),
      'workModeSettings': workModeSettings.toJson(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    final bytes = Uint8List.fromList(utf8.encode(encoder.convert(data)));

    final now = DateTime.now();
    final slug =
        '${now.year}_'
        '${now.month.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}';

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'marv_route_backup_$slug.json',
    );
  }

  // ─── Import ───────────────────────────────────────────────────────────────

  /// Decodes, validates, and restores a backup JSON string.
  /// Throws [FormatException] for invalid/unsupported files.
  Future<void> importBackup(String jsonString) async {
    final decoded = decodeAndValidateBackupJson(jsonString);

    final prefsJson = decoded['preferences'];
    if (prefsJson is Map) {
      await _prefsService.savePreferences(
        UserPreferences.fromJson(Map<String, dynamic>.from(prefsJson)),
      );
    }

    final tripsJson = decoded['trips'];
    if (tripsJson is List<dynamic>) {
      final trips = <Trip>[];
      for (final item in tripsJson) {
        if (item is! Map) continue;
        try {
          trips.add(Trip.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Skip malformed entries without aborting the restore.
        }
      }
      await _tripService.saveTrips(trips);
    }

    final workJson = decoded['workModeSettings'];
    if (workJson is Map) {
      await _workModeService.saveSettings(
        WorkModeSettings.fromJson(Map<String, dynamic>.from(workJson)),
      );
    }

    final fuelJson = decoded['fuelEntries'];
    if (fuelJson is List<dynamic>) {
      final fuelEntries = <FuelEntry>[];
      for (final item in fuelJson) {
        if (item is! Map) continue;
        try {
          fuelEntries.add(FuelEntry.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Skip malformed entries without aborting the restore.
        }
      }
      await _fuelService.saveFuelEntries(fuelEntries);
    }

    final expenseJson = decoded['expenseEntries'];
    if (expenseJson is List<dynamic>) {
      final expenseEntries = <ExpenseEntry>[];
      for (final item in expenseJson) {
        if (item is! Map) continue;
        try {
          expenseEntries.add(
            ExpenseEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          // Skip malformed entries without aborting the restore.
        }
      }
      await _expenseService.saveExpenseEntries(expenseEntries);
    }
  }

  static Map<String, dynamic> decodeAndValidateBackupJson(String jsonString) {
    final Map<String, dynamic> decoded;
    try {
      final raw = jsonDecode(jsonString);
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid backup format');
      }
      decoded = raw;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('File is not valid JSON');
    }

    final appName = decoded['appName'];
    if (appName is String && appName != _appName && appName != _appNameLegacy) {
      throw const FormatException('Not a MarV Route backup file');
    }

    final version = decoded['backupVersion'];
    if (version != null && version is! int) {
      throw const FormatException('Invalid backup version');
    }
    if (version is int && version > _backupVersion) {
      throw FormatException('Backup version $version is not supported');
    }

    return decoded;
  }
}
