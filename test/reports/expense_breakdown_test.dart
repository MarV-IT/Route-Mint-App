import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/features/expenses/models/expense_entry.dart';
import 'package:route_mint_app/features/fuel/models/fuel_entry.dart';
import 'package:route_mint_app/features/reports/expense_breakdown.dart';
import 'package:route_mint_app/features/reports/platform_breakdown.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';

var _id = 0;

Trip trip({
  double parking = 0,
  double tolls = 0,
  String category = 'business',
  DateTime? date,
}) => Trip(
  id: 't${_id++}',
  from: 'A',
  to: 'B',
  distance: 10,
  category: category,
  date: date ?? DateTime(2026, 10, 15),
  parkingExpense: parking,
  tollsExpense: tolls,
);

FuelEntry fuel(double cost, {DateTime? date}) => FuelEntry(
  id: 'f${_id++}',
  date: date ?? DateTime(2026, 10, 15),
  volumeLiters: 30,
  totalCost: cost,
);

ExpenseEntry expense(String category, double amount, {DateTime? date}) =>
    ExpenseEntry(
      id: 'e${_id++}',
      date: date ?? DateTime(2026, 10, 15),
      category: category,
      amount: amount,
    );

Map<ExpenseKind, double> amounts(ExpenseBreakdown b) => {
  for (final s in b.shares) s.kind: s.amount,
};

void main() {
  test('adds each kind from where it is recorded', () {
    final result = buildExpenseBreakdown(
      trips: [
        trip(parking: 5, tolls: 2),
        // Personal driving still costs money; the chart is about spending.
        trip(parking: 3, category: 'personal'),
      ],
      fuelEntries: [fuel(40), fuel(35.5)],
      expenseEntries: [
        expense('service', 120),
        expense('repair', 300),
        expense('parking', 10),
        expense('tolls', 4),
      ],
    );

    expect(amounts(result), {
      ExpenseKind.fuel: 75.5,
      ExpenseKind.service: 120,
      ExpenseKind.repair: 300,
      ExpenseKind.tolls: 6,
      ExpenseKind.parking: 18,
    });
    expect(result.total, closeTo(519.5, 1e-9));
    expect(result.isEmpty, isFalse);
  });

  test('always lists all five kinds, largest first, empty ones last', () {
    final result = buildExpenseBreakdown(
      trips: [trip(tolls: 9)],
      fuelEntries: [fuel(50)],
      expenseEntries: const [],
    );
    expect([for (final s in result.shares) s.kind], [
      ExpenseKind.fuel,
      ExpenseKind.tolls,
      // Nothing spent: the app's own order.
      ExpenseKind.service,
      ExpenseKind.repair,
      ExpenseKind.parking,
    ]);
  });

  test('ignores unknown categories and non-positive amounts', () {
    final result = buildExpenseBreakdown(
      trips: [trip(parking: -4)],
      fuelEntries: [fuel(0)],
      expenseEntries: [expense('snacks', 12)],
    );
    expect(result.isEmpty, isTrue);
    expect(result.total, 0);
  });

  test('nothing recorded is an empty breakdown, not an error', () {
    final result = buildExpenseBreakdown(
      trips: const [],
      fuelEntries: const [],
      expenseEntries: const [],
    );
    expect(result.shares, hasLength(ExpenseKind.values.length));
    expect(result.isEmpty, isTrue);
  });

  test('records are filtered to the chart period by their own date', () {
    final now = DateTime(2026, 10, 21, 14); // Wednesday
    final entries = [
      expense('repair', 1, date: DateTime(2026, 10, 20)), // this week
      expense('repair', 1, date: DateTime(2026, 10, 2)), // this month
      expense('repair', 1, date: DateTime(2026, 9, 30)), // earlier
    ];
    DateTime dateOf(ExpenseEntry e) => e.date;
    expect(inChartPeriod(entries, dateOf, ChartPeriod.week, now), hasLength(1));
    expect(
      inChartPeriod(entries, dateOf, ChartPeriod.month, now),
      hasLength(2),
    );
    expect(
      inChartPeriod(entries, dateOf, ChartPeriod.allTime, now),
      hasLength(3),
    );
  });
}
