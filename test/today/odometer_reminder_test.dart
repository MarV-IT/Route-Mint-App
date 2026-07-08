import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/features/today/odometer_reminder.dart';

void main() {
  group('isWeeklyOdometerReminderDue', () {
    // 2026-07-06 is a Monday.
    final monday = DateTime(2026, 7, 6, 9, 0);
    final tuesday = DateTime(2026, 7, 7, 9, 0);
    final sunday = DateTime(2026, 7, 12, 9, 0);

    test('due on Monday when never updated', () {
      expect(isWeeklyOdometerReminderDue(now: monday, lastUpdate: null), true);
    });

    test('due on Monday when last update was previous week', () {
      expect(
        isWeeklyOdometerReminderDue(
          now: monday,
          lastUpdate: DateTime(2026, 7, 3), // previous Friday
        ),
        true,
      );
    });

    test('stays due on Tuesday when Monday was skipped (regression)', () {
      expect(
        isWeeklyOdometerReminderDue(
          now: tuesday,
          lastUpdate: DateTime(2026, 7, 3), // previous Friday
        ),
        true,
      );
    });

    test('stays due through Sunday when the whole week was skipped', () {
      expect(
        isWeeklyOdometerReminderDue(
          now: sunday,
          lastUpdate: DateTime(2026, 6, 29), // Monday of previous week
        ),
        true,
      );
    });

    test('not due after updating earlier the same Monday', () {
      expect(
        isWeeklyOdometerReminderDue(
          now: monday,
          lastUpdate: DateTime(2026, 7, 6, 7, 30),
        ),
        false,
      );
    });

    test('not due later in the week after updating mid-week', () {
      expect(
        isWeeklyOdometerReminderDue(
          now: sunday,
          lastUpdate: DateTime(2026, 7, 8), // Wednesday same week
        ),
        false,
      );
    });

    test('handles month boundaries when computing Monday start', () {
      // 2026-08-01 is a Saturday; its week starts Monday 2026-07-27.
      expect(
        isWeeklyOdometerReminderDue(
          now: DateTime(2026, 8, 1, 12, 0),
          lastUpdate: DateTime(2026, 7, 26), // Sunday of previous week
        ),
        true,
      );
      expect(
        isWeeklyOdometerReminderDue(
          now: DateTime(2026, 8, 1, 12, 0),
          lastUpdate: DateTime(2026, 7, 28), // Tuesday same week
        ),
        false,
      );
    });
  });
}
