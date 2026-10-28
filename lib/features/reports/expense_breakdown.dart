import '../expenses/models/expense_entry.dart';
import '../fuel/models/fuel_entry.dart';
import '../trips/models/trip.dart';

/// What the Reports expense chart splits spending into, in the order the app
/// lists them.
enum ExpenseKind { fuel, service, repair, tolls, parking }

/// Maps a saved expense category to its kind. Unknown categories return null.
ExpenseKind? expenseKindForCategory(String category) => switch (category) {
  'service' => ExpenseKind.service,
  'repair' => ExpenseKind.repair,
  'tolls' => ExpenseKind.tolls,
  'parking' => ExpenseKind.parking,
  _ => null,
};

class ExpenseShare {
  const ExpenseShare(this.kind, this.amount);

  final ExpenseKind kind;
  final double amount;
}

class ExpenseBreakdown {
  const ExpenseBreakdown(this.shares);

  /// One row per kind, largest first. Kinds with nothing spent come last, in
  /// [ExpenseKind] order, so the five rows stay in a predictable place.
  final List<ExpenseShare> shares;

  double get total => shares.fold(0.0, (sum, s) => sum + s.amount);

  bool get isEmpty => total <= 0;
}

/// Adds up a period's spending by kind.
///
/// Fuel comes from the fuel log. Service and repair come from saved expenses.
/// Parking and tolls can be entered on a trip or saved as a separate expense,
/// so both are counted: they are separate payments, not copies of one.
ExpenseBreakdown buildExpenseBreakdown({
  required Iterable<Trip> trips,
  required Iterable<FuelEntry> fuelEntries,
  required Iterable<ExpenseEntry> expenseEntries,
}) {
  final totals = {for (final kind in ExpenseKind.values) kind: 0.0};
  void add(ExpenseKind kind, double amount) {
    if (amount > 0) totals[kind] = totals[kind]! + amount;
  }

  for (final entry in fuelEntries) {
    add(ExpenseKind.fuel, entry.totalCost);
  }
  for (final trip in trips) {
    add(ExpenseKind.parking, trip.parkingExpense);
    add(ExpenseKind.tolls, trip.tollsExpense);
  }
  for (final entry in expenseEntries) {
    final kind = expenseKindForCategory(entry.category);
    if (kind != null) add(kind, entry.amount);
  }

  final shares = [
    for (final kind in ExpenseKind.values) ExpenseShare(kind, totals[kind]!),
  ]..sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      return byAmount != 0 ? byAmount : a.kind.index - b.kind.index;
    });
  return ExpenseBreakdown(shares);
}
