// Date helpers for Streakly.
//
// All dates are handled as date-only values (midnight, local time) so
// streak math is exact and never trips over time zones or clock times.

/// Returns [date] with the time component stripped.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// True when both dates fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Serialises a date as `yyyy-MM-dd` (the format stored in SQLite).
String toDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Parses a `yyyy-MM-dd` key back into a date-only [DateTime].
DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// The last [n] calendar days ending today, oldest first.
List<DateTime> lastNDays(int n, {DateTime? today}) {
  final end = dateOnly(today ?? DateTime.now());
  return List<DateTime>.generate(
    n,
    (i) => end.subtract(Duration(days: n - 1 - i)),
  );
}

/// The Monday of the week containing [date].
DateTime startOfWeek(DateTime date) {
  final d = dateOnly(date);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Number of days in a given month.
int daysInMonth(int year, int month) {
  final firstOfNext = month == 12
      ? DateTime(year + 1, 1, 1)
      : DateTime(year, month + 1, 1);
  return firstOfNext.subtract(const Duration(days: 1)).day;
}

/// Short weekday labels starting Monday, used by the week strip.
const List<String> weekdayLabels = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Short month labels, index 0 is January.
const List<String> monthLabels = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
