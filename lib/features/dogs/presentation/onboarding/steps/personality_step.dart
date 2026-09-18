import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../domain/dog_draft.dart';
import '../../../domain/dog_enums.dart';
import '../option_chips.dart';

class PersonalityStep extends StatefulWidget {
  const PersonalityStep({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onToggleTemperament,
  });

  final DogDraft draft;
  final ValueChanged<DogDraft> onChanged;
  final ValueChanged<DogTemperament> onToggleTemperament;

  @override
  State<PersonalityStep> createState() => _PersonalityStepState();
}

class _PersonalityStepState extends State<PersonalityStep> {
  late final TextEditingController _weight;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
      text: widget.draft.weightKg?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(AppStrings.stepPersonalityTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(AppStrings.dogSizeLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        OptionChips<DogSize>(
          values: DogSize.values,
          labelOf: sizeLabel,
          isSelected: (value) => widget.draft.size == value,
          onSelected: (value) => widget.onChanged(widget.draft.copyWith(size: value)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: AppStrings.dogWeightLabel,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final parsed = double.tryParse(value);
            widget.onChanged(
              widget.draft.copyWith(
                weightKg: parsed,
                clearWeight: value.isEmpty,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(AppStrings.dogEnergyLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        OptionChips<DogEnergyLevel>(
          values: DogEnergyLevel.values,
          labelOf: energyLabel,
          isSelected: (value) => widget.draft.energyLevel == value,
          onSelected: (value) =>
              widget.onChanged(widget.draft.copyWith(energyLevel: value)),
        ),
        const SizedBox(height: 16),
        Text(AppStrings.dogTemperamentLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        OptionChips<DogTemperament>(
          values: DogTemperament.values,
          labelOf: temperamentLabel,
          isSelected: (value) => widget.draft.temperament.contains(value),
          onSelected: widget.onToggleTemperament,
        ),
      ],
    );
  }
}
