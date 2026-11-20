import '../models/check_in.dart';
import '../models/habit.dart';
import '../models/habit_note.dart';
import '../models/habit_stats.dart';
import '../utils/date_utils.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'streak_calculator.dart';

/// The single place screens talk to for habit data.
///
/// Combines [DatabaseHelper] (storage), [StreakCalculator] (stats) and
/// [NotificationService] (reminders) so screens stay thin.
class HabitRepository {
  HabitRepository({
    DatabaseHelper? database,
    NotificationService? notifications,
  })  : _db = database ?? DatabaseHelper.instance,
        _notifications = notifications ?? NotificationService.instance;

  final DatabaseHelper _db;
  final NotificationService _notifications;

  // ---------------------------------------------------------------- habits

  Future<List<Habit>> getActiveHabits() => _db.getHabits(archived: false);

  Future<List<Habit>> getArchivedHabits() => _db.getHabits(archived: true);

  Future<Habit?> getHabit(int id) => _db.getHabit(id);

  Future<Habit> createHabit(Habit habit) async {
    final id = await _db.insertHabit(habit);
    final created = habit.copyWith(id: id);
    await _notifications.scheduleHabitReminder(created);
    return created;
  }

  Future<void> updateHabit(Habit habit) async {
    await _db.updateHabit(habit);
    await _notifications.scheduleHabitReminder(habit);
  }

  Future<void> deleteHabit(Habit habit) async {
    if (habit.id == null) {
      return;
    }
    await _notifications.cancelHabitReminder(habit.id!);
    await _db.deleteHabit(habit.id!);
  }

  Future<void> archiveHabit(Habit habit, bool archived) async {
    final updated = habit.copyWith(archived: archived);
    await _db.updateHabit(updated);
    if (archived) {
      await _notifications.cancelHabitReminder(habit.id!);
    } else {
      await _notifications.scheduleHabitReminder(updated);
    }
  }

  // -------------------------------------------------------------- check-ins

  /// Toggles today's check-in. Returns true when the habit is now checked.
  Future<bool> toggleCheckInToday(Habit habit) async {
    return toggleCheckIn(habit, dateOnly(DateTime.now()));
  }

  /// Toggles the check-in for [date]. Returns true if now checked.
  Future<bool> toggleCheckIn(Habit habit, DateTime date) async {
    final id = habit.id;
    if (id == null) {
      return false;
    }
    final already = await _db.isChecked(id, date);
    if (already) {
      await _db.deleteCheckIn(id, date);
      return false;
    }
    await _db.insertCheckIn(id, date);
    return true;
  }

  Future<bool> isCheckedToday(Habit habit) async {
    if (habit.id == null) {
      return false;
    }
    return _db.isChecked(habit.id!, dateOnly(DateTime.now()));
  }

  Future<Set<DateTime>> getCheckedDates(Habit habit) async {
    if (habit.id == null) {
      return <DateTime>{};
    }
    return _db.getCheckedDates(habit.id!);
  }

  // ------------------------------------------------------------------ stats

  Future<HabitStats> getHabitStats(Habit habit) async {
    final dates = await getCheckedDates(habit);
    return StreakCalculator.statsFor(dates, habit.createdAt);
  }

  /// Stats for every active habit, keyed by habit id.
  Future<Map<int, HabitStats>> getAllHabitStats() async {
    final habits = await getActiveHabits();
    final result = <int, HabitStats>{};
    for (final habit in habits) {
      final id = habit.id;
      if (id == null) {
        continue;
      }
      result[id] = await getHabitStats(habit);
    }
    return result;
  }

  Future<OverallStats> getOverallStats() async {
    final habits = await getActiveHabits();
    final totalCheckIns = await _db.countAllCheckIns();
    var bestOverall = 0;
    var completionSum = 0.0;
    var checkedToday = 0;
    final today = dateOnly(DateTime.now());
    for (final habit in habits) {
      final dates = await getCheckedDates(habit);
      final stats = StreakCalculator.statsFor(dates, habit.createdAt);
      if (stats.bestStreak > bestOverall) {
        bestOverall = stats.bestStreak;
      }
      completionSum += stats.completionLast30;
      if (dates.contains(today)) {
        checkedToday++;
      }
    }
    return OverallStats(
      totalHabits: habits.length,
      activeHabits: habits.length,
      totalCheckIns: totalCheckIns,
      bestStreakOverall: bestOverall,
      averageCompletion30:
          habits.isEmpty ? 0 : completionSum / habits.length,
      habitsCheckedToday: checkedToday,
      habitsDueToday: habits.length,
    );
  }

  // ------------------------------------------------------------------ notes

  Future<HabitNote> addNote(
    Habit habit,
    DateTime date,
    String text,
  ) async {
    final note = HabitNote(
      habitId: habit.id!,
      date: dateOnly(date),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    final id = await _db.insertNote(note);
    return HabitNote(
      id: id,
      habitId: note.habitId,
      date: note.date,
      text: note.text,
      createdAt: note.createdAt,
    );
  }

  Future<List<HabitNote>> getNotes(Habit habit) async {
    if (habit.id == null) {
      return <HabitNote>[];
    }
    return _db.getNotes(habit.id!);
  }

  Future<void> deleteNote(HabitNote note) async {
    if (note.id != null) {
      await _db.deleteNote(note.id!);
    }
  }

  // ------------------------------------------------------------ data reset

  /// Erases everything (habits, check-ins, notes) and cancels reminders.
  Future<void> deleteAllData() async {
    await _notifications.cancelAllReminders();
    await _db.deleteAllData();
  }
}

/// Convenience alias so tests can reference the check-in type.
typedef CheckInRecord = CheckIn;
