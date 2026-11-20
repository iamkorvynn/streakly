// In-memory fake of HabitRepository for widget tests.
//
// Widget tests should verify widgets, not wait on the SQLite ffi isolate
// (which is CPU-starved on this VM and makes pumpAndSettle time out).
// Real storage is covered by database_test.dart and repository_test.dart.
import 'package:streakly/models/habit.dart';
import 'package:streakly/models/habit_note.dart';
import 'package:streakly/models/habit_stats.dart';
import 'package:streakly/services/habit_repository.dart';
import 'package:streakly/services/streak_calculator.dart';
import 'package:streakly/utils/date_utils.dart';

class FakeHabitRepository extends HabitRepository {
  FakeHabitRepository();

  final Map<int, Habit> _habits = <int, Habit>{};
  final Map<int, Set<DateTime>> _checkIns = <int, Set<DateTime>>{};
  final Map<int, List<HabitNote>> _notes = <int, List<HabitNote>>{};
  int _nextHabitId = 1;
  int _nextNoteId = 1;

  @override
  Future<List<Habit>> getActiveHabits() async {
    final list = _habits.values.where((h) => !h.archived).toList();
    list.sort((a, b) => a.id!.compareTo(b.id!));
    return list;
  }

  @override
  Future<List<Habit>> getArchivedHabits() async {
    final list = _habits.values.where((h) => h.archived).toList();
    list.sort((a, b) => a.id!.compareTo(b.id!));
    return list;
  }

  @override
  Future<Habit?> getHabit(int id) async => _habits[id];

  @override
  Future<Habit> createHabit(Habit habit) async {
    final created = habit.copyWith(id: _nextHabitId++);
    _habits[created.id!] = created;
    _checkIns[created.id!] = <DateTime>{};
    _notes[created.id!] = <HabitNote>[];
    return created;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    if (habit.id != null) {
      _habits[habit.id!] = habit;
    }
  }

  @override
  Future<void> deleteHabit(Habit habit) async {
    if (habit.id == null) {
      return;
    }
    _habits.remove(habit.id);
    _checkIns.remove(habit.id);
    _notes.remove(habit.id);
  }

  @override
  Future<void> archiveHabit(Habit habit, bool archived) async {
    final id = habit.id;
    if (id == null) {
      return;
    }
    _habits[id] = habit.copyWith(archived: archived);
  }

  @override
  Future<bool> toggleCheckInToday(Habit habit) async {
    return toggleCheckIn(habit, dateOnly(DateTime.now()));
  }

  @override
  Future<bool> toggleCheckIn(Habit habit, DateTime date) async {
    final id = habit.id;
    if (id == null) {
      return false;
    }
    final day = dateOnly(date);
    final set = _checkIns.putIfAbsent(id, () => <DateTime>{});
    if (set.contains(day)) {
      set.remove(day);
      return false;
    }
    set.add(day);
    return true;
  }

  @override
  Future<bool> isCheckedToday(Habit habit) async {
    final id = habit.id;
    if (id == null) {
      return false;
    }
    return _checkIns[id]?.contains(dateOnly(DateTime.now())) ?? false;
  }

  @override
  Future<Set<DateTime>> getCheckedDates(Habit habit) async {
    if (habit.id == null) {
      return <DateTime>{};
    }
    return Set<DateTime>.of(_checkIns[habit.id!] ?? <DateTime>{});
  }

  @override
  Future<HabitStats> getHabitStats(Habit habit) async {
    final dates = await getCheckedDates(habit);
    return StreakCalculator.statsFor(dates, habit.createdAt);
  }

  @override
  Future<Map<int, HabitStats>> getAllHabitStats() async {
    final habits = await getActiveHabits();
    final result = <int, HabitStats>{};
    for (final habit in habits) {
      result[habit.id!] = await getHabitStats(habit);
    }
    return result;
  }

  @override
  Future<OverallStats> getOverallStats() async {
    final habits = await getActiveHabits();
    var totalCheckIns = 0;
    var bestOverall = 0;
    var completionSum = 0.0;
    var checkedToday = 0;
    final today = dateOnly(DateTime.now());
    for (final habit in habits) {
      final dates = await getCheckedDates(habit);
      totalCheckIns += dates.length;
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

  @override
  Future<HabitNote> addNote(Habit habit, DateTime date, String text) async {
    final note = HabitNote(
      id: _nextNoteId++,
      habitId: habit.id!,
      date: dateOnly(date),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    _notes.putIfAbsent(habit.id!, () => <HabitNote>[]).add(note);
    return note;
  }

  @override
  Future<List<HabitNote>> getNotes(Habit habit) async {
    if (habit.id == null) {
      return <HabitNote>[];
    }
    final list = List<HabitNote>.of(_notes[habit.id!] ?? <HabitNote>[]);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<void> deleteNote(HabitNote note) async {
    final list = _notes[note.habitId];
    list?.removeWhere((n) => n.id == note.id);
  }

  @override
  Future<void> deleteAllData() async {
    _habits.clear();
    _checkIns.clear();
    _notes.clear();
  }
}
