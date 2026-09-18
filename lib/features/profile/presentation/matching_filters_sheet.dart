import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/matching_filters.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';

Future<void> showMatchingFiltersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
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
          const SizedBox(height: 16),
          Text(ProfileStrings.sizeFilter),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text(ProfileStrings.sizeSmall),
                selected: _draft.sizes.contains('mali'),
                onSelected: (_) => _toggleSize('mali'),
              ),
              FilterChip(
                label: const Text(ProfileStrings.sizeMedium),
                selected: _draft.sizes.contains('srednji'),
                onSelected: (_) => _toggleSize('srednji'),
              ),
              FilterChip(
                label: const Text(ProfileStrings.sizeLarge),
                selected: _draft.sizes.contains('veliki'),
                onSelected: (_) => _toggleSize('veliki'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(ProfileStrings.genderFilter),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text(ProfileStrings.genderMale),
                selected: _draft.gender == FilterGender.male,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(gender: FilterGender.male),
                ),
              ),
              ChoiceChip(
                label: const Text(ProfileStrings.genderFemale),
                selected: _draft.gender == FilterGender.female,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(gender: FilterGender.female),
                ),
              ),
              ChoiceChip(
                label: const Text(ProfileStrings.genderAny),
                selected: _draft.gender == FilterGender.any,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(gender: FilterGender.any),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(ProfileStrings.cityFilter),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text(ProfileStrings.cityNoviSad),
                selected: _draft.city == FilterCity.noviSad,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(city: FilterCity.noviSad),
                ),
              ),
              ChoiceChip(
                label: const Text(ProfileStrings.cityBeograd),
                selected: _draft.city == FilterCity.beograd,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(city: FilterCity.beograd),
                ),
              ),
              ChoiceChip(
                label: const Text(ProfileStrings.cityAll),
                selected: _draft.city == FilterCity.any,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(city: FilterCity.any),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(matchingFiltersProvider.notifier).apply(_draft);
                Navigator.of(context).pop();
              },
              child: const Text(ProfileStrings.applyFilters),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
