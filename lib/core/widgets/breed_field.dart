import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../constants/dog_breeds.dart';

/// Breed dropdown with suggested list + free-text "custom" option at the bottom.
class BreedField extends StatefulWidget {
  const BreedField({
    super.key,
    required this.breed,
    required this.customBreedController,
    required this.onBreedChanged,
    this.onCustomBreedChanged,
    this.enabled = true,
    this.validator,
  });

  /// Current stored breed value (suggested name or custom text).
  final String breed;
  final TextEditingController customBreedController;
  final ValueChanged<String> onBreedChanged;
  final ValueChanged<String>? onCustomBreedChanged;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  @override
  State<BreedField> createState() => _BreedFieldState();
}

class _BreedFieldState extends State<BreedField> {
  /// Suggested breed name, [DogBreeds.customId], or null when unset.
  String? _selection;

  @override
  void initState() {
    super.initState();
    _selection = DogBreeds.dropdownValue(widget.breed);
  }

  @override
  void didUpdateWidget(covariant BreedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.breed != widget.breed) {
      final next = DogBreeds.dropdownValue(widget.breed);
      // Keep custom mode open while the user is still typing an empty value.
      if (next != null || _selection != DogBreeds.customId) {
        _selection = next;
      }
    }
  }

  bool get _showCustom => _selection == DogBreeds.customId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('breed-$_selection'),
          initialValue: _selection,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: AppStrings.dogBreedLabel,
            hintText: AppStrings.dogBreedHint,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final name in DogBreeds.suggested)
              DropdownMenuItem(
                value: name,
                child: Text(name, overflow: TextOverflow.ellipsis),
              ),
            DropdownMenuItem(
              value: DogBreeds.customId,
              child: Text(AppStrings.customBreedLabel),
            ),
          ],
          onChanged: widget.enabled
              ? (value) {
                  if (value == null) return;
                  setState(() => _selection = value);
                  if (value == DogBreeds.customId) {
                    widget.onBreedChanged(
                      widget.customBreedController.text.trim(),
                    );
                  } else {
                    widget.customBreedController.clear();
                    widget.onBreedChanged(value);
                  }
                }
              : null,
          validator: widget.validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.dogBreedRequired;
                }
                if (value == DogBreeds.customId &&
                    widget.customBreedController.text.trim().isEmpty) {
                  return AppStrings.customBreedRequired;
                }
                return null;
              },
        ),
        if (_showCustom) ...[
          SizedBox(height: 16),
          TextField(
            controller: widget.customBreedController,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: AppStrings.customBreedHint,
              hintText: AppStrings.customBreedHint,
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              widget.onBreedChanged(text);
              widget.onCustomBreedChanged?.call(text);
            },
          ),
        ],
      ],
    );
  }
}
