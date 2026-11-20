/// Pure reminder-time maths, kept free of plugins so it is unit-testable.
///
/// Reminder times are stored as minutes since midnight (0..1439).

/// The next wall-clock moment a reminder should fire.
///
/// If today's reminder time is still ahead, returns today at that time,
/// otherwise returns tomorrow at that time.
DateTime nextReminderDateTime(DateTime now, int minutesSinceMidnight) {
  final today = DateTime(now.year, now.month, now.day)
      .add(Duration(minutes: minutesSinceMidnight));
  if (today.isAfter(now)) {
    return today;
  }
  return today.add(const Duration(days: 1));
}

/// Formats minutes-since-midnight as a 24-hour clock string, e.g. `08:30`.
String formatReminderMinutes(int minutesSinceMidnight) {
  final hour = minutesSinceMidnight ~/ 60;
  final minute = minutesSinceMidnight % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

/// Formats minutes-since-midnight as a 12-hour string, e.g. `8:30 AM`.
String formatReminderMinutes12h(int minutesSinceMidnight) {
  final hour24 = minutesSinceMidnight ~/ 60;
  final minute = minutesSinceMidnight % 60;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

/// Combines an hour and minute into minutes since midnight.
int minutesFromHourMinute(int hour, int minute) => hour * 60 + minute;
