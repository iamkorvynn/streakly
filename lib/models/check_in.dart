import '../utils/date_utils.dart';

/// One completed day for a habit.
///
/// Stored in the `check_ins` table. A habit can have at most one check-in
/// per day (enforced by a UNIQUE constraint on habit + date).
class CheckIn {
  const CheckIn({
    this.id,
    required this.habitId,
    required this.date,
    required this.createdAt,
  });

  final int? id;
  final int habitId;

  /// The day that was checked in, date-only.
  final DateTime date;
  final DateTime createdAt;

  /// The `yyyy-MM-dd` key for [date].
  String get dateKey => toDateKey(date);

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'habit_id': habitId,
      'date': dateKey,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CheckIn.fromMap(Map<String, Object?> map) {
    return CheckIn(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      date: parseDateKey(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
