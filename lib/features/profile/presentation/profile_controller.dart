import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/firebase/firebase_status.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/data/dog_profile_mapper.dart';
import '../../discover/domain/discover_profile.dart';
import '../../dogs/domain/dog.dart';
import '../../dogs/domain/dog_area.dart';
import '../../dogs/presentation/dog_providers.dart';
import '../data/app_settings_store.dart';
import '../domain/app_settings.dart';
import '../domain/matching_filters.dart';
import '../domain/user_profile.dart';

class ProfileController extends Notifier<UserProfile> {
  static const _localDemoDogId = 'local-luna';

  @override
  UserProfile build() {
    final user = ref.watch(authStateProvider).asData?.value;
    final dogs = ref.watch(ownerDogsProvider).asData?.value ?? const [];

    if (!isFirebaseReady) {
      final created = [
        for (final dog in dogs)
          if (dog.id != _localDemoDogId) dog,
      ];
      if (created.isEmpty) {
        return mockUserProfile;
      }
      return _fromDogs(user, created);
    }

    if (user == null) {
      return const UserProfile(
        ownerName: '',
        ownerBio: '',
        dogs: [],
        selectedDogId: '',
      );
    }

    if (dogs.isNotEmpty) {
      return _fromDogs(user, dogs);
    }

    if (user.dog.hasProfile) {
      final fromUser = discoverProfileFromUserDog(user);
      return _ownerSheet(user, dogs: [fromUser], selectedId: fromUser.id);
    }

    return _ownerSheet(user, dogs: const [], selectedId: '');
  }

  UserProfile _fromDogs(AppUser? user, List<Dog> dogs) {
    final ownerName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? '');
    final discoverDogs = [
      for (final dog in dogs) discoverProfileFromDog(dog, ownerName: ownerName),
    ];
    final preferredId = user?.dog.id ?? '';
    final selectedId =
        preferredId.isNotEmpty &&
            discoverDogs.any((dog) => dog.id == preferredId)
        ? preferredId
        : discoverDogs.first.id;
    if (user == null) {
      return UserProfile(
        ownerName: ownerName,
        ownerBio: '',
        ownerLocation: discoverDogs.first.location,
        selectedDogId: selectedId,
        dogs: discoverDogs,
      );
    }
    return _ownerSheet(user, dogs: discoverDogs, selectedId: selectedId);
  }

  UserProfile _ownerSheet(
    AppUser user, {
    required List<DiscoverProfile> dogs,
    required String selectedId,
  }) {
    return UserProfile(
      ownerName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email ?? ''),
      ownerEmail: user.email ?? '',
      ownerBio: user.bio.trim(),
      ownerLocation: user.locationLabel,
      ownerCityId: user.cityId,
      ownerNeighborhoodId: user.neighborhoodId,
      selectedDogId: selectedId,
      dogs: dogs,
    );
  }

  void selectDog(String dogId) {
    state = state.copyWith(selectedDogId: dogId);
  }

  void save(UserProfile profile) {
    state = profile;
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null || !isFirebaseReady) {
      return;
    }
    unawaited(
      ref
          .read(authRepositoryProvider)
          .saveUserProfile(
            user: user,
            city: profile.ownerLocation,
            name: profile.ownerName,
            bio: profile.ownerBio,
            cityId: profile.ownerCityId,
            neighborhoodId: profile.ownerNeighborhoodId,
            neighborhoodName: _neighborhoodName(
              profile.ownerCityId,
              profile.ownerNeighborhoodId,
            ),
            writeDog: false,
          ),
    );
    final area = DogArea(
      cityId: profile.ownerCityId,
      cityName: _cityName(profile.ownerCityId, profile.ownerLocation),
      neighborhoodId: profile.ownerNeighborhoodId,
      neighborhoodName: _neighborhoodName(
        profile.ownerCityId,
        profile.ownerNeighborhoodId,
      ),
    );
    for (final dog in profile.dogs) {
      unawaited(
        ref
            .read(dogsRepositoryProvider)
            .updateDog(
              dogFromDiscover(dog, ownerId: user.uid, area: area),
              ageMonths: dog.ageMonths,
            ),
      );
    }
  }

  void saveDog(DiscoverProfile dog) {
    final dogs = [
      for (final item in state.dogs)
        if (item.id == dog.id) dog else item,
    ];
    state = state.copyWith(dogs: dogs, selectedDogId: dog.id);
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null || !isFirebaseReady) {
      return;
    }
    final area = DogArea(
      cityId: state.ownerCityId,
      cityName: _cityName(state.ownerCityId, state.ownerLocation),
      neighborhoodId: state.ownerNeighborhoodId,
      neighborhoodName: _neighborhoodName(
        state.ownerCityId,
        state.ownerNeighborhoodId,
      ),
    );
    unawaited(
      ref
          .read(dogsRepositoryProvider)
          .updateDog(
            dogFromDiscover(dog, ownerId: user.uid, area: area),
            ageMonths: dog.ageMonths,
          ),
    );
    if (user.dog.id == dog.id || user.dog.id.isEmpty) {
      unawaited(
        ref
            .read(authRepositoryProvider)
            .saveUserProfile(
              user: user,
              dog: userDogFromDiscover(dog),
              writeDog: true,
            ),
      );
    }
  }

  Future<void> saveOwnerCustomPhoto(String url) async {
    final trimmed = url.trim();
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null || trimmed.isEmpty) {
      return;
    }
    await ref
        .read(authRepositoryProvider)
        .saveOwnerCustomPhoto(uid: user.uid, customPhotoUrl: trimmed);
    // Force auth stream consumers (Profil, Meni drawer) to pick up the new URL.
    ref.invalidate(authStateProvider);
  }

  String _cityName(String cityId, String fallback) {
    return SerbiaLocations.cityById(cityId)?.name ??
        SerbiaLocations.sanitizeLocationLabel(fallback).split(',').first.trim();
  }

  String _neighborhoodName(String cityId, String neighborhoodId) {
    final city = SerbiaLocations.cityById(cityId);
    if (city == null) {
      return '';
    }
    for (final hood in city.neighborhoods) {
      if (hood.id == neighborhoodId) {
        return hood.name;
      }
    }
    return '';
  }
}

