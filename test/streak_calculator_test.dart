import 'package:flutter_test/flutter_test.dart';
import 'package:streakly/services/streak_calculator.dart';

void main() {
  // Fixed "today" so tests are deterministic.
  final today = DateTime(2026, 11, 20);
  DateTime d(int day) => DateTime(2026, 11, day);

  Set<DateTime> days(List<int> dayNumbers) {
    return dayNumbers.map(d).toSet();
  }

  group('currentStreak', () {
    test('empty set has no streak', () {
      expect(StreakCalculator.currentStreak(<DateTime>{}, today: today), 0);
    });

    test('today only is a 1-day streak', () {
      expect(
        StreakCalculator.currentStreak(days([20]), today: today),
        1,
      );
    });

    test('yesterday only still counts as a 1-day streak', () {
      expect(
        StreakCalculator.currentStreak(days([19]), today: today),
        1,
      );
    });

    test('unbroken run ending today', () {
      expect(
        StreakCalculator.currentStreak(days([16, 17, 18, 19, 20]),
            today: today),
        5,
      );
    });

    test('unbroken run ending yesterday (today not checked yet)', () {
      expect(
        StreakCalculator.currentStreak(days([16, 17, 18, 19]),
            today: today),
        4,
      );
    });

    test('a gap breaks the streak', () {
      expect(
        StreakCalculator.currentStreak(days([10, 11, 12, 18, 19, 20]),
            today: today),
        3,
      );
    });

    test('last check two days ago means no current streak', () {
      expect(
        StreakCalculator.currentStreak(days([15, 16, 17, 18]),
            today: today),
        0,
      );
    });

    test('streak crosses a month boundary', () {
      final set = <DateTime>{
        DateTime(2026, 10, 30),
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
      };
      expect(
        StreakCalculator.currentStreak(set, today: DateTime(2026, 11, 2)),
        4,
      );
    });
  });

  group('bestStreak', () {
    test('empty set is 0', () {
      expect(StreakCalculator.bestStreak(<DateTime>{}), 0);
    });

    test('single day is 1', () {
      expect(StreakCalculator.bestStreak(days([20])), 1);
    });

    test('picks the longest run among several', () {
      expect(
        StreakCalculator.bestStreak(days([1, 2, 3, 10, 11, 12, 13, 14])),
        5,
      );
    });

    test('a full unbroken month is the whole month', () {
      final set = List<DateTime>.generate(
        30,
        (i) => DateTime(2026, 10, i + 1),
      ).toSet();
      expect(StreakCalculator.bestStreak(set), 30);
    });
  });

  group('completionRate', () {
    test('all 7 days checked is 1.0', () {
      expect(
        StreakCalculator.completionRate(days([14, 15, 16, 17, 18, 19, 20]), 7,
            today: today),
        1.0,
      );
    });

    test('half the days checked is 0.5', () {
      expect(
        StreakCalculator.completionRate(days([17, 19, 20]), 7, today: today),
        closeTo(3 / 7, 0.001),
      );
    });

    test('nothing checked is 0.0', () {
      expect(
        StreakCalculator.completionRate(<DateTime>{}, 30, today: today),
        0.0,
      );
    });

    test('zero days requested is 0.0', () {
      expect(
        StreakCalculator.completionRate(days([20]), 0, today: today),
        0.0,
      );
    });
  });

  group('currentWeek', () {
    test('marks Mon..Sun correctly for a Friday today', () {
      // 2026-11-20 is a Friday; week is Nov 16..22.
      final week = StreakCalculator.currentWeek(days([16, 18, 20]),
          today: today);
      expect(week, [true, false, true, false, true, false, false]);
    });
  });

  group('lastNDaysStatus', () {
    test('returns oldest-first booleans', () {
      final status = StreakCalculator.lastNDaysStatus(days([18, 20]), 3,
          today: today);
      expect(status, [true, false, true]);
    });
  });

  group('monthStats', () {
    test('counts checked days in November 2026', () {
      final stats = StreakCalculator.monthStats(days([1, 2, 20]), 2026, 11);
      expect(stats.checked, 3);
      expect(stats.total, 30);
    });

    test('February 2026 has 28 days', () {
      final stats = StreakCalculator.monthStats(<DateTime>{}, 2026, 2);
      expect(stats.total, 28);
    });
  });

  group('statsFor', () {
    test('bundles streaks, totals and rates', () {
      final stats = StreakCalculator.statsFor(
        days([14, 15, 16, 17, 18, 19, 20]),
        DateTime(2026, 11, 1),
        today: today,
      );
      expect(stats.currentStreak, 7);
      expect(stats.bestStreak, 7);
      expect(stats.totalCheckIns, 7);
      expect(stats.completionLast7, 1.0);
      expect(stats.daysSinceStart, 20);
      expect(stats.progressToTarget(30), closeTo(7 / 30, 0.001));
      expect(stats.progressToTarget(7), 1.0);
    });
  });
}
