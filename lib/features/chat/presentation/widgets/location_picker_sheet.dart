import 'package:flutter/material.dart';

import '../../data/walk_locations.dart';
import '../chat_strings.dart';
import 'location_choice_chip.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

Future<String?> showLocationPickerSheet(BuildContext context) {
  return showAppBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => const LocationPickerSheet(),
  );
}

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late String _selected;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = scheduledWalkLocations.first;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ChatStrings.sendLocation,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              ChatStrings.walkLocation,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final place in scheduledWalkLocations)
                  LocationChoiceChip(
                    label: place,
                    selected: _selected == place &&
                        _customController.text.trim().isEmpty,
                    onSelected: (_) => setState(() {
                      _selected = place;
                      _customController.clear();
                    }),
                  ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _customController,
              style: TextStyle(color: onSurface),
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
                setState(() {
                  if (trimmed.isNotEmpty) {
                    _selected = trimmed;
                  } else {
                    _selected = scheduledWalkLocations.first;
                  }
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(ChatStrings.cancel),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_selected.trim()),
                    child: Text(ChatStrings.send),
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
