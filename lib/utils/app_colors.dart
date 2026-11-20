import 'package:material_ui/material_ui.dart';

/// One pickable colour for a habit.
class HabitColorOption {
  const HabitColorOption(this.color, this.label);

  final Color color;
  final String label;
}

/// The habit colour palette.
const List<HabitColorOption> habitColorOptions = <HabitColorOption>[
  HabitColorOption(Colors.deepOrange, 'Ember'),
  HabitColorOption(Colors.amber, 'Honey'),
  HabitColorOption(Colors.green, 'Leaf'),
  HabitColorOption(Colors.teal, 'Lagoon'),
  HabitColorOption(Colors.blue, 'Ocean'),
  HabitColorOption(Colors.indigo, 'Dusk'),
  HabitColorOption(Colors.purple, 'Grape'),
  HabitColorOption(Colors.pink, 'Bloom'),
  HabitColorOption(Colors.red, 'Cherry'),
  HabitColorOption(Colors.brown, 'Cocoa'),
  HabitColorOption(Colors.lime, 'Citrus'),
  HabitColorOption(Colors.cyan, 'Glacier'),
];

/// Fallback colour when a stored colour value is unknown.
const Color defaultHabitColor = Colors.deepOrange;
