import 'package:flutter/material.dart';

class PreferenceChipGroup extends StatelessWidget {
  const PreferenceChipGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.selectedColor,
    required this.selectedForeground,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final Color selectedColor;
  final Color selectedForeground;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in options)
              FilterChip(
                label: Text(tag),
                selected: selected.contains(tag),
                onSelected: (_) => onToggle(tag),
                selectedColor: selectedColor,
                checkmarkColor: selectedForeground,
                labelStyle: TextStyle(
                  color: selected.contains(tag)
                      ? selectedForeground
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

List<String> togglePreference(List<String> current, String tag) {
  if (current.contains(tag)) {
    return [for (final item in current) if (item != tag) item];
  }
  return [...current, tag];
}
