import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discover/domain/discover_profile.dart';
import '../domain/app_settings.dart';
import '../domain/matching_filters.dart';
import '../domain/user_profile.dart';

class ProfileController extends Notifier<UserProfile> {
  @override
  UserProfile build() => mockUserProfile;

  void selectDog(String dogId) {
    state = state.copyWith(selectedDogId: dogId);
  }

  void save(UserProfile profile) {
    final selected = profile.dog.copyWith(ownerName: profile.ownerName);
    final dogs = [
      for (final dog in profile.dogs)
        if (dog.id == selected.id)
          selected
        else
          dog.copyWith(ownerName: profile.ownerName),
    ];
    state = profile.copyWith(dogs: dogs, selectedDogId: selected.id);
  }
}

class MatchingFiltersController extends Notifier<MatchingFilters> {
  @override
  MatchingFilters build() => const MatchingFilters();

  void apply(MatchingFilters filters) {
    state = filters;
  }
}

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void update(AppSettings settings) {
    state = settings;
    final filters = ref.read(matchingFiltersProvider);
    if (filters.radiusKm != settings.radiusKm) {
      ref.read(matchingFiltersProvider.notifier).apply(
            filters.copyWith(radiusKm: settings.radiusKm),
          );
    }
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, UserProfile>(ProfileController.new);

final matchingFiltersProvider =
    NotifierProvider<MatchingFiltersController, MatchingFilters>(
      MatchingFiltersController.new,
    );

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

final currentDiscoverDogProvider = Provider<DiscoverProfile>((ref) {
  return ref.watch(profileControllerProvider).dog;
});
