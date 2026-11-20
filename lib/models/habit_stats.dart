/// Aggregated numbers for one habit, computed from its check-ins.
class HabitStats {
  const HabitStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCheckIns,
    required this.completionLast7,
    required this.completionLast30,
    required this.daysSinceStart,
  });

  /// Consecutive days checked, ending today (or yesterday if today
  /// is not checked yet).
  final int currentStreak;

  /// Longest unbroken run ever.
  final int bestStreak;

  /// Total days ever checked in.
  final int totalCheckIns;

  /// Fraction of the last 7 days checked (0.0..1.0).
  final double completionLast7;

  /// Fraction of the last 30 days checked (0.0..1.0).
  final double completionLast30;

  /// Days since the habit was created.
  final int daysSinceStart;

  /// Progress toward a streak target of [targetDays] (0.0..1.0).
  double progressToTarget(int targetDays) {
    if (targetDays <= 0) {
      return 0;
    }
    final progress = currentStreak / targetDays;
    return progress > 1 ? 1 : progress;
  }
}

/// Aggregated numbers across all of the user's habits.
class OverallStats {
  const OverallStats({
    required this.totalHabits,
    required this.activeHabits,
    required this.totalCheckIns,
    required this.bestStreakOverall,
    required this.averageCompletion30,
    required this.habitsCheckedToday,
    required this.habitsDueToday,
  });

  final int totalHabits;
  final int activeHabits;
  final int totalCheckIns;
  final int bestStreakOverall;

  /// Mean 30-day completion across active habits (0.0..1.0).
  final double averageCompletion30;

  /// Active habits already checked in today.
  final int habitsCheckedToday;

  /// Active habits due today (same as [activeHabits] — every habit is
  /// due every day).
  final int habitsDueToday;

  /// Fraction of today's habits already done (0.0..1.0).
  double get todayProgress {
    if (habitsDueToday == 0) {
      return 0;
    }
    return habitsCheckedToday / habitsDueToday;
  }
}
