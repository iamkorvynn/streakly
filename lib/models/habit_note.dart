import '../utils/date_utils.dart';

/// A free-text note attached to one day of a habit.
///
/// Stored in the `notes` table. Notes are shown on the habit detail
/// screen as a timeline, newest first.
class HabitNote {
  const HabitNote({
    this.id,
    required this.habitId,
    required this.date,
    required this.text,
    required this.createdAt,
  });

  final int? id;
  final int habitId;

  /// The day the note belongs to, date-only.
  final DateTime date;

  /// The note text (1..500 characters).
  final String text;
  final DateTime createdAt;

  /// The `yyyy-MM-dd` key for [date].
  String get dateKey => toDateKey(date);

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'habit_id': habitId,
      'date': dateKey,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitNote.fromMap(Map<String, Object?> map) {
    return HabitNote(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      date: parseDateKey(map['date'] as String),
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
