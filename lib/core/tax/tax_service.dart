enum Country { usa, canada }

class TaxService {
  // ─── Constants ────────────────────────────────────────────────────────────

  static const double _usaRatePerMile = 0.725;

  static const double _canadaRateTier1 = 0.73; // first 5000 km
  static const double _canadaRateTier2 = 0.67; // beyond 5000 km
  static const double _canadaTier1LimitKm = 5000;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Calculates tax reimbursement for a given distance in kilometres.
  ///
  /// [km] — trip distance in kilometres (must be ≥ 0).
  /// [country] — jurisdiction that determines the rate schedule.
  ///
  /// Returns the reimbursement amount in local currency.
  double calculateTaxFromKm(double km, Country country) {
    assert(km >= 0, 'Distance must be non-negative');
    if (km <= 0) return 0;

    switch (country) {
      case Country.usa:
        return _calculateUsa(km);
      case Country.canada:
        return _calculateCanada(km);
    }
  }

  // ─── Private calculations ─────────────────────────────────────────────────

  double _calculateUsa(double km) {
    final miles = _kmToMiles(km);
    return miles * _usaRatePerMile;
  }

  double _calculateCanada(double km) {
    if (km <= _canadaTier1LimitKm) {
      return km * _canadaRateTier1;
    }

    final tier1Amount = _canadaTier1LimitKm * _canadaRateTier1;
    final tier2Amount = (km - _canadaTier1LimitKm) * _canadaRateTier2;
    return tier1Amount + tier2Amount;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  double _kmToMiles(double km) => km * 0.621371;
}
