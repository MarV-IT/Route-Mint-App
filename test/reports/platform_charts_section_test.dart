import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/features/expenses/models/expense_entry.dart';
import 'package:route_mint_app/features/fuel/models/fuel_entry.dart';
import 'package:route_mint_app/features/reports/expense_breakdown.dart';
import 'package:route_mint_app/features/reports/platform_breakdown.dart';
import 'package:route_mint_app/features/reports/widgets/platform_charts_section.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';

var _id = 0;

Trip trip({
  String? platform,
  String category = 'business',
  double parking = 0,
}) => Trip(
  id: 'c${_id++}',
  from: 'A',
  to: 'B',
  distance: 12,
  category: category,
  date: DateTime(2026, 10, 15),
  platformName: platform,
  parkingExpense: parking,
);

PlatformBreakdown breakdownOf(List<Trip> trips) => buildPlatformBreakdown(
  trips: trips,
  colors: PlatformColorAssignment.fromTrips(trips),
);

ExpenseBreakdown expensesOf({
  List<Trip> trips = const [],
  List<FuelEntry> fuel = const [],
  List<ExpenseEntry> entries = const [],
}) => buildExpenseBreakdown(
  trips: trips,
  fuelEntries: fuel,
  expenseEntries: entries,
);

final _noExpenses = expensesOf();

FuelEntry fuelEntry(double cost) => FuelEntry(
  id: 'f${_id++}',
  date: DateTime(2026, 10, 15),
  volumeLiters: 30,
  totalCost: cost,
);

ExpenseEntry expenseEntry(String category, double amount) => ExpenseEntry(
  id: 'e${_id++}',
  date: DateTime(2026, 10, 15),
  category: category,
  amount: amount,
);

