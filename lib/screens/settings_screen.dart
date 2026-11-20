import 'package:material_ui/material_ui.dart';

import '../services/habit_repository.dart';
import '../services/notification_service.dart';
import 'archive_screen.dart';

/// The "Settings" tab: reminder permission, archived habits, data erase,
/// and about info.
///
/// Streakly stores everything on-device in SQLite. There is no account,
/// no network and no tracking.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.repository});

  final HabitRepository repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsAllowed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allowed =
        await NotificationService.instance.isPermissionGranted;
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsAllowed = allowed;
      _loading = false;
    });
  }

  Future<void> _requestPermission() async {
    final granted =
        await NotificationService.instance.requestPermission();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Reminders enabled — habits with a reminder time will notify you.'
              : 'Notification permission not granted. You can enable it in system settings.',
        ),
      ),
    );
    await _load();
  }

  Future<void> _eraseAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text(
          'This deletes every habit, check-in and note, and cancels all '
          'reminders. This cannot be undone.',
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
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.repository.deleteAllData();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data erased.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader('Reminders'),
        Card(
          child: ListTile(
            leading: Icon(
              _notificationsAllowed
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: _notificationsAllowed
                  ? Colors.green.shade700
                  : scheme.onSurfaceVariant,
            ),
            title: const Text('Notifications'),
            subtitle: Text(
              _loading
                  ? 'Checking…'
                  : _notificationsAllowed
                      ? 'Allowed — daily reminders can fire.'
                      : 'Not allowed — reminders cannot fire.',
            ),
            trailing: _notificationsAllowed
                ? null
                : FilledButton(
                    onPressed: _requestPermission,
                    child: const Text('Enable'),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionHeader('Habits'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archived habits'),
            subtitle: const Text('Restore or delete habits you archived.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => ArchiveScreen(
                    repository: widget.repository,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const _SectionHeader('Data'),
        Card(
          child: ListTile(
            leading: Icon(Icons.delete_forever, color: scheme.error),
            title: const Text('Erase all data'),
            subtitle: const Text(
              'Delete every habit, check-in and note.',
            ),
            onTap: _eraseAll,
          ),
        ),
        const SizedBox(height: 16),
        const _SectionHeader('About'),
        Card(
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
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: scheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Streakly',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Version 1.0.0'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A habit tracker that lives entirely on your phone. '
                  'Your habits, check-ins and notes are stored in a local '
                  'database — no account, no network, no tracking.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 88),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
