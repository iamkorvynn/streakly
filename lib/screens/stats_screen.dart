import 'package:material_ui/material_ui.dart';

import '../models/habit_stats.dart';
import '../services/habit_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_chip.dart';

/// The "Stats" tab: totals across all habits plus a per-habit breakdown.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.repository});

  final HabitRepository repository;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  OverallStats? _overall;
  Map<int, HabitStats> _perHabit = <int, HabitStats>{};
  List<String> _names = <String>[];
  List<int> _ids = <int>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final overall = await widget.repository.getOverallStats();
    final habits = await widget.repository.getActiveHabits();
    final perHabit = await widget.repository.getAllHabitStats();
    if (!mounted) {
      return;
    }
    setState(() {
      _overall = overall;
      _perHabit = perHabit;
      _names = habits.map((h) => h.name).toList();
      _ids = habits.map((h) => h.id!).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final overall = _overall;
    if (overall == null || overall.activeHabits == 0) {
      return const EmptyState(
        icon: Icons.bar_chart,
        title: 'No stats yet',
        message: 'Add a habit and check in a few days — '
            'your numbers will show up here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Your numbers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: StatChip(
                  label: 'Total check-ins',
                  value: '${overall.totalCheckIns}',
                  icon: Icons.check_circle,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatChip(
                  label: 'Best streak',
                  value: '${overall.bestStreakOverall}',
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: StatChip(
                  label: 'Today',
                  value:
                      '${overall.habitsCheckedToday}/${overall.habitsDueToday}',
                  icon: Icons.today,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatChip(
                  label: 'Avg last 30 days',
                  value:
                      '${(overall.averageCompletion30 * 100).round()}%',
                  icon: Icons.percent,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Per habit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(_ids.length, (index) {
            final id = _ids[index];
            final stats = _perHabit[id];
            if (stats == null) {
              return const SizedBox.shrink();
            }
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _names[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${stats.currentStreak} day streak',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: stats.completionLast30,
                      backgroundColor: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last 30 days: '
                      '${(stats.completionLast30 * 100).round()}%  •  '
                      'Best ${stats.bestStreak}  •  '
                      '${stats.totalCheckIns} total',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}
