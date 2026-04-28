import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/backup/backup_service.dart';

void main() {
  group('BackupService validation', () {
    test('throws FormatException for malformed JSON', () {
      expect(
        () => BackupService.decodeAndValidateBackupJson('{not valid json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for unsupported backupVersion', () {
      final backup = jsonEncode({
        'appName': 'Route Mint',
        'backupVersion': 999,
      });

      expect(
        () => BackupService.decodeAndValidateBackupJson(backup),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for malformed backupVersion', () {
      final backup = jsonEncode({
        'appName': 'Route Mint',
        'backupVersion': '2',
      });

      expect(
        () => BackupService.decodeAndValidateBackupJson(backup),
        throwsA(isA<FormatException>()),
      );
    });

    test('accepts current backupVersion', () {
      final backup = jsonEncode({
        'appName': 'Route Mint',
        'backupVersion': 1,
        'preferences': <String, dynamic>{},
        'trips': <dynamic>[],
        'workModeSettings': <String, dynamic>{},
      });

      final decoded = BackupService.decodeAndValidateBackupJson(backup);

      expect(decoded['backupVersion'], 1);
    });
  });
}
