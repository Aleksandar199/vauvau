import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../domain/dog_draft.dart';
import '../../../domain/dog_enums.dart';
import '../option_chips.dart';
import '../../widgets/preference_chip_group.dart';
import '../../../domain/dog_preference_tags.dart';

class PersonalityStep extends StatefulWidget {
  const PersonalityStep({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onToggleTemperament,
    required this.onToggleLike,
    required this.onToggleDislike,
  });

  final DogDraft draft;
  final ValueChanged<DogDraft> onChanged;
  final ValueChanged<DogTemperament> onToggleTemperament;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleDislike;

  static const temperamentOptions = [
    DogTemperament.friendly,
    DogTemperament.playful,
    DogTemperament.calm,
    DogTemperament.shy,
    DogTemperament.protective,
  ];

  @override
  State<PersonalityStep> createState() => _PersonalityStepState();
}

class _PersonalityStepState extends State<PersonalityStep> {
  late final TextEditingController _weight;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
      text: widget.draft.weightKg?.toStringAsFixed(0) ?? '',
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
    final draft = widget.draft;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(AppStrings.stepPersonalityTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(AppStrings.dogSizeLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        OptionChips<DogSize>(
          values: const [DogSize.small, DogSize.medium, DogSize.large],
          labelOf: sizeLabel,
          isSelected: (value) => draft.size == value,
          onSelected: (value) => widget.onChanged(draft.copyWith(size: value)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weight,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: AppStrings.dogWeightLabel,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final parsed = double.tryParse(value.trim());
            widget.onChanged(
              draft.copyWith(weightKg: parsed, clearWeight: parsed == null),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(AppStrings.dogTemperamentLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        OptionChips<DogTemperament>(
          values: PersonalityStep.temperamentOptions,
          labelOf: temperamentLabel,
          isSelected: (value) => draft.temperament.contains(value),
          onSelected: widget.onToggleTemperament,
        ),
        const SizedBox(height: 16),
        PreferenceChipGroup(
          title: '🐕 Voli',
          options: DogPreferenceTags.likes,
          selected: draft.likesTags,
          onToggle: widget.onToggleLike,
          selectedColor: const Color(0xFF2E7D32),
          selectedForeground: Colors.white,
        ),
        const SizedBox(height: 16),
        PreferenceChipGroup(
          title: '❌ Ne voli',
          options: DogPreferenceTags.dislikes,
          selected: draft.dislikesTags,
          onToggle: widget.onToggleDislike,
          selectedColor: const Color(0xFFC62828),
          selectedForeground: Colors.white,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.dogVaccinatedLabel),
          value: draft.vaccinated,
          onChanged: (value) =>
              widget.onChanged(draft.copyWith(vaccinated: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.dogChippedLabel),
          value: draft.chipped,
          onChanged: (value) => widget.onChanged(draft.copyWith(chipped: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.dogSterilizedLabel),
          value: draft.sterilized,
          onChanged: (value) =>
              widget.onChanged(draft.copyWith(sterilized: value)),
        ),
      ],
    );
  }
}
