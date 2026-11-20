import 'package:material_ui/material_ui.dart';

import '../models/habit.dart';
import '../services/habit_repository.dart';
import '../services/streak_calculator.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_chip.dart';
import 'habit_detail_screen.dart';

/// The "Calendar" tab: a month heatmap for one habit at a time.
///
/// Pick a habit from the dropdown, flip months, and tap a day to toggle
/// its check-in.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.repository});

  final HabitRepository repository;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Habit> _habits = <Habit>[];
  Habit? _selected;
  Set<DateTime> _checked = <DateTime>{};
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await widget.repository.getActiveHabits();
    Habit? selected = _selected;
    if (habits.isEmpty) {
      selected = null;
    } else if (selected == null ||
        !habits.any((h) => h.id == selected!.id)) {
      selected = habits.first;
    }
    Set<DateTime> checked = <DateTime>{};
    if (selected != null) {
      checked = await widget.repository.getCheckedDates(selected);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _habits = habits;
      _selected = selected;
      _checked = checked;
      _loading = false;
    });
  }

  Future<void> _toggleDay(DateTime day) async {
    final habit = _selected;
    if (habit == null) {
      return;
    }
    await widget.repository.toggleCheckIn(habit, day);
    await _load();
  }

  void _openDetail() {
    final habit = _selected;
    if (habit == null) {
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => HabitDetailScreen(
          repository: widget.repository,
          habit: habit,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_habits.isEmpty || _selected == null) {
      return const EmptyState(
        icon: Icons.calendar_month,
        title: 'No habits to show',
        message: 'Add a habit first, then its calendar will appear here.',
      );
    }
    final habit = _selected!;
    final monthStat = StreakCalculator.monthStats(
      _checked,
      _month.year,
      _month.month,
    );
    final rate = monthStat.total == 0
        ? 0
        : (monthStat.checked / monthStat.total * 100).round();
    final now = dateOnly(DateTime.now());
    final total = daysInMonth(_month.year, _month.month);
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final checked = _checked.map(dateOnly).toSet();
    final cells = <Widget>[];
    for (var i = 0; i < firstWeekday - 1; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= total; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final isChecked = checked.contains(date);
      final isToday = isSameDay(date, now);
      final isFuture = date.isAfter(now);
      cells.add(
        InkWell(
          onTap: isFuture ? null : () => _toggleDay(date),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isChecked ? habit.color : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday
                  ? Border.all(color: habit.color, width: 2)
                  : Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isChecked
                      ? Colors.white
                      : isFuture
                          ? scheme.onSurface.withValues(alpha: 0.35)
                          : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DropdownButtonFormField<Habit>(
            value: habit,
            decoration: const InputDecoration(
              labelText: 'Habit',
              border: OutlineInputBorder(),
            ),
            items: _habits
                .map(
                  (h) => DropdownMenuItem<Habit>(
                    value: h,
                    child: Row(
                      children: <Widget>[
                        Icon(h.icon, color: h.color, size: 20),
                        const SizedBox(width: 8),
                        Text(h.name),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selected = value);
                _load();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                tooltip: 'Previous month',
              ),
              Expanded(
                child: Text(
                  '${monthLabels[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                tooltip: 'Next month',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weekdayLabels
                .map(
                  (label) => Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
            children: cells,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: StatChip(
                  label: 'Days done',
                  value: '${monthStat.checked}/${monthStat.total}',
                  icon: Icons.check_circle,
                  color: habit.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatChip(
                  label: 'This month',
                  value: '$rate%',
                  icon: Icons.percent,
                  color: habit.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openDetail,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open habit details'),
            ),
          ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}
