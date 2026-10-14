import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/serbia_locations.dart';
import '../../../../../core/widgets/city_neighborhood_fields.dart';
import '../../../domain/dog_draft.dart';

class AreaStep extends StatefulWidget {
  const AreaStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final DogDraft draft;
  final ValueChanged<DogDraft> onChanged;

  @override
  State<AreaStep> createState() => _AreaStepState();
}

class _AreaStepState extends State<AreaStep> {
  late final TextEditingController _customNeighborhood;

  @override
  void initState() {
    super.initState();
    _customNeighborhood = TextEditingController(
      text: widget.draft.customNeighborhoodName,
    );
  }

  @override
  void dispose() {
    _customNeighborhood.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCityId = widget.draft.cityId ?? SerbiaLocations.noviSadId;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          AppStrings.stepAreaTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          AppStrings.stepAreaPrivacy,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        CityNeighborhoodFields(
          cityId: selectedCityId,
          neighborhoodId: widget.draft.neighborhoodId,
          customNeighborhoodController: _customNeighborhood,
          onCityChanged: (value) {
            _customNeighborhood.clear();
            widget.onChanged(
              widget.draft.copyWith(cityId: value, clearNeighborhood: true),
            );
          },
          onNeighborhoodChanged: (value) {
            if (!SerbiaLocations.isCustomNeighborhoodId(value)) {
              _customNeighborhood.clear();
            }
            widget.onChanged(
              widget.draft.copyWith(
                neighborhoodId: value,
                customNeighborhoodName: SerbiaLocations.isCustomNeighborhoodId(
                      value,
                    )
                    ? _customNeighborhood.text.trim()
                    : '',
              ),
            );
          },
          onCustomNeighborhoodChanged: (value) {
            widget.onChanged(
              widget.draft.copyWith(customNeighborhoodName: value),
            );
          },
        ),
      ],
    );
  }
}
