import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/dog_breeds.dart';
import '../../../../../core/widgets/breed_field.dart';
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
  late final TextEditingController _customBreed;
  late final TextEditingController _age;
  late String _breed;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft.name);
    _breed = widget.draft.breed;
    final isCustom = DogBreeds.dropdownValue(_breed) == DogBreeds.customId;
    _customBreed = TextEditingController(text: isCustom ? _breed : '');
    _age = TextEditingController(
      text: widget.draft.ageYears?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _customBreed.dispose();
    _age.dispose();
    super.dispose();
  }

  void _emit({DogGender? gender, String? breed}) {
    if (breed != null) {
      _breed = breed;
    }
    widget.onChanged(
      widget.draft.copyWith(
        name: _name.text,
        breed: _breed,
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
        SizedBox(height: 16),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: AppStrings.dogNameLabel,
            hintText: AppStrings.dogNameHint,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: 16),
        BreedField(
          breed: _breed,
          customBreedController: _customBreed,
          onBreedChanged: (value) {
            setState(() => _breed = value);
            _emit(breed: value);
          },
        ),
        SizedBox(height: 16),
        Text(AppStrings.dogGenderLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        OptionChips<DogGender>(
          values: const [DogGender.male, DogGender.female],
          labelOf: genderLabel,
          isSelected: (value) => widget.draft.gender == value,
          onSelected: (value) => _emit(gender: value),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _age,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: AppStrings.dogAgeLabel,
            hintText: AppStrings.dogAgeHint,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
