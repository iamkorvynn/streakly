import 'package:material_ui/material_ui.dart';

import '../models/habit.dart';
import '../models/habit_stats.dart';
import '../services/habit_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/habit_card.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';

/// The "Today" tab: today's progress plus every active habit.
///
/// Habits are checked in by tapping the circle on their card, or by
/// tapping a day on the week strip. Tapping a card opens its detail page.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final HabitRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> _habits = <Habit>[];
  Map<int, HabitStats> _stats = <int, HabitStats>{};
  Map<int, Set<DateTime>> _checked = <int, Set<DateTime>>{};
  Map<int, bool> _checkedToday = <int, bool>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await widget.repository.getActiveHabits();
    final stats = await widget.repository.getAllHabitStats();
    final checked = <int, Set<DateTime>>{};
    final checkedToday = <int, bool>{};
    for (final habit in habits) {
      final id = habit.id;
      if (id == null) {
        continue;
      }
      checked[id] = await widget.repository.getCheckedDates(habit);
      checkedToday[id] = await widget.repository.isCheckedToday(habit);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _habits = habits;
      _stats = stats;
      _checked = checked;
      _checkedToday = checkedToday;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            AddEditHabitScreen(repository: widget.repository),
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _openDetail(Habit habit) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => HabitDetailScreen(
          repository: widget.repository,
          habit: habit,
        ),
      ),
    );
    await _load();
  }

  Future<void> _toggleToday(Habit habit) async {
    final nowChecked = await widget.repository.toggleCheckInToday(habit);
    if (!mounted) {
      return;
    }
    // maybeOf: HomeScreen is normally inside MainScaffold's Scaffold,
    // but it must not crash when used standalone (e.g. in tests).
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          nowChecked
              ? '${habit.name} — done for today. Nice!'
              : '${habit.name} — check-in removed.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    await _load();
  }

  Future<void> _toggleDay(Habit habit, DateTime day) async {
    await widget.repository.toggleCheckIn(habit, day);
    await _load();
  }

  String get _motivation {
    final total = _habits.length;
    if (total == 0) {
      return '';
    }
    final done = _checkedToday.values.where((v) => v).length;
    if (done == 0) {
      return 'A fresh day — your streaks are waiting.';
    }
    if (done == total) {
      return 'All done for today. Streaks secured.';
    }
    return '$done of $total done — keep going.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_habits.isEmpty) {
      return EmptyState(
        icon: Icons.local_fire_department,
        title: 'No habits yet',
        message: 'Add your first habit and start a streak. '
            'Small steps, every day.',
        actionLabel: 'Add your first habit',
        onAction: _openAdd,
      );
    }
    final done = _checkedToday.values.where((v) => v).length;
    final progress = _habits.isEmpty ? 0.0 : done / _habits.length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.today,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$done/${_habits.length} done',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _motivation,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ..._habits.map((habit) {
            final id = habit.id;
            final stats = _stats[id] ??
                const HabitStats(
                  currentStreak: 0,
                  bestStreak: 0,
                  totalCheckIns: 0,
                  completionLast7: 0,
                  completionLast30: 0,
                  daysSinceStart: 1,
                );
            return HabitCard(
              habit: habit,
              stats: stats,
              checkedDays: _checked[id] ?? <DateTime>{},
              checkedToday: _checkedToday[id] ?? false,
              onTap: () => _openDetail(habit),
              onToggleToday: () => _toggleToday(habit),
              onToggleDay: (day) => _toggleDay(habit, day),
            );
          }),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}