class MatchingFiltersController extends Notifier<MatchingFilters> {
  @override
  MatchingFilters build() => const MatchingFilters();

  void apply(MatchingFilters filters) {
    state = filters;
    ref
        .read(appSettingsProvider.notifier)
        .syncRadiusFromFilters(filters.radiusKm);
  }
}

class AppSettingsController extends Notifier<AppSettings> {
  var _hydrated = false;

  @override
  AppSettings build() {
    unawaited(_hydrate());
    return const AppSettings();
  }

  Future<void> _hydrate() async {
    final loaded = await AppSettingsStore.read();
    if (!ref.mounted) {
      return;
    }
    _hydrated = true;
    state = loaded;
    _syncRadius(loaded);
  }

  void update(AppSettings settings) {
    state = settings;
    _syncRadius(settings);
    unawaited(AppSettingsStore.write(settings));
  }

  void syncRadiusFromFilters(double radiusKm) {
    if (state.radiusKm == radiusKm) {
      return;
    }
    state = state.copyWith(radiusKm: radiusKm);
    if (_hydrated) {
      unawaited(AppSettingsStore.write(state));
    }
  }

  void _syncRadius(AppSettings settings) {
    final filters = ref.read(matchingFiltersProvider);
    if (filters.radiusKm != settings.radiusKm) {
      ref
          .read(matchingFiltersProvider.notifier)
          .apply(filters.copyWith(radiusKm: settings.radiusKm));
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
  final profile = ref.watch(profileControllerProvider);
  if (profile.dogs.isEmpty) {
    return mockUserProfile.dog;
  }
  return profile.dog;
});
