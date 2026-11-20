import 'package:material_ui/material_ui.dart';

import '../utils/app_icons.dart';

/// A grid of icons for the add/edit habit form.
///
/// The selected icon is highlighted with the habit colour.
class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.selectedCodePoint,
    required this.color,
    required this.onSelected,
  });

  final int selectedCodePoint;
  final Color color;
  final void Function(int codePoint) onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: habitIconOptions.length,
      itemBuilder: (context, index) {
        final option = habitIconOptions[index];
        final selected = option.icon.codePoint == selectedCodePoint;
        return InkWell(
          onTap: () => onSelected(option.icon.codePoint),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.18)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: color, width: 2)
                  : null,
            ),
            child: Icon(
              option.icon,
              color: selected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
