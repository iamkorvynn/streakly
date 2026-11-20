import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:streakly/models/check_in.dart';
import 'package:streakly/models/habit.dart';
import 'package:streakly/models/habit_note.dart';
import 'package:streakly/models/habit_stats.dart';

void main() {
  group('Habit', () {
    test('toMap/fromMap round-trips', () {
      final withDate = Habit(
        id: 7,
        name: 'Read',
        iconIndex: 2,
        colorValue: 0xFFE64A19,
        targetDays: 30,
        reminderMinutes: 510,
        createdAt: DateTime(2026, 11, 1),
      );
      final restored = Habit.fromMap(withDate.toMap());
      expect(restored.id, 7);
      expect(restored.name, 'Read');
      expect(restored.iconIndex, 2);
      expect(restored.colorValue, 0xFFE64A19);
      expect(restored.targetDays, 30);
      expect(restored.reminderMinutes, 510);
      expect(restored.createdAt, DateTime(2026, 11, 1));
      expect(restored.archived, isFalse);
    });

    test('defaults: 30-day target, no reminder, not archived', () {
      final real = Habit(
        name: 'Meditate',
        iconIndex: 2,
        colorValue: 0xFF000000,
        createdAt: DateTime(2026, 11, 1),
      );
      expect(real.targetDays, 30);
      expect(real.reminderMinutes, isNull);
      expect(real.hasReminder, isFalse);
      expect(real.archived, isFalse);
      expect(real.reminderTimeOfDay, isNull);
    });

    test('reminderTimeOfDay converts minutes correctly', () {
      final habit = Habit(
        name: 'Run',
        iconIndex: 2,
        colorValue: 0xFF000000,
        reminderMinutes: 8 * 60 + 30,
        createdAt: DateTime(2026, 11, 1),
      );
      expect(habit.reminderTimeOfDay?.hour, 8);
      expect(habit.reminderTimeOfDay?.minute, 30);
    });

    test('copyWith can clear a reminder', () {
      final habit = Habit(
        name: 'Run',
        iconIndex: 2,
        colorValue: 0xFF000000,
        reminderMinutes: 510,
        createdAt: DateTime(2026, 11, 1),
      );
      final cleared = habit.copyWith(clearReminder: true);
      expect(cleared.reminderMinutes, isNull);
      expect(cleared.name, 'Run');
    });

    test('icon and color getters work', () {
      final habit = Habit(
        name: 'Read',
        iconIndex: 2,
        colorValue: Colors.green.toARGB32(),
        createdAt: DateTime(2026, 11, 1),
      );
      expect(habit.icon.codePoint, Icons.menu_book.codePoint);
      expect(habit.color.toARGB32(), Colors.green.toARGB32());
    });
  });

  group('CheckIn', () {
    test('dateKey formats as yyyy-MM-dd', () {
      final checkIn = CheckIn(
        habitId: 1,
        date: DateTime(2026, 11, 20),
        createdAt: DateTime(2026, 11, 20, 8),
      );
      expect(checkIn.dateKey, '2026-11-20');
    });

    test('toMap/fromMap round-trips', () {
      final checkIn = CheckIn(
        id: 3,
        habitId: 1,
        date: DateTime(2026, 11, 20),
        createdAt: DateTime(2026, 11, 20, 8, 0),
      );
      final restored = CheckIn.fromMap(checkIn.toMap());
      expect(restored.id, 3);
      expect(restored.habitId, 1);
      expect(restored.date, DateTime(2026, 11, 20));
    });
  });

  group('HabitNote', () {
    test('toMap/fromMap round-trips', () {
      final note = HabitNote(
        id: 2,
        habitId: 1,
        date: DateTime(2026, 11, 19),
        text: 'Felt great after the run.',
        createdAt: DateTime(2026, 11, 19, 21, 0),
      );
      final restored = HabitNote.fromMap(note.toMap());
      expect(restored.id, 2);
      expect(restored.text, 'Felt great after the run.');
      expect(restored.dateKey, '2026-11-19');
    });
  });

  group('HabitStats', () {
    test('progressToTarget caps at 1.0', () {
      const stats = HabitStats(
        currentStreak: 40,
        bestStreak: 40,
        totalCheckIns: 40,
        completionLast7: 1,
        completionLast30: 1,
        daysSinceStart: 40,
      );
      expect(stats.progressToTarget(30), 1.0);
      expect(stats.progressToTarget(7), 1.0);
    });

    test('progressToTarget is 0 for a zero target', () {
      const stats = HabitStats(
        currentStreak: 5,
        bestStreak: 5,
        totalCheckIns: 5,
        completionLast7: 1,
        completionLast30: 1,
        daysSinceStart: 5,
      );
      expect(stats.progressToTarget(0), 0);
    });
  });

  group('OverallStats', () {
    test('todayProgress is 0 with no habits due', () {
      const stats = OverallStats(
        totalHabits: 0,
        activeHabits: 0,
        totalCheckIns: 0,
        bestStreakOverall: 0,
        averageCompletion30: 0,
        habitsCheckedToday: 0,
        habitsDueToday: 0,
      );
      expect(stats.todayProgress, 0);
    });

    test('todayProgress is a real fraction', () {
      const stats = OverallStats(
        totalHabits: 4,
        activeHabits: 4,
        totalCheckIns: 10,
        bestStreakOverall: 5,
        averageCompletion30: 0.5,
        habitsCheckedToday: 3,
        habitsDueToday: 4,
      );
      expect(stats.todayProgress, 0.75);
    });
  });
}
