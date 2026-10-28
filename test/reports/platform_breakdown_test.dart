import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/features/reports/platform_breakdown.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';

var _id = 0;

Trip trip({String? platform, String category = 'business', DateTime? date}) =>
    Trip(
      id: 't${_id++}',
      from: 'A',
      to: 'B',
      distance: 10,
      category: category,
      date: date ?? DateTime(2026, 10, 15, 10),
      platformName: platform,
    );

List<Trip> many(int n, {String? platform, String category = 'business'}) => [
  for (var i = 0; i < n; i++) trip(platform: platform, category: category),
];

void main() {
  group('roundedPercents', () {
    int sum(List<int> xs) => xs.fold(0, (s, x) => s + x);

    test('always sums to exactly 100', () {
      for (final counts in [
        [1, 1, 1],
        [2, 1],
        [199, 1],
        [1, 1, 1, 1, 1, 1, 1],
        [7, 3, 3, 2],
        [10],
      ]) {
        expect(sum(roundedPercents(counts)), 100, reason: '$counts');
      }
    });

    test('the largest share absorbs the rounding error', () {
      // 33.3 each rounds to 99 in total; the first (largest, tied) takes +1.
      expect(roundedPercents([1, 1, 1]), [34, 33, 33]);
      // 99.5 and 0.5 both round up to 101; the largest gives one back.
      expect(roundedPercents([199, 1]), [99, 1]);
    });

    test('a single slice is a clean 100%', () {
      expect(roundedPercents([42]), [100]);
    });

    test('no trips gives zeros rather than dividing by zero', () {
      expect(roundedPercents([0, 0]), [0, 0]);
      expect(roundedPercents([]), isEmpty);
    });
  });

  group('PlatformColorAssignment', () {
    test('names the three most used platforms and folds the rest', () {
      final colors = PlatformColorAssignment.fromTrips([
        ...many(5, platform: 'Amazon Flex'),
        ...many(4, platform: 'DoorDash'),
        ...many(3, platform: 'Uber'),
        ...many(1, platform: 'Lyft'),
      ]);

      expect(colors.bucketFor(trip(platform: 'Amazon Flex')).colorSlot, 0);
      expect(colors.bucketFor(trip(platform: 'DoorDash')).colorSlot, 1);
      expect(colors.bucketFor(trip(platform: 'Uber')).colorSlot, 2);
      expect(
        colors.bucketFor(trip(platform: 'Lyft')).kind,
        PlatformBucketKind.otherWork,
      );
    });

    test('work trips without a platform are other work', () {
      final colors = PlatformColorAssignment.fromTrips(
        many(3, platform: 'Uber'),
      );
      expect(colors.bucketFor(trip()).kind, PlatformBucketKind.otherWork);
      expect(
        colors.bucketFor(trip(platform: '  ')).kind,
        PlatformBucketKind.otherWork,
      );
    });

    test('personal trips are personal whatever platform they carry', () {
      final colors = PlatformColorAssignment.fromTrips(
        many(3, platform: 'Uber'),
      );
      expect(
        colors.bucketFor(trip(platform: 'Uber', category: 'personal')).kind,
        PlatformBucketKind.personal,
      );
    });

    test('groups platform names case-insensitively', () {
      final colors = PlatformColorAssignment.fromTrips([
        trip(platform: 'Uber'),
        trip(platform: 'uber '),
        trip(platform: 'Lyft'),
      ]);
      final upper = colors.bucketFor(trip(platform: 'Uber'));
      expect(colors.bucketFor(trip(platform: 'UBER')), upper);
      expect(upper.colorSlot, 0);
    });

    test('breaks ties by name so colours are stable', () {
      final a = PlatformColorAssignment.fromTrips([
        trip(platform: 'Lyft'),
        trip(platform: 'DoorDash'),
      ]);
      final b = PlatformColorAssignment.fromTrips([
        trip(platform: 'DoorDash'),
        trip(platform: 'Lyft'),
      ]);
      expect(a.bucketFor(trip(platform: 'DoorDash')).colorSlot, 0);
      expect(b.bucketFor(trip(platform: 'DoorDash')).colorSlot, 0);
    });
  });

  group('buildPlatformBreakdown', () {
    test(
      'counts trips and orders platforms, then other work, then personal',
      () {
        final trips = [
          ...many(2, platform: 'DoorDash'),
          ...many(5, platform: 'Amazon Flex'),
          ...many(1),
          ...many(2, category: 'personal'),
        ];
        final result = buildPlatformBreakdown(
          trips: trips,
          colors: PlatformColorAssignment.fromTrips(trips),
        );

        expect(result.totalTrips, 10);
        expect([for (final s in result.shares) s.tripCount], [5, 2, 1, 2]);
        expect(
          [for (final s in result.shares) s.bucket.kind],
          [
            PlatformBucketKind.platform,
            PlatformBucketKind.platform,
            PlatformBucketKind.otherWork,
            PlatformBucketKind.personal,
          ],
        );
        expect(result.shares.first.bucket.name, 'Amazon Flex');
        expect(result.shares.fold(0, (s, x) => s + x.percent), 100);
      },
    );

    test('a single platform is one 100% slice, not an error', () {
      final trips = many(3, platform: 'Amazon Flex');
      final result = buildPlatformBreakdown(
        trips: trips,
        colors: PlatformColorAssignment.fromTrips(trips),
      );
      expect(result.shares, hasLength(1));
      expect(result.shares.single.percent, 100);
    });

    test('a slice that rounds to 0% is flagged so it is not shown as 0%', () {
      final trips = [...many(300, platform: 'Uber'), trip(platform: 'Lyft')];
      final result = buildPlatformBreakdown(
        trips: trips,
        colors: PlatformColorAssignment.fromTrips(trips),
      );
      final lyft = result.shares.firstWhere((s) => s.bucket.name == 'Lyft');
      expect(lyft.percent, 0);
      expect(lyft.isBelowOnePercent, isTrue);
    });

  });

  group('periods', () {
    // Wednesday.
    final now = DateTime(2026, 10, 21, 14);

    test('the week starts on Monday and ends today', () {
      final range = chartPeriodRange(ChartPeriod.week, now);
      expect(range.start, DateTime(2026, 10, 19));
      expect(range.end.day, 21);
    });

    test('filters trips to the week, the month, or keeps everything', () {
      final trips = [
        trip(date: DateTime(2026, 10, 20)), // this week
        trip(date: DateTime(2026, 10, 3)), // this month
        trip(date: DateTime(2026, 9, 28)), // earlier
      ];
      expect(tripsInPeriod(trips, ChartPeriod.week, now), hasLength(1));
      expect(tripsInPeriod(trips, ChartPeriod.month, now), hasLength(2));
      expect(tripsInPeriod(trips, ChartPeriod.allTime, now), hasLength(3));
    });

    test('colours do not change between periods', () {
      // Lyft dominates this week but Uber leads overall, so Uber keeps slot 0.
      final trips = [
        for (var i = 0; i < 6; i++)
          trip(platform: 'Uber', date: DateTime(2026, 9, 1 + i)),
        for (var i = 0; i < 3; i++)
          trip(platform: 'Lyft', date: DateTime(2026, 10, 20)),
      ];
      final colors = PlatformColorAssignment.fromTrips(trips);
      final week = buildPlatformBreakdown(
        trips: tripsInPeriod(trips, ChartPeriod.week, now),
        colors: colors,
      );
      final all = buildPlatformBreakdown(
        trips: trips,
        colors: colors,
      );
      int? slotOf(PlatformBreakdown b, String name) =>
          b.shares.firstWhere((s) => s.bucket.name == name).bucket.colorSlot;

      expect(slotOf(week, 'Lyft'), slotOf(all, 'Lyft'));
      expect(slotOf(all, 'Uber'), 0);
    });

    test('all time starts at the earliest record', () {
      final range = chartPeriodRange(
        ChartPeriod.allTime,
        now,
        earliest: DateTime(2025, 3, 4, 9),
      );
      expect(range.start, DateTime(2025, 3, 4));
    });
  });
}
