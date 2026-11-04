import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/preferences/user_preferences.dart';
import 'package:route_mint_app/core/tax/tax_service.dart';

void main() {
  final base = UserPreferences.fromCountry(Country.usa);

  test('vehicle and insurance details survive a save and reload', () {
    final prefs = base.copyWith(
      vehicleMake: 'Toyota',
      vehicleModel: 'Camry',
      vehicleYear: 2021,
      vehicleLicensePlate: 'ABC 1234',
      insuranceCompanyName: 'Geico',
      insurancePolicyName: 'Full coverage',
      insurancePolicyNumber: 'P-778',
    );
    final restored = UserPreferences.fromJson(prefs.toJson());

    expect(restored.vehicleMake, 'Toyota');
    expect(restored.vehicleModel, 'Camry');
    expect(restored.vehicleYear, 2021);
    expect(restored.vehicleLicensePlate, 'ABC 1234');
    expect(restored.insuranceCompanyName, 'Geico');
    expect(restored.insurancePolicyName, 'Full coverage');
    expect(restored.insurancePolicyNumber, 'P-778');
  });

  group('vehicleDescription', () {
    test('reads year, make, model, then the plate', () {
      expect(
        base
            .copyWith(
              vehicleMake: 'Toyota',
              vehicleModel: 'Camry',
              vehicleYear: 2021,
              vehicleLicensePlate: 'ABC 1234',
            )
            .vehicleDescription,
        '2021 Toyota Camry · ABC 1234',
      );
      expect(
        base.copyWith(vehicleLicensePlate: 'ABC 1234').vehicleDescription,
        'ABC 1234',
      );
    });

    test('falls back to the old free-text name, then to nothing', () {
      expect(
        base.copyWith(vehicleName: 'My Prius').vehicleDescription,
        'My Prius',
      );
      expect(
        base
            .copyWith(vehicleName: 'My Prius', vehicleMake: 'Toyota')
            .vehicleDescription,
        'Toyota',
      );
      expect(base.vehicleDescription, isNull);
      expect(base.copyWith(vehicleName: '  ').vehicleDescription, isNull);
    });
  });

  group('feature guide flag', () {
    test('a new user has not seen the guide', () {
      expect(base.featureGuideCompleted, isFalse);
      expect(
        base.copyWith(onboardingCompleted: true).featureGuideCompleted,
        isFalse,
      );
    });

    test('people set up before the guide existed are not shown it', () {
      final json = base.copyWith(onboardingCompleted: true).toJson()
        ..remove('featureGuideCompleted');
      expect(UserPreferences.fromJson(json).featureGuideCompleted, isTrue);

      final fresh = base.toJson()..remove('featureGuideCompleted');
      expect(UserPreferences.fromJson(fresh).featureGuideCompleted, isFalse);
    });

    test('finishing or skipping is remembered', () {
      final done = base.copyWith(
        onboardingCompleted: true,
        featureGuideCompleted: true,
      );
      expect(
        UserPreferences.fromJson(done.toJson()).featureGuideCompleted,
        isTrue,
      );
    });
  });
}
