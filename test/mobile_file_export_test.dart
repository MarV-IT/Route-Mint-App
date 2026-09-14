import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/backup/backup_service.dart';
import 'package:route_mint_app/core/export/csv_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Picker extends FilePicker {
  String? fileName;
  List<String>? extensions;
  Uint8List? bytes;
  bool cancelled = false;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    this.fileName = fileName;
    extensions = allowedExtensions;
    this.bytes = bytes;
    return cancelled ? null : fileName;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Picker picker;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    picker = _Picker();
    FilePicker.platform = picker;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test(
      '$platform exports real JSON bytes through the system file picker',
      () async {
        debugDefaultTargetPlatformOverride = platform;
        expect(await BackupService().exportBackup(), isTrue);
        expect(picker.fileName, endsWith('.json'));
        expect(picker.extensions, ['json']);
        expect(jsonDecode(utf8.decode(picker.bytes!))['appName'], 'MarV Route');
      },
    );
    test('$platform exports CSV with its correct extension', () async {
      debugDefaultTargetPlatformOverride = platform;
      await CsvExportService().exportTrips(
        trips: [],
        unit: AppUnit.kilometers,
        currencyCode: 'USD',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 13),
      );
      expect(picker.fileName, endsWith('.csv'));
      expect(picker.extensions, ['csv']);
      expect(utf8.decode(picker.bytes!), startsWith('Date,From,To,'));
    });
  }
  test('cancelling backup export reports no file saved', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    picker.cancelled = true;
    expect(await BackupService().exportBackup(), isFalse);
  });
}
