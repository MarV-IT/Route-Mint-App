import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/auth/account_deletion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountDeletionService.clearLocalData', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('removes every account-owned key', () async {
      SharedPreferences.setMockInitialValues({
        for (final key in AccountDeletionService.localDataKeys) key: 'value',
      });

      await AccountDeletionService().clearLocalData();

      final prefs = await SharedPreferences.getInstance();
      for (final key in AccountDeletionService.localDataKeys) {
        expect(prefs.get(key), isNull, reason: '$key survived deletion');
      }
    });

    test('covers the storage keys used across the app', () {
      // Guards against a feature persisting data under a key that account
      // deletion then leaves behind on the device.
      expect(
        AccountDeletionService.localDataKeys,
        containsAll(<String>[
          'user_preferences',
          'trips',
          'expense_entries',
          'fuel_entries',
          'work_mode_settings',
          'app_unit',
          'app_language',
          'app_country',
        ]),
      );
    });

    test('leaves unrelated keys untouched', () async {
      SharedPreferences.setMockInitialValues({
        'trips': 'value',
        'some_cache_key': 'keep me',
      });

      await AccountDeletionService().clearLocalData();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get('trips'), isNull);
      expect(prefs.get('some_cache_key'), 'keep me');
    });
  });
}
