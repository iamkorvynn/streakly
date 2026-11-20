// Widget tests for Streakly's screens and widgets.
//
// The database runs on sqflite_common_ffi so widget tests exercise the
// real storage path. No demo data is seeded anywhere — tests create
// their own habits and wipe the database afterwards.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:streakly/main.dart';
import 'package:streakly/models/habit.dart';
import 'package:streakly/models/habit_stats.dart';
import 'package:streakly/screens/add_edit_habit_screen.dart';
import 'package:streakly/screens/home_screen.dart';
import 'package:streakly/services/database_helper.dart';
import 'package:streakly/services/habit_repository.dart';
import 'package:streakly/widgets/heatmap_widget.dart';
import 'package:streakly/widgets/habit_card.dart';
import 'package:streakly/widgets/streak_badge.dart';
import 'package:streakly/widgets/week_strip.dart';

void main() {
  late HabitRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    repo = HabitRepository();
    await DatabaseHelper.instance.deleteAllData();
  });

  tearDown(() async {
    await DatabaseHelper.instance.deleteAllData();
    await DatabaseHelper.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/streakly.db');
  });

  Habit _habit({String name = 'Read'}) => Habit(
        name: name,
        iconCodePoint: Icons.menu_book.codePoint,
        colorValue: Colors.deepOrange.toARGB32(),
        createdAt: DateTime.now(),
      );

  const emptyStats = HabitStats(
    currentStreak: 0,
    bestStreak: 0,
    totalCheckIns: 0,
    completionLast7: 0,
    completionLast30: 0,
    daysSinceStart: 1,
  );

  Widget _wrap(Widget child) => MaterialApp(home: child);

  group('HomeScreen', () {
    testWidgets('shows the empty state when no habits exist',
        (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('No habits yet'), findsOneWidget);
      expect(find.text('Add your first habit'), findsOneWidget);
    });

    testWidgets('lists a created habit with its streak',
        (tester) async {
      await repo.createHabit(_habit(name: 'Morning run'));
      await tester.pumpWidget(_wrap(HomeScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('0/1 done'), findsOneWidget);
    });

    testWidgets('tapping the check button checks the habit in',
        (tester) async {
      final habit = await repo.createHabit(_habit(name: 'Read'));
      await tester.pumpWidget(_wrap(HomeScreen(repository: repo)));
      await tester.pumpAndSettle();
      // The check button is the circular button on the card.
      final checkButtons = find.byIcon(Icons.check);
      expect(checkButtons, findsWidgets);
      await tester.tap(checkButtons.first);
      await tester.pumpAndSettle();
      expect(await repo.isCheckedToday(habit), isTrue);
      expect(find.text('1/1 done'), findsOneWidget);
    });
  });

  group('HabitCard', () {
    testWidgets('renders name, best streak and target progress',
        (tester) async {
      final habit = _habit(name: 'Meditate').copyWith(id: 1);
      await tester.pumpWidget(_wrap(
        Scaffold(
          body: HabitCard(
            habit: habit,
            stats: const HabitStats(
              currentStreak: 5,
              bestStreak: 12,
              totalCheckIns: 20,
              completionLast7: 0.8,
              completionLast30: 0.6,
              daysSinceStart: 25,
            ),
            checkedDays: <DateTime>{},
            checkedToday: false,
            onTap: () {},
            onToggleToday: () {},
            onToggleDay: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Meditate'), findsOneWidget);
      expect(find.text('Best 12  •  20 days total'), findsOneWidget);
      expect(find.text('5/30 days'), findsOneWidget);
    });
  });

  group('StreakBadge', () {
    testWidgets('shows the streak number', (tester) async {
      await tester.pumpWidget(
        _wrap(const Scaffold(body: StreakBadge(streak: 21))),
      );
      expect(find.text('21'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });
  });

  group('WeekStrip', () {
    testWidgets('renders seven day dots', (tester) async {
      await tester.pumpWidget(_wrap(
        Scaffold(
          body: WeekStrip(
            checkedDays: <DateTime>{DateTime.now()},
            color: Colors.deepOrange,
          ),
        ),
      ));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('HeatmapWidget', () {
    testWidgets('renders the legend and total', (tester) async {
      await tester.pumpWidget(_wrap(
        Scaffold(
          body: HeatmapWidget(
            checkedDays: <DateTime>{DateTime.now()},
            color: Colors.deepOrange,
            weeks: 2,
          ),
        ),
      ));
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.text('1 days total'), findsOneWidget);
    });
  });

  group('AddEditHabitScreen', () {
    testWidgets('saving with a name creates the habit', (tester) async {
      await tester.pumpWidget(
        _wrap(AddEditHabitScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('New habit'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Drink water',
      );
      await tester.tap(find.text('Save').first);
      await tester.pumpAndSettle();
      final habits = await repo.getActiveHabits();
      expect(habits.map((h) => h.name), ['Drink water']);
    });

    testWidgets('saving with an empty name shows a warning',
        (tester) async {
      await tester.pumpWidget(
        _wrap(AddEditHabitScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save').first);
      await tester.pump();
      expect(find.text('Give your habit a name first.'), findsOneWidget);
      expect(await repo.getActiveHabits(), isEmpty);
    });
  });

  group('StreaklyApp', () {
    testWidgets('boots with four tabs', (tester) async {
      await tester.pumpWidget(const StreaklyApp());
      await tester.pumpAndSettle();
      expect(find.text('Streakly'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
