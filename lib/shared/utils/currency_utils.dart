const String kDefaultCurrencyCode = 'USD';

/// Formats [amount] for UI display with the given [currencyCode].
///
/// Examples:
///   formatCurrency(12.5)          → "USD 12.50"
///   formatCurrency(12.5, 'CAD')   → "CAD 12.50"
String formatCurrency(double amount, [String currencyCode = kDefaultCurrencyCode]) {
  return '$currencyCode ${amount.toStringAsFixed(2)}';
}

/// Formats [amount] using a compact dollar-sign prefix for tight UI spaces.
///
/// Examples:
///   formatCurrencyCompact(12.5)   → "\$12.50"
String formatCurrencyCompact(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}
