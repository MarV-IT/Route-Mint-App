import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/trip_purpose.dart';

Trip tripWith({
  String category = 'business',
  String? platformName,
  String? businessPurpose,
}) => Trip(
  id: 't1',
  from: 'A',
  to: 'B',
  distance: 8.4,
  category: category,
  date: DateTime(2026, 7, 9),
  platformName: platformName,
  businessPurpose: businessPurpose,
);

void main() {
  final english = AppStrings(AppLanguage.english);
  final ukrainian = AppStrings(AppLanguage.ukrainian);

  group('displayBusinessPurpose', () {
    test('derives the purpose in the active language when none is stored', () {
      final trip = tripWith(platformName: 'Amazon Flex');

      expect(
        displayBusinessPurpose(trip, english),
        'Amazon Flex business trip',
      );
      expect(
        displayBusinessPurpose(trip, ukrainian),
        'Робоча поїздка Amazon Flex',
      );
    });

    test('re-derives wording frozen by an older version (regression)', () {
      // Saved while the app was in Ukrainian, then switched to English.
      final trip = tripWith(
        platformName: 'Amazon Flex',
        businessPurpose: 'Робоча поїздка Amazon Flex',
      );

      expect(
        displayBusinessPurpose(trip, english),
        'Amazon Flex business trip',
      );
    });

    test('re-derives a frozen platform-less purpose', () {
      final trip = tripWith(businessPurpose: 'Рабочая поездка');

      expect(displayBusinessPurpose(trip, english), 'Business trip');
    });

    test('keeps text the user typed verbatim', () {
      final trip = tripWith(
        platformName: 'Amazon Flex',
        businessPurpose: 'Delivery block, warehouse BOI3',
      );

      expect(
        displayBusinessPurpose(trip, english),
        'Delivery block, warehouse BOI3',
      );
      expect(
        displayBusinessPurpose(trip, ukrainian),
        'Delivery block, warehouse BOI3',
      );
    });

    test('falls back to the plain wording without a platform', () {
      expect(displayBusinessPurpose(tripWith(), english), 'Business trip');
    });

    test('shows nothing for a personal trip with no stored purpose', () {
      expect(displayBusinessPurpose(tripWith(category: 'personal'), english), isNull);
    });

    test('keeps a user purpose on a personal trip', () {
      final trip = tripWith(category: 'personal', businessPurpose: 'Moving day');

      expect(displayBusinessPurpose(trip, english), 'Moving day');
    });
  });

  group('isGeneratedPurpose', () {
    test('recognises generated wording in every supported language', () {
      for (final language in AppLanguage.values) {
        final strings = AppStrings(language);
        expect(
          isGeneratedPurpose(strings.businessTrip, null),
          isTrue,
          reason: 'plain wording for $language',
        );
        expect(
          isGeneratedPurpose(strings.platformBusinessTrip('Uber'), 'Uber'),
          isTrue,
          reason: 'platform wording for $language',
        );
      }
    });

    test('does not mistake user text for generated wording', () {
      expect(isGeneratedPurpose('Client meeting downtown', 'Uber'), isFalse);
      expect(isGeneratedPurpose('', null), isFalse);
    });
  });
}
