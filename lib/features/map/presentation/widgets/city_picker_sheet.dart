import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cities_controller.dart';
import '../map_strings.dart';
import '../../domain/city_model.dart';

Future<void> showCityPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const _CityPickerSheet(),
  );
}

class _CityPickerSheet extends ConsumerWidget {
  const _CityPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);
    final selected = ref.watch(mapRegionProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              MapStrings.chooseCity,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.my_location,
                color: selected.isMyLocation
                    ? theme.colorScheme.primary
                    : null,
              ),
              title: Text(MapStrings.cityMyLocation),
              subtitle: Text(MapStrings.cityMyLocationSubtitle),
              trailing: selected.isMyLocation
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(mapRegionProvider.notifier).selectMyLocation();
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: citiesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => _CityList(
                  cities: SeedCities.all,
                  selected: selected,
                ),
                data: (cities) => _CityList(
                  cities: cities.isEmpty ? SeedCities.all : cities,
                  selected: selected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityList extends ConsumerWidget {
  const _CityList({required this.cities, required this.selected});

  final List<CityModel> cities;
  final MapRegionSelection selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      itemCount: cities.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final city = cities[index];
        final isSelected =
            !selected.isMyLocation && selected.cityId == city.id;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.location_city,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
          title: Text(city.name),
          subtitle: Text('Radius ${city.radiusKm.round()} km'),
          trailing: isSelected
              ? Icon(Icons.check, color: theme.colorScheme.primary)
              : null,
          onTap: () {
            ref.read(mapRegionProvider.notifier).selectCity(city);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
