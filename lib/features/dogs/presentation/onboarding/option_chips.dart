import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../discover/domain/discover_profile.dart';
import '../../../discover/presentation/discover_strings.dart';
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
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(labelOf(value)),
            selected: isSelected(value),
            onSelected: (_) => onSelected(value),
            selectedColor: theme.colorScheme.primary,
            checkmarkColor: theme.colorScheme.onPrimary,
            labelStyle: TextStyle(
              color: isSelected(value)
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

String genderLabel(DogGender gender) {
  switch (gender) {
    case DogGender.female:
      return DiscoverStrings.genderFemale;
    case DogGender.male:
      return DiscoverStrings.genderMale;
    case DogGender.unknown:
      return L10n.tr('Nije navedeno', 'Not specified');
  }
}

String sizeLabel(DogSize size) {
  switch (size) {
    case DogSize.small:
      return DiscoverStrings.sizeSmall;
    case DogSize.medium:
      return DiscoverStrings.sizeMid;
    case DogSize.large:
    case DogSize.xlarge:
      return DiscoverStrings.sizeBig;
  }
}

String temperamentLabel(DogTemperament tag) {
  return DiscoverProfile.localizeTrait(tag.firestoreValue);
}
