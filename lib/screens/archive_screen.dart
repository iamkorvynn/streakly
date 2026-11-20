import 'package:material_ui/material_ui.dart';

import '../models/habit.dart';
import '../services/habit_repository.dart';
import '../widgets/empty_state.dart';

/// Archived habits: restore them to the home list or delete them for good.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key, required this.repository});

  final HabitRepository repository;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Habit> _habits = <Habit>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await widget.repository.getArchivedHabits();
    if (!mounted) {
      return;
    }
    setState(() {
      _habits = habits;
      _loading = false;
    });
  }

  Future<void> _restore(Habit habit) async {
    await widget.repository.archiveHabit(habit, false);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${habit.name} restored.')),
    );
    await _load();
  }

  Future<void> _delete(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'This permanently deletes "${habit.name}" plus all its '
          'check-ins and notes.',
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
    await widget.repository.deleteHabit(habit);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived habits')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const EmptyState(
                  icon: Icons.archive,
                  title: 'Nothing archived',
                  message: 'Habits you archive will wait here until '
                      'you restore or delete them.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: habit.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(habit.icon, color: habit.color),
                        ),
                        title: Text(habit.name),
                        subtitle: const Text('Archived'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.unarchive),
                              tooltip: 'Restore',
                              onPressed: () => _restore(habit),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete forever',
                              onPressed: () => _delete(habit),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
