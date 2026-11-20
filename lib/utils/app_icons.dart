import 'package:material_ui/material_ui.dart';

/// One pickable icon for a habit.
class HabitIconOption {
  const HabitIconOption(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Icons the user can assign to a habit.
const List<HabitIconOption> habitIconOptions = <HabitIconOption>[
  HabitIconOption(Icons.fitness_center, 'Workout'),
  HabitIconOption(Icons.directions_run, 'Run'),
  HabitIconOption(Icons.menu_book, 'Read'),
  HabitIconOption(Icons.water_drop, 'Water'),
  HabitIconOption(Icons.self_improvement, 'Meditate'),
  HabitIconOption(Icons.bedtime, 'Sleep'),
  HabitIconOption(Icons.code, 'Code'),
  HabitIconOption(Icons.translate, 'Language'),
  HabitIconOption(Icons.music_note, 'Music'),
  HabitIconOption(Icons.brush, 'Draw'),
  HabitIconOption(Icons.restaurant, 'Eat well'),
  HabitIconOption(Icons.smoke_free, 'No smoking'),
  HabitIconOption(Icons.savings, 'Save money'),
  HabitIconOption(Icons.smartphone, 'Less screen'),
  HabitIconOption(Icons.school, 'Study'),
  HabitIconOption(Icons.work, 'Deep work'),
  HabitIconOption(Icons.timer, 'Focus'),
  HabitIconOption(Icons.star, 'Goal'),
  HabitIconOption(Icons.favorite, 'Health'),
  HabitIconOption(Icons.pets, 'Pet care'),
  HabitIconOption(Icons.directions_bike, 'Cycle'),
  HabitIconOption(Icons.pool, 'Swim'),
  HabitIconOption(Icons.local_cafe, 'No caffeine'),
  HabitIconOption(Icons.emoji_events, 'Win'),
  HabitIconOption(Icons.eco, 'Nature'),
  HabitIconOption(Icons.cleaning_services, 'Tidy up'),
  HabitIconOption(Icons.account_balance_wallet, 'Budget'),
  HabitIconOption(Icons.edit_note, 'Journal'),
];
