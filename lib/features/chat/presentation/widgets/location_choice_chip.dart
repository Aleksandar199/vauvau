import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// High-contrast location chip readable on light and dark surfaces.
class LocationChoiceChip extends StatelessWidget {
  const LocationChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.onPrimary : onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.85),
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : onSurface.withValues(alpha: 0.25),
      ),
      showCheckmark: false,
    );
  }
}
