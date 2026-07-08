/// Whether the weekly odometer reminder is due.
///
/// The reminder becomes due when the current week starts (Monday 00:00) and
/// stays due on the following days until the odometer is updated during that
/// week — skipping the app on Monday must not hide it for the rest of the
/// week.
bool isWeeklyOdometerReminderDue({
  required DateTime now,
  required DateTime? lastUpdate,
}) {
  final mondayStart = DateTime(
    now.year,
    now.month,
    now.day - (now.weekday - DateTime.monday),
  );
  return lastUpdate == null || lastUpdate.isBefore(mondayStart);
}
