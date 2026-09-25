import 'package:flutter/material.dart';

import '../../../discover/domain/discover_profile.dart';
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
      return 'Ženka';
    case DogGender.male:
      return 'Mužjak';
    case DogGender.unknown:
      return 'Nije navedeno';
  }
}

String sizeLabel(DogSize size) {
  switch (size) {
    case DogSize.small:
      return 'Mali';
    case DogSize.medium:
      return 'Srednji';
    case DogSize.large:
    case DogSize.xlarge:
      return 'Veliki';
  }
}

String temperamentLabel(DogTemperament tag) {
  return DiscoverProfile.localizeTrait(tag.firestoreValue);
}
