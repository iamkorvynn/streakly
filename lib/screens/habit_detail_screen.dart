import 'package:material_ui/material_ui.dart';

import '../models/habit.dart';
import '../models/habit_note.dart';
import '../models/habit_stats.dart';
import '../services/habit_repository.dart';
import '../utils/date_utils.dart';
import '../utils/reminder_time.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/stat_chip.dart';
import '../widgets/streak_badge.dart';
import '../widgets/week_strip.dart';
import 'add_edit_habit_screen.dart';

/// Full view of one habit: streaks, heatmap, month calendar, notes,
/// and edit / archive / delete actions.
class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({
    super.key,
    required this.repository,
    required this.habit,
  });

  final HabitRepository repository;
  final Habit habit;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late Habit _habit;
  HabitStats? _stats;
  Set<DateTime> _checked = <DateTime>{};
  List<HabitNote> _notes = <HabitNote>[];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _noteController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fresh = await widget.repository.getHabit(_habit.id!);
    if (fresh != null) {
      _habit = fresh;
    }
    final stats = await widget.repository.getHabitStats(_habit);
    final checked = await widget.repository.getCheckedDates(_habit);
    final notes = await widget.repository.getNotes(_habit);
    if (!mounted) {
      return;
    }
    setState(() {
      _stats = stats;
      _checked = checked;
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _toggleToday() async {
    await widget.repository.toggleCheckInToday(_habit);
    await _load();
  }

  Future<void> _toggleDay(DateTime day) async {
    await widget.repository.toggleCheckIn(_habit, day);
    await _load();
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      return;
    }
    await widget.repository.addNote(_habit, DateTime.now(), text);
    _noteController.clear();
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
    await _load();
  }

  Future<void> _deleteNote(HabitNote note) async {
    await widget.repository.deleteNote(note);
    await _load();
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => AddEditHabitScreen(
          repository: widget.repository,
          habit: _habit,
        ),
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _archive() async {
    await widget.repository.archiveHabit(_habit, true);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_habit.name} archived.')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'This deletes "${_habit.name}" plus all its check-ins and notes. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.repository.deleteHabit(_habit);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(
        title: Text(_habit.name),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit habit',
            onPressed: _edit,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archive') {
                _archive();
              } else if (value == 'delete') {
                _delete();
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'archive',
                child: Text('Archive habit'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete habit'),
              ),
            ],
          ),
        ],
      ),
      body: _loading || stats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HeaderCard(
                    habit: _habit,
                    stats: stats,
                    onToggleToday: _toggleToday,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatChip(
                          label: 'Current streak',
                          value: '${stats.currentStreak}',
                          icon: Icons.local_fire_department,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatChip(
                          label: 'Best streak',
                          value: '${stats.bestStreak}',
                          icon: Icons.emoji_events,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatChip(
                          label: 'Total days',
                          value: '${stats.totalCheckIns}',
                          icon: Icons.check_circle,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatChip(
                          label: 'Last 30 days',
                          value:
                              '${(stats.completionLast30 * 100).round()}%',
                          icon: Icons.percent,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('This week'),
                  const SizedBox(height: 12),
                  WeekStrip(
                    checkedDays: _checked,
                    color: _habit.color,
                    onToggleDay: _toggleDay,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('History'),
                  const SizedBox(height: 12),
                  HeatmapWidget(
                    checkedDays: _checked,
                    color: _habit.color,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    '${monthLabels[_month.month - 1]} ${_month.year}',
                  ),
                  const SizedBox(height: 12),
                  _MonthGrid(
                    month: _month,
                    checkedDays: _checked,
                    color: _habit.color,
                    onPrevious: () => setState(
                      () => _month =
                          DateTime(_month.year, _month.month - 1),
                    ),
                    onNext: () => setState(
                      () => _month =
                          DateTime(_month.year, _month.month + 1),
                    ),
                    onToggleDay: _toggleDay,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Notes'),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Add a note for today…',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onSubmitted: (_) => _addNote(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addNote,
                        icon: const Icon(Icons.add),
                        tooltip: 'Add note',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_notes.isEmpty)
                    Text(
                      'No notes yet. Notes are a good place to record '
                      'what helped — or what got in the way.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else
                    ..._notes.map(
                      (note) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(note.text),
                          subtitle: Text(
                            '${note.date.day} '
                            '${monthLabels[note.date.month - 1]} '
                            '${note.date.year}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete note',
                            onPressed: () => _deleteNote(note),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_habit.reminderMinutes != null)
                    ListTile(
                      leading: Icon(Icons.alarm, color: _habit.color),
                      title: const Text('Daily reminder'),
                      subtitle: Text(
                        formatReminderMinutes12h(_habit.reminderMinutes!),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  Text(
                    'Started ${_habit.createdAt.day} '
                    '${monthLabels[_habit.createdAt.month - 1]} '
                    '${_habit.createdAt.year} • '
                    '${stats.daysSinceStart} days in',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.habit,
    required this.stats,
    required this.onToggleToday,
  });

  final Habit habit;
  final HabitStats stats;
  final VoidCallback onToggleToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: habit.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(habit.icon, color: habit.color, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StreakBadge(streak: stats.currentStreak, large: true),
                  const SizedBox(height: 4),
                  Text(
                    'day streak',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: stats.progressToTarget(habit.targetDays),
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(habit.color),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.currentStreak} of ${habit.targetDays} days '
                    'to target',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onToggleToday,
              style: FilledButton.styleFrom(
                backgroundColor: habit.color,
              ),
              child: const Text('Check in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.checkedDays,
    required this.color,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleDay,
  });

  final DateTime month;
  final Set<DateTime> checkedDays;
  final Color color;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final void Function(DateTime day) onToggleDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = dateOnly(DateTime.now());
    final total = daysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final checked = checkedDays.map(dateOnly).toSet();
    final cells = <Widget>[];
    for (var i = 0; i < firstWeekday - 1; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= total; day++) {
      final date = DateTime(month.year, month.month, day);
      final isChecked = checked.contains(date);
      final isToday = isSameDay(date, now);
      final isFuture = date.isAfter(now);
      cells.add(
        InkWell(
          onTap: isFuture ? null : () => onToggleDay(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isChecked ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: color, width: 2)
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
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
              tooltip: 'Previous month',
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weekdayLabels
                    .map(
                      (label) => Text(
                        label[0],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
              tooltip: 'Next month',
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1,
          children: cells,
        ),
      ],
    );
  }
}
