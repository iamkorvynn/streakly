import 'package:material_ui/material_ui.dart';

/// A flame badge showing a streak count, e.g. `🔥 12`.
///
/// Colour shifts with the streak: grey for 0, amber for a young streak,
/// deep orange once the streak is on fire.
class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.streak,
    this.large = false,
  });

  final int streak;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color color;
    if (streak == 0) {
      color = scheme.outline;
    } else if (streak < 7) {
      color = Colors.amber.shade700;
    } else if (streak < 30) {
      color = Colors.orange.shade700;
    } else {
      color = Colors.deepOrange;
    }
    final size = large ? 28.0 : 18.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.local_fire_department, color: color, size: size),
        const SizedBox(width: 2),
        Text(
          '$streak',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: large ? 24 : 16,
          ),
        ),
      ],
    );
  }
}
