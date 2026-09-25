import 'package:flutter/material.dart';

import '../../data/walk_locations.dart';
import '../chat_strings.dart';

Future<String?> showLocationPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => const LocationPickerSheet(),
  );
}

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  String? _selected;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ChatStrings.sendLocation,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              ChatStrings.walkLocation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final place in scheduledWalkLocations)
                  ChoiceChip(
                    label: Text(place),
                    selected: _selected == place,
                    onSelected: (_) => setState(() {
                      _selected = place;
                      _customController.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customController,
              decoration: InputDecoration(
                hintText: ChatStrings.walkCustomLocationHint,
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                final trimmed = value.trim();
                setState(() => _selected = trimmed.isEmpty ? null : trimmed);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(ChatStrings.cancel),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected == null || _selected!.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_selected),
                    child: const Text(ChatStrings.send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}