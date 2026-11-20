import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:streakly/models/habit.dart';
import 'package:streakly/services/database_helper.dart';
import 'package:streakly/services/habit_repository.dart';

void main() {
  late HabitRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Own database file: test files run in parallel and would
    // otherwise lock each other's database.
    DatabaseHelper.databaseName = 'test_repository.db';
  });

  setUp(() async {
    repo = HabitRepository();
    await DatabaseHelper.instance.deleteAllData();
  });

  tearDown(() async {
    await DatabaseHelper.instance.deleteAllData();
    await DatabaseHelper.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/test_repository.db');
  });

  Habit makeHabit({String name = 'Read', int? reminderMinutes}) => Habit(
        name: name,
        iconIndex: 2,
        colorValue: 0xFFE64A19,
        reminderMinutes: reminderMinutes,
        createdAt: DateTime.now(),
      );

  test('create then list active habits', () async {
    await repo.createHabit(makeHabit(name: 'Read'));
    await repo.createHabit(makeHabit(name: 'Run'));
    final habits = await repo.getActiveHabits();
    expect(habits.map((h) => h.name), ['Read', 'Run']);
  });

  test('toggleCheckInToday flips state', () async {
    final habit = await repo.createHabit(makeHabit());
    expect(await repo.isCheckedToday(habit), isFalse);
    expect(await repo.toggleCheckInToday(habit), isTrue);
    expect(await repo.isCheckedToday(habit), isTrue);
    expect(await repo.toggleCheckInToday(habit), isFalse);
    expect(await repo.isCheckedToday(habit), isFalse);
  });

  test('toggleCheckIn works for past days', () async {
    final habit = await repo.createHabit(makeHabit());
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(await repo.toggleCheckIn(habit, yesterday), isTrue);
    final dates = await repo.getCheckedDates(habit);
    expect(dates.length, 1);
  });

  test('stats reflect check-ins', () async {
    final habit = await repo.createHabit(makeHabit());
    final today = DateTime.now();
    await repo.toggleCheckIn(habit, today.subtract(const Duration(days: 1)));
    await repo.toggleCheckIn(habit, today);
    final stats = await repo.getHabitStats(habit);
    expect(stats.currentStreak, 2);
    expect(stats.bestStreak, 2);
    expect(stats.totalCheckIns, 2);
  });

  test('archive hides the habit and restore brings it back', () async {
    final habit = await repo.createHabit(makeHabit());
    await repo.archiveHabit(habit, true);
    expect(await repo.getActiveHabits(), isEmpty);
    expect((await repo.getArchivedHabits()).length, 1);
    final archived = (await repo.getArchivedHabits()).first;
    await repo.archiveHabit(archived, false);
    expect((await repo.getActiveHabits()).length, 1);
  });

  test('delete removes the habit entirely', () async {
    final habit = await repo.createHabit(makeHabit());
    await repo.toggleCheckInToday(habit);
    await repo.deleteHabit(habit);
    expect(await repo.getActiveHabits(), isEmpty);
  });

  test('notes round-trip through the repository', () async {
    final habit = await repo.createHabit(makeHabit());
    await repo.addNote(habit, DateTime.now(), 'Great session');
    final notes = await repo.getNotes(habit);
    expect(notes.length, 1);
    expect(notes.first.text, 'Great session');
    await repo.deleteNote(notes.first);
    expect(await repo.getNotes(habit), isEmpty);
  });

  test('overall stats aggregate across habits', () async {
    final a = await repo.createHabit(makeHabit(name: 'A'));
    final b = await repo.createHabit(makeHabit(name: 'B'));
    await repo.toggleCheckInToday(a);
    await repo.toggleCheckInToday(b);
    final overall = await repo.getOverallStats();
    expect(overall.totalHabits, 2);
    expect(overall.totalCheckIns, 2);
    expect(overall.habitsCheckedToday, 2);
    expect(overall.todayProgress, 1.0);
  });

  test('deleteAllData wipes everything', () async {
    await repo.createHabit(makeHabit());
    await repo.deleteAllData();
    expect(await repo.getActiveHabits(), isEmpty);
  });

  test('creating a habit with a reminder does not throw', () async {
    // In tests the notification plugin is unavailable; the repository
    // must still create the habit without throwing.
    final habit = await repo.createHabit(
      makeHabit(reminderMinutes: 8 * 60),
    );
    expect(habit.id, isNotNull);
    expect((await repo.getActiveHabits()).length, 1);
  });
}
