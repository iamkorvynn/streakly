import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:streakly/models/habit.dart';
import 'package:streakly/models/habit_note.dart';
import 'package:streakly/services/database_helper.dart';

void main() {
  late DatabaseHelper db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = DatabaseHelper.instance;
    await db.deleteAllData();
  });

  tearDown(() async {
    await db.deleteAllData();
    await db.close();
    // Remove the test database file so each test starts clean.
    final path = await getDatabasesPath();
    await deleteDatabase('$path/streakly.db');
  });

  Habit _habit({String name = 'Read'}) => Habit(
        name: name,
        iconCodePoint: 0xe3a1,
        colorValue: 0xFFE64A19,
        createdAt: DateTime(2026, 11, 1),
      );

  group('habits', () {
    test('insert then get returns the habit', () async {
      final id = await db.insertHabit(_habit());
      final fetched = await db.getHabit(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Read');
      expect(fetched.targetDays, 30);
      expect(fetched.archived, isFalse);
    });

    test('getHabits filters archived', () async {
      final id1 = await db.insertHabit(_habit(name: 'Read'));
      final id2 = await db.insertHabit(_habit(name: 'Run'));
      final habit2 = (await db.getHabit(id2))!;
      await db.updateHabit(habit2.copyWith(archived: true));
      final active = await db.getHabits(archived: false);
      final archived = await db.getHabits(archived: true);
      expect(active.map((h) => h.id), [id1]);
      expect(archived.map((h) => h.id), [id2]);
    });

    test('update changes the name', () async {
      final id = await db.insertHabit(_habit());
      final habit = (await db.getHabit(id))!;
      await db.updateHabit(habit.copyWith(name: 'Read 10 pages'));
      expect((await db.getHabit(id))!.name, 'Read 10 pages');
    });

    test('delete removes habit, check-ins and notes', () async {
      final id = await db.insertHabit(_habit());
      await db.insertCheckIn(id, DateTime(2026, 11, 20));
      await db.insertNote(HabitNote(
        habitId: id,
        date: DateTime(2026, 11, 20),
        text: 'note',
        createdAt: DateTime.now(),
      ));
      await db.deleteHabit(id);
      expect(await db.getHabit(id), isNull);
      expect(await db.getCheckedDates(id), isEmpty);
      expect(await db.getNotes(id), isEmpty);
    });

    test('countHabits counts active habits', () async {
      await db.insertHabit(_habit(name: 'A'));
      await db.insertHabit(_habit(name: 'B'));
      expect(await db.countHabits(), 2);
    });
  });

  group('check-ins', () {
    test('insert and isChecked round-trip', () async {
      final id = await db.insertHabit(_habit());
      expect(await db.isChecked(id, DateTime(2026, 11, 20)), isFalse);
      expect(await db.insertCheckIn(id, DateTime(2026, 11, 20)), isTrue);
      expect(await db.isChecked(id, DateTime(2026, 11, 20)), isTrue);
    });

    test('duplicate check-in for the same day is ignored', () async {
      final id = await db.insertHabit(_habit());
      expect(await db.insertCheckIn(id, DateTime(2026, 11, 20)), isTrue);
      expect(await db.insertCheckIn(id, DateTime(2026, 11, 20)), isFalse);
      expect(await db.countCheckIns(id), 1);
    });

    test('delete removes the check-in', () async {
      final id = await db.insertHabit(_habit());
      await db.insertCheckIn(id, DateTime(2026, 11, 20));
      await db.deleteCheckIn(id, DateTime(2026, 11, 20));
      expect(await db.isChecked(id, DateTime(2026, 11, 20)), isFalse);
    });

    test('getCheckedDates returns all dates', () async {
      final id = await db.insertHabit(_habit());
      await db.insertCheckIn(id, DateTime(2026, 11, 18));
      await db.insertCheckIn(id, DateTime(2026, 11, 20));
      final dates = await db.getCheckedDates(id);
      expect(
        dates,
        {DateTime(2026, 11, 18), DateTime(2026, 11, 20)},
      );
    });
  });

  group('notes', () {
    test('insert, list newest first, delete', () async {
      final id = await db.insertHabit(_habit());
      final noteId = await db.insertNote(HabitNote(
        habitId: id,
        date: DateTime(2026, 11, 19),
        text: 'First note',
        createdAt: DateTime.now(),
      ));
      await db.insertNote(HabitNote(
        habitId: id,
        date: DateTime(2026, 11, 20),
        text: 'Second note',
        createdAt: DateTime.now(),
      ));
      final notes = await db.getNotes(id);
      expect(notes.length, 2);
      expect(notes.first.text, 'Second note');
      await db.deleteNote(noteId);
      expect((await db.getNotes(id)).length, 1);
    });
  });

  group('deleteAllData', () {
    test('wipes habits, check-ins and notes', () async {
      final id = await db.insertHabit(_habit());
      await db.insertCheckIn(id, DateTime(2026, 11, 20));
      await db.deleteAllData();
      expect(await db.getHabits(), isEmpty);
      expect(await db.countAllCheckIns(), 0);
    });
  });
}
