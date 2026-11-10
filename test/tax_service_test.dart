import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/tax/tax_service.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/trip_deduction.dart';

const _kmPerMile = 1 / 0.621371;

void main() {
  final tax = TaxService();

  group('IRS rates', () {
    test('follow the published table, including the July 2026 rise', () {
      expect(tax.usaRatePerMile(DateTime(2024, 5, 1)), 0.67);
      expect(tax.usaRatePerMile(DateTime(2025, 12, 31, 23)), 0.70);
      expect(tax.usaRatePerMile(DateTime(2026, 1, 1)), 0.725);
      expect(tax.usaRatePerMile(DateTime(2026, 6, 30, 23, 59)), 0.725);
      expect(tax.usaRatePerMile(DateTime(2026, 7, 1)), 0.76);
      expect(tax.usaRatePerMile(DateTime(2026, 11, 4)), 0.76);
    });

    test('dates outside the table use the nearest known rate', () {
      expect(tax.usaRatePerMile(DateTime(2019)), 0.655);
      expect(tax.usaRatePerMile(DateTime(2030)), 0.76);
    });

    test('each trip is paid at the rate of its own date', () {
      final deduction = tax.calculateTaxForTrips([
        (date: DateTime(2026, 6, 15), km: 100 * _kmPerMile),
        (date: DateTime(2026, 7, 15), km: 100 * _kmPerMile),
      ], Country.usa);
      expect(deduction, closeTo(72.5 + 76, 1e-6));
    });
  });

  group('CRA rates', () {
    test('match the published years', () {
      expect(tax.canadaRates(2025), (firstTier: 0.72, afterTier: 0.66));
      expect(tax.canadaRates(2026), (firstTier: 0.73, afterTier: 0.67));
      expect(tax.canadaRates(2031), (firstTier: 0.73, afterTier: 0.67));
      expect(tax.canadaRates(2020), (firstTier: 0.68, afterTier: 0.62));
    });

    test('the lower rate starts after 5,000 km in the year', () {
      final deduction = tax.calculateTaxForTrips([
        (date: DateTime(2026, 2, 1), km: 4000),
        (date: DateTime(2026, 3, 1), km: 3000),
      ], Country.canada);
      expect(deduction, closeTo(5000 * 0.73 + 2000 * 0.67, 1e-6));
    });

    test('each calendar year has its own 5,000 km and its own rates', () {
      final deduction = tax.calculateTaxForTrips([
        (date: DateTime(2025, 12, 20), km: 6000),
        (date: DateTime(2026, 1, 5), km: 1000),
      ], Country.canada);
      expect(deduction, closeTo(5000 * 0.72 + 1000 * 0.66 + 1000 * 0.73, 1e-6));
    });
  });

  test('a single distance uses the rate of the given day', () {
    expect(
      tax.calculateTaxFromKm(
        10 * _kmPerMile,
        Country.usa,
        on: DateTime(2025, 3, 1),
      ),
      closeTo(7.0, 1e-6),
    );
    expect(tax.calculateTaxFromKm(0, Country.canada), 0);
  });

  test('only the United States gets a deduction estimate', () {
    // Canada's per-kilometre figures are employer allowance limits, not a
    // deduction a self-employed driver can claim, so no amount is shown.
    expect(TaxService.showsDeductionEstimate(Country.usa), isTrue);
    expect(TaxService.showsDeductionEstimate(Country.canada), isFalse);
  });

  test('only business trips count toward the deduction', () {
    Trip trip(String category, DateTime date) => Trip(
      id: '$category$date',
      from: 'A',
      to: 'B',
      distance: 10,
      category: category,
      date: date,
    );
    final distances = businessDistances([
      trip('business', DateTime(2026, 7, 2)),
      trip('personal', DateTime(2026, 7, 3)),
    ]).toList();
    expect(distances, [(date: DateTime(2026, 7, 2), km: 10.0)]);
  });
}
