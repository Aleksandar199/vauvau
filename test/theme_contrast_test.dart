import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/theme/app_theme.dart';

/// Colour a [Text] with [label] is actually painted with: its own style
/// merged over the surrounding DefaultTextStyle (chips, tiles, buttons set
/// their own).
Color _paintColor(WidgetTester tester, String label) {
  final element = tester.element(find.text(label));
  final text = tester.widget<Text>(find.text(label));
  final base = DefaultTextStyle.of(element).style;
  final color = base.merge(text.style).color;
  expect(color, isNotNull, reason: '$label has no explicit text colour');
  return color!;
}

void main() {
  for (final entry in {
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  }.entries) {
    testWidgets('${entry.key} theme: unselected widgets keep readable text', (
      tester,
    ) async {
      final theme = entry.value;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Column(
              children: [
                const ChoiceChip(label: Text('chip-off'), selected: false),
                const FilterChip(label: Text('filter-off'), selected: false, onSelected: null),
                const InputChip(label: Text('input-off')),
                const ListTile(title: Text('tile'), subtitle: Text('sub')),
                const Text('plain'),
                TextButton(onPressed: () {}, child: const Text('text-btn')),
                OutlinedButton(onPressed: () {}, child: const Text('outlined')),
              ],
            ),
          ),
        ),
      );
      final surface = theme.colorScheme.surface;
      for (final label in [
        'chip-off',
        'filter-off',
        'input-off',
        'tile',
        'sub',
        'plain',
        'text-btn',
        'outlined',
      ]) {
        final color = _paintColor(tester, label);
        expect(
          (color.computeLuminance() - surface.computeLuminance()).abs(),
          greaterThan(0.3),
          reason: '$label ($color) on surface $surface in ${entry.key} theme',
        );
      }
    });
  }
}
