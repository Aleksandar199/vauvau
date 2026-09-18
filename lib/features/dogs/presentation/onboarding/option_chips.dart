import 'package:flutter/material.dart';

import '../../domain/dog_enums.dart';

class OptionChips<T> extends StatelessWidget {
  const OptionChips({
    super.key,
    required this.values,
    required this.labelOf,
    required this.isSelected,
    required this.onSelected,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final bool Function(T value) isSelected;
  final void Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(labelOf(value)),
            selected: isSelected(value),
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}

String genderLabel(DogGender gender) {
  switch (gender) {
    case DogGender.female:
      return 'Female';
    case DogGender.male:
      return 'Male';
    case DogGender.unknown:
      return 'Unknown';
  }
}

String sizeLabel(DogSize size) {
  switch (size) {
    case DogSize.small:
      return 'Small';
    case DogSize.medium:
      return 'Medium';
    case DogSize.large:
      return 'Large';
    case DogSize.xlarge:
      return 'Extra large';
  }
}

String energyLabel(DogEnergyLevel energy) {
  switch (energy) {
    case DogEnergyLevel.low:
      return 'Low';
    case DogEnergyLevel.moderate:
      return 'Moderate';
    case DogEnergyLevel.high:
      return 'High';
  }
}

String temperamentLabel(DogTemperament tag) {
  switch (tag) {
    case DogTemperament.friendly:
      return 'Friendly';
    case DogTemperament.playful:
      return 'Playful';
    case DogTemperament.calm:
      return 'Calm';
    case DogTemperament.shy:
      return 'Shy';
    case DogTemperament.protective:
      return 'Protective';
    case DogTemperament.social:
      return 'Social';
  }
}
