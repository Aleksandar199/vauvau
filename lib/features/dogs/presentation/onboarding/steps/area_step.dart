import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/serbia_locations.dart';
import '../../../domain/dog_draft.dart';

class AreaStep extends StatelessWidget {
  const AreaStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final DogDraft draft;
  final ValueChanged<DogDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final city = SerbiaLocations.cityById(draft.cityId ?? '');
    final neighborhoods = city?.neighborhoods ?? [];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          AppStrings.stepAreaTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.stepAreaPrivacy,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('city-${draft.cityId}'),
          initialValue: draft.cityId,
          decoration: const InputDecoration(
            labelText: AppStrings.cityLabel,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final item in SerbiaLocations.cities)
              DropdownMenuItem(value: item.id, child: Text(item.name)),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            onChanged(
              draft.copyWith(cityId: value, clearNeighborhood: true),
            );
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('hood-${draft.cityId}-${draft.neighborhoodId}'),
          initialValue: draft.neighborhoodId,
          decoration: const InputDecoration(
            labelText: AppStrings.neighborhoodLabel,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final item in neighborhoods)
              DropdownMenuItem(value: item.id, child: Text(item.name)),
          ],
          onChanged: neighborhoods.isEmpty
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  onChanged(draft.copyWith(neighborhoodId: value));
                },
        ),
      ],
    );
  }
}
