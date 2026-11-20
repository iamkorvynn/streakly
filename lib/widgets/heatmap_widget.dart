import 'package:material_ui/material_ui.dart';

import '../utils/date_utils.dart';

/// GitHub-style heatmap of the last [weeks] weeks.
///
/// Each cell is one day: filled with the habit colour when checked,
/// faint when missed. The newest week is on the right.
class HeatmapWidget extends StatelessWidget {
  const HeatmapWidget({
    super.key,
    required this.checkedDays,
    required this.color,
    this.weeks = 16,
    this.today,
  });

  final Set<DateTime> checkedDays;
  final Color color;

  /// How many weeks of history to show.
  final int weeks;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final now = dateOnly(today ?? DateTime.now());
    final checked = checkedDays.map(dateOnly).toSet();
    final scheme = Theme.of(context).colorScheme;
    final endOfWeek = startOfWeek(now).add(const Duration(days: 6));
    final totalDays = weeks * 7;
    final start = endOfWeek.subtract(Duration(days: totalDays - 1));
    final cells = List<Widget>.generate(totalDays, (i) {
      final day = start.add(Duration(days: i));
      final isFuture = day.isAfter(now);
      final isChecked = checked.contains(day);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: isFuture
              ? Colors.transparent
              : isChecked
                  ? color
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          border: isFuture
              ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4))
              : null,
        ),
      );
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1,
          children: cells,
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const Text('Less', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            const Text('More', style: TextStyle(fontSize: 12)),
            const Spacer(),
            Text(
              '${checked.length} days total',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
