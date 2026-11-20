import 'package:material_ui/material_ui.dart';

import '../utils/app_colors.dart';

/// A row of colour swatches for the add/edit habit form.
class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.selectedValue,
    required this.onSelected,
  });

  final int selectedValue;
  final void Function(int colorValue) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: habitColorOptions.map((option) {
        final selected = option.color.toARGB32() == selectedValue;
        return InkWell(
          onTap: () => onSelected(option.color.toARGB32()),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: option.color,
              border: selected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 2.5,
                    )
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
