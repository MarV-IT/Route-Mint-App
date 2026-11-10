enum Country { usa, canada }

/// A business distance on a given day, the unit the deduction is worked out
/// from.
typedef DatedDistance = ({DateTime date, double km});

/// Mileage deduction at the official per-distance rates.
///
/// Rates change by date — the IRS even changed its 2026 rate in July — so a
/// deduction is worked out from each trip's date, not from today's rate.
/// When a new rate is announced, add it to the tables below; dates after the
/// newest entry keep using it until then.
class TaxService {
  /// Whether the app shows a deduction estimate for [country].
  ///
  /// Only the United States has a standard mileage rate that a self-employed
  /// driver can deduct. In Canada the self-employed claim the business share
  /// of their actual vehicle expenses, and the per-kilometre figures below are
  /// limits for allowances an employer pays to an employee. Presenting them
  /// as a deduction would mislead, so for Canada the app keeps the kilometer
  /// log and shows no amount.
  static bool showsDeductionEstimate(Country country) => country == Country.usa;

  // ─── Rate tables ──────────────────────────────────────────────────────────

  /// IRS business standard mileage rates, oldest first, each in force from
  /// [from] until the next entry.
  /// https://www.irs.gov/tax-professionals/standard-mileage-rates
  static final List<({DateTime from, double perMile})> _usaRates = [
    (from: DateTime(2023), perMile: 0.655), // IR-2022-234
    (from: DateTime(2024), perMile: 0.67), // IR-2023-239
    (from: DateTime(2025), perMile: 0.70), // IR-2024-312
    (from: DateTime(2026), perMile: 0.725), // IR-2025-128
    (from: DateTime(2026, 7), perMile: 0.76), // IR-2026-29, mid-year rise
  ];

  /// CRA per-kilometre allowance limits for the provinces, by calendar year:
  /// one rate for the first 5,000 km of the year and a lower one after.
  /// Kept for reference only: nothing in the app shows an amount worked out
  /// from them (see [showsDeductionEstimate]).
  /// https://www.canada.ca/en/department-finance/news/2026/01/government-announces-the-2026-automobile-deduction-limits-and-expense-benefit-rates-for-businesses.html
  static const Map<int, ({double firstTier, double afterTier})> _canadaRates = {
    2023: (firstTier: 0.68, afterTier: 0.62),
    2024: (firstTier: 0.70, afterTier: 0.64),
    2025: (firstTier: 0.72, afterTier: 0.66),
    2026: (firstTier: 0.73, afterTier: 0.67),
  };

  static const double _canadaTier1LimitKm = 5000;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// The IRS business rate per mile in force on [date].
  double usaRatePerMile(DateTime date) {
    var rate = _usaRates.first.perMile;
    for (final entry in _usaRates) {
      if (date.isBefore(entry.from)) break;
      rate = entry.perMile;
    }
    return rate;
  }

  /// The CRA rates for [year], or the nearest year on record.
  ({double firstTier, double afterTier}) canadaRates(int year) {
    final years = _canadaRates.keys.toList()..sort();
    var chosen = years.first;
    for (final y in years) {
      if (y > year) break;
      chosen = y;
    }
    return _canadaRates[chosen]!;
  }

  /// Deduction for [km] kilometres all driven on [on] (today if omitted).
  ///
  /// For a set of trips use [calculateTaxForTrips], which applies each
  /// trip's own rate.
  double calculateTaxFromKm(double km, Country country, {DateTime? on}) {
    assert(km >= 0, 'Distance must be non-negative');
    if (km <= 0) return 0;
    final date = on ?? DateTime.now();
    return calculateTaxForTrips([(date: date, km: km)], country);
  }

  /// Deduction for business [distances], each at the rate of its own date.
  ///
  /// Canada's lower rate starts after 5,000 km in a calendar year, so
  /// kilometres are added up per year before the tiers are applied.
  double calculateTaxForTrips(
    Iterable<DatedDistance> distances,
    Country country,
  ) {
    switch (country) {
      case Country.usa:
        var total = 0.0;
        for (final d in distances) {
          if (d.km <= 0) continue;
          total += _kmToMiles(d.km) * usaRatePerMile(d.date);
        }
        return total;
      case Country.canada:
        final kmByYear = <int, double>{};
        for (final d in distances) {
          if (d.km <= 0) continue;
          kmByYear[d.date.year] = (kmByYear[d.date.year] ?? 0) + d.km;
        }
        var total = 0.0;
        kmByYear.forEach((year, km) {
          final rates = canadaRates(year);
          final firstKm = km < _canadaTier1LimitKm ? km : _canadaTier1LimitKm;
          total += firstKm * rates.firstTier + (km - firstKm) * rates.afterTier;
        });
        return total;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  double _kmToMiles(double km) => km * 0.621371;
}
