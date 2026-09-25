import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/matching_filters.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../discover_strings.dart';
import 'discover_filter_chip.dart';

Future<void> showDiscoverFiltersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const DiscoverFiltersBottomSheet(),
  );
}

class DiscoverFiltersBottomSheet extends ConsumerStatefulWidget {
  const DiscoverFiltersBottomSheet({super.key});

  @override
  ConsumerState<DiscoverFiltersBottomSheet> createState() =>
      _DiscoverFiltersBottomSheetState();
}

class _DiscoverFiltersBottomSheetState
    extends ConsumerState<DiscoverFiltersBottomSheet> {
  late MatchingFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(matchingFiltersProvider);
  }

  void _toggleSize(String size) {
    final next = Set<String>.from(_draft.sizes);
    if (next.contains(size)) {
      next.remove(size);
    } else {
      next.add(size);
    }
    setState(() => _draft = _draft.copyWith(sizes: next));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DiscoverStrings.filters,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(DiscoverStrings.genderTitle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  DiscoverStrings.genderAll,
                  _draft.gender == FilterGender.any,
                  () => setState(
                    () => _draft = _draft.copyWith(gender: FilterGender.any),
                  ),
                ),
                _filterChip(
                  DiscoverStrings.genderMale,
                  _draft.gender == FilterGender.male,
                  () => setState(
                    () => _draft = _draft.copyWith(gender: FilterGender.male),
                  ),
                ),
                _filterChip(
                  DiscoverStrings.genderFemale,
                  _draft.gender == FilterGender.female,
                  () => setState(
                    () => _draft = _draft.copyWith(gender: FilterGender.female),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(DiscoverStrings.sizeTitle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  DiscoverStrings.sizeSmall,
                  _draft.sizes.contains('mali'),
                  () => _toggleSize('mali'),
                ),
                _filterChip(
                  DiscoverStrings.sizeMid,
                  _draft.sizes.contains('srednji'),
                  () => _toggleSize('srednji'),
                ),
                _filterChip(
                  DiscoverStrings.sizeBig,
                  _draft.sizes.contains('veliki'),
                  () => _toggleSize('veliki'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(DiscoverStrings.energyTitle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  DiscoverStrings.genderAll,
                  _draft.energy == FilterEnergy.any,
                  () => setState(
                    () => _draft = _draft.copyWith(energy: FilterEnergy.any),
                  ),
                ),
                _filterChip(
                  DiscoverStrings.energyLow,
                  _draft.energy == FilterEnergy.low,
                  () => setState(
                    () => _draft = _draft.copyWith(energy: FilterEnergy.low),
                  ),
                ),
                _filterChip(
                  DiscoverStrings.energyMid,
                  _draft.energy == FilterEnergy.medium,
                  () => setState(
                    () => _draft = _draft.copyWith(energy: FilterEnergy.medium),
                  ),
                ),
                _filterChip(
                  DiscoverStrings.energyHigh,
                  _draft.energy == FilterEnergy.high,
                  () => setState(
                    () => _draft = _draft.copyWith(energy: FilterEnergy.high),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(DiscoverStrings.distanceTitle),
            Slider(
              min: 1,
              max: 20,
              divisions: 19,
              label: '${_draft.radiusKm.round()} km',
              value: _draft.radiusKm.clamp(1, 20),
              onChanged: (value) {
                setState(() => _draft = _draft.copyWith(radiusKm: value));
              },
            ),
            Text('${_draft.radiusKm.round()} km'),
            const SizedBox(height: 8),
            Text(DiscoverStrings.ageTitle),
            RangeSlider(
              min: 0,
              max: 15,
              divisions: 15,
              labels: RangeLabels(
                '${_draft.minAge.round()}',
                '${_draft.maxAge.round()}',
              ),
              values: RangeValues(_draft.minAge, _draft.maxAge),
              onChanged: (value) {
                setState(
                  () => _draft = _draft.copyWith(
                    minAge: value.start,
                    maxAge: value.end,
                  ),
                );
              },
            ),
            Text(
              '${_draft.minAge.round()} – ${_draft.maxAge.round()} god.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(DiscoverStrings.vaccinatedOnly),
              value: _draft.vaccinatedOnly,
              onChanged: (value) {
                setState(
                  () => _draft = _draft.copyWith(vaccinatedOnly: value),
                );
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(DiscoverStrings.sterilizedOnly),
              value: _draft.sterilizedOnly,
              onChanged: (value) {
                setState(
                  () => _draft = _draft.copyWith(sterilizedOnly: value),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _draft = const MatchingFilters());
                  },
                  child: const Text(DiscoverStrings.reset),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () {
                      ref.read(matchingFiltersProvider.notifier).apply(_draft);
                      Navigator.of(context).pop();
                    },
                    child: const Text(DiscoverStrings.applyFilters),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return DiscoverFilterChip(
      label: label,
      selected: selected,
      onTap: onTap,
    );
  }
}
