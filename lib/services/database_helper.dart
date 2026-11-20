import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/check_in.dart';
import '../models/habit.dart';
import '../models/habit_note.dart';
import '../utils/date_utils.dart';

/// SQLite storage for Streakly. Local only — no network, no sync.
///
/// Tables:
/// * `habits` — one row per habit.
/// * `check_ins` — one row per checked day, UNIQUE per habit + date.
/// * `notes` — free-text notes attached to a day of a habit.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'streakly.db';
  static const int _dbVersion = 1;

  Database? _db;

  /// Opens (creating on first run) and returns the database.
  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_index INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        target_days INTEGER NOT NULL DEFAULT 30,
        reminder_minutes INTEGER,
        created_at TEXT NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE check_ins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE (habit_id, date),
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_check_ins_habit ON check_ins (habit_id, date)',
    );
    await db.execute(
      'CREATE INDEX idx_notes_habit ON notes (habit_id, date)',
    );
  }

  // ---------------------------------------------------------------- habits

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getHabits({bool archived = false}) async {
    final db = await database;
    final rows = await db.query(
      'habits',
      where: 'archived = ?',
      whereArgs: <Object>[archived ? 1 : 0],
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<Habit?> getHabit(int id) async {
    final db = await database;
    final rows = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      return null;
    }
    return Habit.fromMap(rows.first);
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    await db.delete('check_ins', where: 'habit_id = ?', whereArgs: [id]);
    await db.delete('notes', where: 'habit_id = ?', whereArgs: [id]);
    return db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countHabits({bool archived = false}) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM habits WHERE archived = ?',
      <Object>[archived ? 1 : 0],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  // -------------------------------------------------------------- check-ins

  Future<bool> isChecked(int habitId, DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'check_ins',
      where: 'habit_id = ? AND date = ?',
      whereArgs: <Object>[habitId, toDateKey(date)],
    );
    return rows.isNotEmpty;
  }

  /// Inserts a check-in for [date]; returns false if one already exists.
  Future<bool> insertCheckIn(int habitId, DateTime date) async {
    final db = await database;
    final now = DateTime.now();
    final id = await db.insert(
      'check_ins',
      CheckIn(
        habitId: habitId,
        date: dateOnly(date),
        createdAt: now,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return id != 0;
  }

  Future<int> deleteCheckIn(int habitId, DateTime date) async {
    final db = await database;
    return db.delete(
      'check_ins',
      where: 'habit_id = ? AND date = ?',
      whereArgs: <Object>[habitId, toDateKey(date)],
    );
  }

  /// All checked dates for a habit, as date-only values.
  Future<Set<DateTime>> getCheckedDates(int habitId) async {
    final db = await database;
    final rows = await db.query(
      'check_ins',
      columns: <String>['date'],
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
    return rows
        .map((row) => parseDateKey(row['date'] as String))
        .toSet();
  }

  Future<int> countCheckIns(int habitId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM check_ins WHERE habit_id = ?',
      [habitId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countAllCheckIns() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM check_ins');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  // ------------------------------------------------------------------ notes

  Future<int> insertNote(HabitNote note) async {
    final db = await database;
    return db.insert('notes', note.toMap());
  }

  Future<List<HabitNote>> getNotes(int habitId) async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(HabitNote.fromMap).toList();
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes every row in every table. Used by Settings > Erase all data.
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('check_ins');
    await db.delete('notes');
    await db.delete('habits');
  }

  /// Test helper: closes the database so a fresh one can be opened.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
