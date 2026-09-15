import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/auth/account_deletion_service.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountDeletionService.clearLocalData', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      AccountDataStore.resetForTesting();
    });

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

    test(
      'late deletion clears only its owner and preserves the new session',
      () async {
        SharedPreferences.setMockInitialValues({'trips': 'legacy A trips'});
        await AccountDataStore.activate('A', claimLegacy: true);
        final owner = AccountDataStore.current;
        final deletion = AccountDeletionService();
        await AccountDataStore.activate('B');
        final other = await AccountDataStore.current.getPreferences();
        await other.setString('trips', 'B trips');
        final raw = await SharedPreferences.getInstance();
        await raw.setBool('firebase_auth_session_expected', true);
        const credentials = FlutterSecureStorage();
        await credentials.write(key: 'auth_email', value: 'b@example.com');

        await deletion.clearLocalData();

        expect((await owner.getPreferences()).getString('trips'), isNull);
        expect(raw.getString('trips'), isNull);
        expect(other.getString('trips'), 'B trips');
        expect(raw.getBool('firebase_auth_session_expected'), isTrue);
        expect(await credentials.read(key: 'auth_email'), 'b@example.com');
        await AccountDataStore.activate('A');
        expect(
          (await AccountDataStore.current.getPreferences()).getString('trips'),
          isNull,
        );
      },
    );
  });
}