void main() {
  final uk = AppStrings(AppLanguage.ukrainian);

  Widget host(
    Widget child, {
    ThemeData? theme,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    theme: theme,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: app!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );

  PlatformChartsSection section({
    required PlatformBreakdown breakdown,
    ExpenseBreakdown? expenses,
    bool hasAnyRecords = true,
    ChartPeriod period = ChartPeriod.month,
    ValueChanged<ChartPeriod>? onPeriodChanged,
    VoidCallback? onAddTrip,
    VoidCallback? onAddExpense,
    VoidCallback? onCreateReport,
    bool isCreatingReport = false,
  }) => PlatformChartsSection(
    strings: uk,
    period: period,
    onPeriodChanged: onPeriodChanged ?? (_) {},
    breakdown: breakdown,
    expenses: expenses ?? _noExpenses,
    hasAnyRecords: hasAnyRecords,
    currencyCode: 'USD',
    onAddTrip: onAddTrip,
    onAddExpense: onAddExpense,
    onCreateReport: onCreateReport,
    isCreatingReport: isCreatingReport,
  );

  testWidgets('with nothing recorded at all it invites adding a trip', (
    tester,
  ) async {
    var added = false;
    await tester.pumpWidget(
      host(
        section(
          breakdown: breakdownOf(const []),
          hasAnyRecords: false,
          onAddTrip: () => added = true,
        ),
      ),
    );

    expect(find.text(uk.chartsEmptyMessage), findsOneWidget);
    // No empty axes and no period filter for a history that does not exist.
    expect(find.byType(SegmentedButton<ChartPeriod>), findsNothing);
    expect(find.text(uk.createReport), findsNothing);

    await tester.tap(find.text(uk.addTrip));
    expect(added, isTrue);
  });

  testWidgets('an empty period offers to widen it instead of empty charts', (
    tester,
  ) async {
    ChartPeriod? picked;
    await tester.pumpWidget(
      host(
        section(
          breakdown: breakdownOf(const []),
          period: ChartPeriod.week,
          onPeriodChanged: (p) => picked = p,
        ),
      ),
    );

    expect(find.text(uk.noTripsInPeriod), findsOneWidget);
    expect(find.text(uk.tripShareByPlatform), findsNothing);
    await tester.tap(find.text(uk.showAllTime));
    expect(picked, ChartPeriod.allTime);
  });

  testWidgets('labels show the trip count and percent without a tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        section(
          breakdown: breakdownOf([
            ...List.generate(3, (_) => trip(platform: 'Amazon Flex')),
            trip(category: 'personal'),
          ]),
        ),
      ),
    );

    expect(find.text('Amazon Flex'), findsOneWidget);
    expect(find.text('3 поїздки · 75%'), findsOneWidget);
    expect(find.text(uk.personalTrips), findsOneWidget);
    expect(find.text('1 поїздка · 25%'), findsOneWidget);
    // Total in the middle of the ring, with the matching noun form.
    expect(find.text('4'), findsOneWidget);
    expect(find.text('поїздки'), findsOneWidget);
  });

  testWidgets('the bars show every expense kind with its amount', (
    tester,
  ) async {
    final trips = [trip(platform: 'Uber', parking: 6)];
    await tester.pumpWidget(
      host(
        section(
          breakdown: breakdownOf(trips),
          expenses: expensesOf(
            trips: trips,
            fuel: [fuelEntry(80)],
            entries: [expenseEntry('repair', 250), expenseEntry('tolls', 4)],
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text(uk.expensesByType));

    expect(find.text(uk.expensesByType), findsOneWidget);
    expect(find.text('Разом: USD 340.00'), findsOneWidget);
    for (final label in [
      uk.fuel,
      uk.serviceExpense,
      uk.repair,
      uk.tolls,
      uk.parking,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('USD 250.00'), findsOneWidget);
    expect(find.text('USD 80.00'), findsOneWidget);
    // Nothing spent on service: shown as zero, not hidden.
    expect(find.text('USD 0.00'), findsOneWidget);
    // Largest first.
    final repairY = tester.getTopLeft(find.text(uk.repair)).dy;
    final fuelY = tester.getTopLeft(find.text(uk.fuel)).dy;
    expect(repairY, lessThan(fuelY));
  });

  testWidgets('a period without expenses offers to add one', (tester) async {
    var added = false;
    await tester.pumpWidget(
      host(
        section(
          breakdown: breakdownOf([trip(platform: 'Uber')]),
          onAddExpense: () => added = true,
        ),
      ),
    );
    await tester.ensureVisible(find.text(uk.noExpensesInPeriod));
    await tester.pumpAndSettle();

    expect(find.text(uk.noExpensesInPeriod), findsOneWidget);
    expect(find.text(uk.fuel), findsNothing);
    await tester.tap(find.text(uk.addExpense));
    expect(added, isTrue);
  });

  testWidgets('expenses still show in a period without trips', (
    tester,
  ) async {
    var created = 0;
    await tester.pumpWidget(
      host(
        section(
          breakdown: breakdownOf(const []),
          expenses: expensesOf(fuel: [fuelEntry(50)]),
          onCreateReport: () => created++,
        ),
      ),
    );

    expect(find.text(uk.noTripsInPeriod), findsOneWidget);
    await tester.ensureVisible(find.text(uk.createReport));
    await tester.pumpAndSettle();
    expect(find.text('Разом: USD 50.00'), findsOneWidget);
    await tester.tap(find.text(uk.createReport));
    expect(created, 1);
  });

  testWidgets('create report runs the export and locks while it is busy', (
    tester,
  ) async {
    var created = 0;
    final breakdown = breakdownOf([trip(platform: 'Uber')]);
    await tester.pumpWidget(
      host(section(breakdown: breakdown, onCreateReport: () => created++)),
    );
    // The button sits under both charts, below the test viewport's fold.
    await tester.ensureVisible(find.text(uk.createReport));
    await tester.pumpAndSettle();
    await tester.tap(find.text(uk.createReport));
    expect(created, 1);

    await tester.pumpWidget(
      host(
        section(
          breakdown: breakdown,
          onCreateReport: () => created++,
          isCreatingReport: true,
        ),
      ),
    );
    // The busy spinner never settles, so pump a frame rather than settle.
    await tester.ensureVisible(find.text(uk.createReport));
    await tester.pump();
    await tester.tap(find.text(uk.createReport), warnIfMissed: false);
    expect(created, 1);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$platform $brightness: five slices and five bars fit a small phone '
        'at 200% text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            host(
              section(
                breakdown: breakdownOf([
                  ...List.generate(9, (_) => trip(platform: 'Amazon Flex')),
                  ...List.generate(5, (_) => trip(platform: 'DoorDash')),
                  ...List.generate(3, (_) => trip(platform: 'Spark Driver')),
                  trip(platform: 'Lyft'),
                  trip(),
                  ...List.generate(4, (_) => trip(category: 'personal')),
                ]),
                expenses: expensesOf(
                  trips: [trip(parking: 12.5)],
                  fuel: [fuelEntry(1216.46)],
                  entries: [
                    expenseEntry('service', 89.99),
                    expenseEntry('repair', 1450),
                    expenseEntry('tolls', 7.25),
                  ],
                ),
              ),
              theme: ThemeData(platform: platform, brightness: brightness),
              textScaler: const TextScaler.linear(2),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          for (var i = 0; i < 10; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -250),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  group('Ukrainian trip plurals', () {
    test('follow the last digits', () {
      expect(uk.tripCount(1), '1 поїздка');
      expect(uk.tripCount(2), '2 поїздки');
      expect(uk.tripCount(4), '4 поїздки');
      expect(uk.tripCount(5), '5 поїздок');
      expect(uk.tripCount(11), '11 поїздок');
      expect(uk.tripCount(12), '12 поїздок');
      expect(uk.tripCount(21), '21 поїздка');
      expect(uk.tripCount(22), '22 поїздки');
      expect(uk.tripCount(112), '112 поїздок');
      expect(AppStrings(AppLanguage.english).tripCount(1), '1 trip');
      expect(AppStrings(AppLanguage.english).tripCount(2), '2 trips');
    });
  });
}
