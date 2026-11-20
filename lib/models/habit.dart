import 'package:material_ui/material_ui.dart';

import '../utils/app_icons.dart';
import '../utils/date_utils.dart';

/// A habit the user wants to build.
///
/// Stored in the `habits` SQLite table. Dates are kept as `yyyy-MM-dd`
/// strings; reminder times as minutes since midnight (null = no reminder).
class Habit {
  const Habit({
    this.id,
    required this.name,
    required this.iconIndex,
    required this.colorValue,
    this.targetDays = 30,
    this.reminderMinutes,
    required this.createdAt,
    this.archived = false,
    this.sortOrder = 0,
  });

  final int? id;
  final String name;

  /// Index into [habitIconOptions]. Stored instead of a code point
  /// because Flutter 3.50's IconData requires constant arguments.
  final int iconIndex;

  /// ARGB colour value of the habit.
  final int colorValue;

  /// The streak length the user is aiming for (7..365).
  final int targetDays;

  /// Daily reminder time, minutes since midnight. Null disables reminders.
  final int? reminderMinutes;

  final DateTime createdAt;
  final bool archived;
  final int sortOrder;

  /// The Material icon for this habit.
  IconData get icon {
    final index = iconIndex.clamp(0, habitIconOptions.length - 1);
    return habitIconOptions[index].icon;
  }

  /// The display colour for this habit.
  Color get color => Color(colorValue);

  /// True when a daily reminder is enabled.
  bool get hasReminder => reminderMinutes != null;

  /// Reminder time as a [TimeOfDay], or null when reminders are off.
  TimeOfDay? get reminderTimeOfDay => reminderMinutes == null
      ? null
      : TimeOfDay(
          hour: reminderMinutes! ~/ 60,
          minute: reminderMinutes! % 60,
        );

  Habit copyWith({
    int? id,
    String? name,
    int? iconIndex,
    int? colorValue,
    int? targetDays,
    int? reminderMinutes,
    bool clearReminder = false,
    DateTime? createdAt,
    bool? archived,
    int? sortOrder,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      iconIndex: iconIndex ?? this.iconIndex,
      colorValue: colorValue ?? this.colorValue,
      targetDays: targetDays ?? this.targetDays,
      reminderMinutes: clearReminder
          ? null
          : (reminderMinutes ?? this.reminderMinutes),
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'icon_index': iconIndex,
      'color_value': colorValue,
      'target_days': targetDays,
      'reminder_minutes': reminderMinutes,
      'created_at': toDateKey(createdAt),
      'archived': archived ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory Habit.fromMap(Map<String, Object?> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconIndex: map['icon_index'] as int? ?? 0,
      colorValue: map['color_value'] as int,
      targetDays: map['target_days'] as int? ?? 30,
      reminderMinutes: map['reminder_minutes'] as int?,
      createdAt: parseDateKey(map['created_at'] as String),
      archived: (map['archived'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
