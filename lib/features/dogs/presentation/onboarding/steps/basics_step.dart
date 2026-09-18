import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../domain/dog_draft.dart';
import '../../../domain/dog_enums.dart';
import '../option_chips.dart';

class BasicsStep extends StatefulWidget {
  const BasicsStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final DogDraft draft;
  final ValueChanged<DogDraft> onChanged;

  @override
  State<BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends State<BasicsStep> {
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _age;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft.name);
    _breed = TextEditingController(text: widget.draft.breed);
    _age = TextEditingController(
      text: widget.draft.ageYears?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    super.dispose();
  }

  void _emit({DogGender? gender}) {
    widget.onChanged(
      widget.draft.copyWith(
        name: _name.text,
        breed: _breed.text,
        gender: gender ?? widget.draft.gender,
        ageYears: int.tryParse(_age.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(AppStrings.stepBasicsTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: AppStrings.dogNameLabel,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _breed,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: AppStrings.dogBreedLabel,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 16),
        Text(AppStrings.dogGenderLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        OptionChips<DogGender>(
          values: DogGender.values,
          labelOf: genderLabel,
          isSelected: (value) => widget.draft.gender == value,
          onSelected: (value) => _emit(gender: value),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _age,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: AppStrings.dogAgeLabel,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
