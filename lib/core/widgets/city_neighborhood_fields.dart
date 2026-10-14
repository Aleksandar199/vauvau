import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../constants/serbia_locations.dart';

/// City dropdown + neighborhood dropdown with optional free-text neighborhood.
class CityNeighborhoodFields extends StatelessWidget {
  const CityNeighborhoodFields({
    super.key,
    required this.cityId,
    required this.neighborhoodId,
    required this.customNeighborhoodController,
    required this.onCityChanged,
    required this.onNeighborhoodChanged,
    this.onCustomNeighborhoodChanged,
    this.enabled = true,
    this.showLabels = false,
  });

  final String cityId;
  final String? neighborhoodId;
  final TextEditingController customNeighborhoodController;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String?> onNeighborhoodChanged;
  final ValueChanged<String>? onCustomNeighborhoodChanged;
  final bool enabled;
  final bool showLabels;

  bool get _isCustom =>
      SerbiaLocations.usesCustomNeighborhood(cityId, neighborhoodId);

  @override
  Widget build(BuildContext context) {
    final hoodValue = SerbiaLocations.neighborhoodDropdownValue(
      cityId,
      neighborhoodId,
    );
    final neighborhoods =
        SerbiaLocations.cityById(cityId)?.neighborhoods ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabels) ...[
          Text(AppStrings.cityLabel, style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          key: ValueKey('city-$cityId'),
          initialValue: SerbiaLocations.cityById(cityId)?.id ??
              SerbiaLocations.cities.first.id,
          decoration: InputDecoration(
            labelText: AppStrings.cityLabel,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final city in SerbiaLocations.cities)
              DropdownMenuItem(value: city.id, child: Text(city.name)),
          ],
          onChanged: enabled
              ? (value) {
                  if (value != null) {
                    onCityChanged(value);
                  }
                }
              : null,
        ),
        SizedBox(height: 16),
        if (showLabels) ...[
          Text(
            AppStrings.neighborhoodLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          key: ValueKey('hood-$cityId-$hoodValue'),
          initialValue: hoodValue,
          hint: Text(AppStrings.neighborhoodLabel),
          decoration: InputDecoration(
            labelText: AppStrings.neighborhoodLabel,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final hood in neighborhoods)
              DropdownMenuItem(value: hood.id, child: Text(hood.name)),
            DropdownMenuItem(
              value: SerbiaLocations.customNeighborhoodId,
              child: Text(SerbiaLocations.customNeighborhoodLabel),
            ),
          ],
          onChanged: enabled
              ? (value) {
                  onNeighborhoodChanged(value);
                }
              : null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.neighborhoodRequired;
            }
            return null;
          },
        ),
        if (_isCustom) ...[
          SizedBox(height: 16),
          TextField(
            controller: customNeighborhoodController,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: AppStrings.customNeighborhoodHint,
              hintText: AppStrings.customNeighborhoodHint,
              border: OutlineInputBorder(),
            ),
            onChanged: onCustomNeighborhoodChanged,
          ),
        ],
      ],
    );
  }
}
