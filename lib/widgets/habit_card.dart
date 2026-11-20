import 'package:material_ui/material_ui.dart';

import '../models/habit.dart';
import '../models/habit_stats.dart';
import 'streak_badge.dart';
import 'week_strip.dart';

/// One habit row on the home screen.
///
/// Shows the icon, name, current streak, a tappable week strip and a
/// progress bar toward the target streak. Tapping the card opens the
/// habit detail screen; tapping the check button toggles today.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.stats,
    required this.checkedDays,
    required this.checkedToday,
    required this.onTap,
    required this.onToggleToday,
    required this.onToggleDay,
  });

  final Habit habit;
  final HabitStats stats;
  final Set<DateTime> checkedDays;
  final bool checkedToday;
  final VoidCallback onTap;
  final VoidCallback onToggleToday;
  final void Function(DateTime day) onToggleDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = stats.progressToTarget(habit.targetDays);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: habit.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(habit.icon, color: habit.color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Best ${stats.bestStreak}  •  '
                          '${stats.totalCheckIns} days total',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreakBadge(streak: stats.currentStreak),
                  const SizedBox(width: 8),
                  _CheckButton(
                    checked: checkedToday,
                    color: habit.color,
                    onTap: onToggleToday,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              WeekStrip(
                checkedDays: checkedDays,
                color: habit.color,
                onToggleDay: onToggleDay,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          scheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(habit.color),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.currentStreak}/${habit.targetDays} day'
                    '${habit.targetDays == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.checked,
    required this.color,
    required this.onTap,
  });

  final bool checked;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
        child: checked
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : Icon(Icons.check, color: color, size: 22),
      ),
    );
  }
}
