import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/matching_filters.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

Future<void> showMatchingFiltersSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => const MatchingFiltersSheet(),
  );
}

class MatchingFiltersSheet extends ConsumerStatefulWidget {
  const MatchingFiltersSheet({super.key});

  @override
  ConsumerState<MatchingFiltersSheet> createState() =>
      _MatchingFiltersSheetState();
}

class _MatchingFiltersSheetState extends ConsumerState<MatchingFiltersSheet> {
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ProfileStrings.filtersTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Text(ProfileStrings.sizeFilter),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(ProfileStrings.sizeSmall),
                  selected: _draft.sizes.contains('mali'),
                  onSelected: (_) => _toggleSize('mali'),
                ),
                FilterChip(
                  label: Text(ProfileStrings.sizeMedium),
                  selected: _draft.sizes.contains('srednji'),
                  onSelected: (_) => _toggleSize('srednji'),
                ),
                FilterChip(
                  label: Text(ProfileStrings.sizeLarge),
                  selected: _draft.sizes.contains('veliki'),
                  onSelected: (_) => _toggleSize('veliki'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(ProfileStrings.genderFilter),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(ProfileStrings.genderMale),
                  selected: _draft.gender == FilterGender.male,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(gender: FilterGender.male),
                  ),
                ),
                ChoiceChip(
                  label: Text(ProfileStrings.genderFemale),
                  selected: _draft.gender == FilterGender.female,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(gender: FilterGender.female),
                  ),
                ),
                ChoiceChip(
                  label: Text(ProfileStrings.genderAny),
                  selected: _draft.gender == FilterGender.any,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(gender: FilterGender.any),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(ProfileStrings.cityFilter),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(ProfileStrings.cityNoviSad),
                  selected: _draft.city == FilterCity.noviSad,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(city: FilterCity.noviSad),
                  ),
                ),
                ChoiceChip(
                  label: Text(ProfileStrings.cityBeograd),
                  selected: _draft.city == FilterCity.beograd,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(city: FilterCity.beograd),
                  ),
                ),
                ChoiceChip(
                  label: Text(ProfileStrings.cityNis),
                  selected: _draft.city == FilterCity.nis,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(city: FilterCity.nis),
                  ),
                ),
                ChoiceChip(
                  label: Text(ProfileStrings.cityKragujevac),
                  selected: _draft.city == FilterCity.kragujevac,
                  onSelected: (_) => setState(
                    () => _draft =
                        _draft.copyWith(city: FilterCity.kragujevac),
                  ),
                ),
                ChoiceChip(
                  label: Text(ProfileStrings.cityZrenjanin),
                  selected: _draft.city == FilterCity.zrenjanin,
                  onSelected: (_) => setState(
                    () => _draft =
                        _draft.copyWith(city: FilterCity.zrenjanin),
                  ),
                ),
                ChoiceChip(
                  label: Text(ProfileStrings.citySubotica),
                  selected: _draft.city == FilterCity.subotica,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(city: FilterCity.subotica),
                  ),
                ),
                ChoiceChip(
                  label: Text(ProfileStrings.cityAll),
                  selected: _draft.city == FilterCity.any,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(city: FilterCity.any),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(ProfileStrings.radiusFilter),
            Slider(
              min: 1,
              max: 30,
              divisions: 29,
              value: _draft.radiusKm.clamp(1, 30).toDouble(),
              label: ProfileStrings.radiusValue(_draft.radiusKm),
              onChanged: (value) {
                setState(() => _draft = _draft.copyWith(radiusKm: value));
              },
            ),
            Text(ProfileStrings.radiusValue(_draft.radiusKm)),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(matchingFiltersProvider.notifier).apply(_draft);
                  Navigator.of(context).pop();
                },
                child: Text(ProfileStrings.applyFilters),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
