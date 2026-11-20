import '../models/habit_stats.dart';
import 'date_utils.dart';

/// Pure streak and completion maths over a set of checked-in dates.
///
/// Everything here is a pure function of the date set, so it is fully
/// unit-testable without a database or plugins.
class StreakCalculator {
  /// Current unbroken run of days, ending today.
  ///
  /// If today is not checked yet, the run may still end yesterday —
  /// a streak is not lost until a full day passes unchecked.
  static int currentStreak(Set<DateTime> checkedDates, {DateTime? today}) {
    final now = dateOnly(today ?? DateTime.now());
    final days = checkedDates.map(dateOnly).toSet();
    var cursor = days.contains(now) ? now : now.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest unbroken run ever recorded in [checkedDates].
  static int bestStreak(Set<DateTime> checkedDates) {
    if (checkedDates.isEmpty) {
      return 0;
    }
    final days = checkedDates.map(dateOnly).toSet().toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > best) {
          best = run;
        }
      } else {
        run = 1;
      }
    }
    return best;
  }

  /// Fraction of the last [days] days (ending today) that were checked.
  static double completionRate(
    Set<DateTime> checkedDates,
    int days, {
    DateTime? today,
  }) {
    if (days <= 0) {
      return 0;
    }
    final now = dateOnly(today ?? DateTime.now());
    final set = checkedDates.map(dateOnly).toSet();
    var done = 0;
    for (var i = 0; i < days; i++) {
      if (set.contains(now.subtract(Duration(days: i)))) {
        done++;
      }
    }
    return done / days;
  }

  /// Check-in status for each day of the current week (Mon..Sun).
  static List<bool> currentWeek(
    Set<DateTime> checkedDates, {
    DateTime? today,
  }) {
    final now = dateOnly(today ?? DateTime.now());
    final monday = startOfWeek(now);
    final set = checkedDates.map(dateOnly).toSet();
    return List<bool>.generate(
      7,
      (i) => set.contains(monday.add(Duration(days: i))),
    );
  }

  /// Check-in status for the last [n] days, oldest first.
  static List<bool> lastNDaysStatus(
    Set<DateTime> checkedDates,
    int n, {
    DateTime? today,
  }) {
    final days = lastNDays(n, today: today);
    final set = checkedDates.map(dateOnly).toSet();
    return days.map((d) => set.contains(d)).toList();
  }

  /// Days checked within a calendar month, plus the month length.
  static ({int checked, int total}) monthStats(
    Set<DateTime> checkedDates,
    int year,
    int month,
  ) {
    final total = daysInMonth(year, month);
    final set = checkedDates.map(dateOnly).toSet();
    var checked = 0;
    for (var day = 1; day <= total; day++) {
      if (set.contains(DateTime(year, month, day))) {
        checked++;
      }
    }
    return (checked: checked, total: total);
  }

  /// Full stats bundle for one habit.
  static HabitStats statsFor(
    Set<DateTime> checkedDates,
    DateTime createdAt, {
    DateTime? today,
  }) {
    final now = dateOnly(today ?? DateTime.now());
    final daysSinceStart = now.difference(dateOnly(createdAt)).inDays + 1;
    return HabitStats(
      currentStreak: currentStreak(checkedDates, today: now),
      bestStreak: bestStreak(checkedDates),
      totalCheckIns: checkedDates.length,
      completionLast7: completionRate(checkedDates, 7, today: now),
      completionLast30: completionRate(checkedDates, 30, today: now),
      daysSinceStart: daysSinceStart < 1 ? 1 : daysSinceStart,
    );
  }
}
