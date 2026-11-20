import 'package:material_ui/material_ui.dart';

import 'screens/add_edit_habit_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'services/habit_repository.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reminders are best-effort: the app must work even if notification
  // setup fails (e.g. on a device without the permission flow).
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // Reminders stay off; everything else works offline.
  }
  runApp(const StreaklyApp());
}

/// Root widget: Material 3 theming plus the four-tab shell.
class StreaklyApp extends StatelessWidget {
  const StreaklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streakly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MainScaffold(),
    );
  }
}

/// Bottom-navigation shell: Today, Calendar, Stats, Settings.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final HabitRepository _repository = HabitRepository();
  int _tab = 0;

  late final List<Widget> _tabs = <Widget>[
    HomeScreen(repository: _repository),
    CalendarScreen(repository: _repository),
    StatsScreen(repository: _repository),
    SettingsScreen(repository: _repository),
  ];

  Future<void> _openAdd() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            AddEditHabitScreen(repository: _repository),
      ),
    );
    if (saved == true) {
      setState(() {
        // Rebuild the tabs so the new habit appears immediately.
        _tab = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _tab == 0
          ? AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.local_fire_department,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Streakly',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : null,
      body: IndexedStack(
        index: _tab,
        children: _tabs,
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: _openAdd,
              tooltip: 'Add habit',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.today),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
