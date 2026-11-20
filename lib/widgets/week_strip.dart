import 'package:material_ui/material_ui.dart';

import '../utils/date_utils.dart';

/// A 7-dot strip for the current week (Mon..Sun).
///
/// Filled dots are checked days, hollow dots are missed or future days,
/// and today gets a ring. Tapping a dot toggles that day (past days and
/// today only — future days are not tappable).
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.checkedDays,
    required this.color,
    this.onToggleDay,
    this.today,
  });

  /// Set of checked dates (date-only).
  final Set<DateTime> checkedDays;

  /// The habit colour used for filled dots.
  final Color color;

  /// Called with the tapped day when it is today or in the past.
  final void Function(DateTime day)? onToggleDay;

  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final now = dateOnly(today ?? DateTime.now());
    final monday = startOfWeek(now);
    final days = List<DateTime>.generate(
      7,
      (i) => monday.add(Duration(days: i)),
    );
    final checked = checkedDays.map(dateOnly).toSet();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final isToday = isSameDay(day, now);
        final isFuture = day.isAfter(now);
        final isChecked = checked.contains(day);
        final label = weekdayLabels[day.weekday - 1][0];
        final dot = Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isChecked ? color : Colors.transparent,
            border: Border.all(
              color: isToday ? color : color.withValues(alpha: 0.45),
              width: isToday ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: isChecked
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      color: isFuture
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
          ),
        );
        if (isFuture || onToggleDay == null) {
          return dot;
        }
        return InkWell(
          onTap: () => onToggleDay!(day),
          borderRadius: BorderRadius.circular(15),
          child: dot,
        );
      }).toList(),
    );
  }
}
