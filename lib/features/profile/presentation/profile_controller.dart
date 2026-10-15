import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/firebase/firebase_status.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme_preference.dart';
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

  String? _selectedDogId;

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
      _selectedDogId = null;
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
    final selectedId = _resolveSelectedId(
      discoverDogs,
      preferredId: user?.dog.id ?? '',
    );
    _selectedDogId = selectedId;
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

  String _resolveSelectedId(
    List<DiscoverProfile> dogs, {
    required String preferredId,
  }) {
    if (dogs.isEmpty) {
      return '';
    }
    final remembered = _selectedDogId?.trim() ?? '';
    if (remembered.isNotEmpty && dogs.any((dog) => dog.id == remembered)) {
      return remembered;
    }
    if (preferredId.isNotEmpty && dogs.any((dog) => dog.id == preferredId)) {
      return preferredId;
    }
    return dogs.first.id;
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
      ownerNeighborhoodName: user.neighborhoodName,
      ownerDetails: user.details,
      selectedDogId: selectedId,
      dogs: dogs,
    );
  }

  void selectDog(String dogId) {
    _selectedDogId = dogId;
    state = state.copyWith(selectedDogId: dogId);
  }

  /// [writeOwnerDetails]: also replace the optional "about me" fields with
  /// `profile.ownerDetails` (only the edit-profile screen edits them).
  void save(UserProfile profile, {bool writeOwnerDetails = false}) {
    state = profile;
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null || !isFirebaseReady) {
      return;
    }
    final neighborhoodName = _neighborhoodName(
      profile.ownerCityId,
      profile.ownerNeighborhoodId,
      profile.ownerNeighborhoodName,
    );
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
            neighborhoodName: neighborhoodName,
            writeDog: false,
            details: writeOwnerDetails ? profile.ownerDetails : null,
          ),
    );
    final area = DogArea(
      cityId: profile.ownerCityId,
      cityName: _cityName(profile.ownerCityId, profile.ownerLocation),
      neighborhoodId: profile.ownerNeighborhoodId,
      neighborhoodName: neighborhoodName,
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
    final normalized = dog.copyWith(
      gender: normalizeDogGender(dog.gender),
      size: normalizeDogSize(dog.size),
    );
    final dogs = [
      for (final item in state.dogs)
        if (item.id == normalized.id) normalized else item,
    ];
    _selectedDogId = normalized.id;
    state = state.copyWith(dogs: dogs, selectedDogId: normalized.id);
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
        state.ownerNeighborhoodName,
      ),
    );
    final entity = dogFromDiscover(
      normalized,
      ownerId: user.uid,
      area: area,
    );
    // Optimistic overlay — kept until Firestore snapshot matches these fields.
    ref.read(localOwnerDogsProvider.notifier).upsert(entity);
    unawaited(
      ref
          .read(dogsRepositoryProvider)
          .updateDog(entity, ageMonths: normalized.ageMonths),
    );
    if (user.dog.id == normalized.id || user.dog.id.isEmpty) {
      unawaited(
        ref
            .read(authRepositoryProvider)
            .saveUserProfile(
              user: user,
              dog: userDogFromDiscover(normalized),
              writeDog: true,
            ),
      );
    }
  }

  Future<void> deleteDog(String dogId) async {
    if (state.dogs.length <= 1) {
      return;
    }
    final remaining = [
      for (final dog in state.dogs)
        if (dog.id != dogId) dog,
    ];
    if (remaining.isEmpty) {
      return;
    }
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      return;
    }
    final previous = state;
    final nextSelected = remaining.first.id;
    _selectedDogId = nextSelected;
    state = state.copyWith(dogs: remaining, selectedDogId: nextSelected);
    try {
      await ref
          .read(dogsRepositoryProvider)
          .deleteDog(dogId, ownerId: user.uid)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      _selectedDogId = previous.selectedDogId;
      state = previous;
      rethrow;
    }
    ref.read(localOwnerDogsProvider.notifier).remove(dogId);
    if (!isFirebaseReady) {
      return;
    }
    final nextDog = remaining.first;
    if (user.dog.id == dogId || user.dog.id.isEmpty) {
      unawaited(
        ref.read(authRepositoryProvider).saveUserProfile(
              user: user,
              dog: userDogFromDiscover(nextDog),
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

  String _neighborhoodName(
    String cityId,
    String neighborhoodId,
    String customOrStoredName,
  ) {
    return SerbiaLocations.resolveNeighborhoodName(
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      customName: customOrStoredName,
    );
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
  var _hydrateStarted = false;
  Completer<void>? _ready;

  @override
  AppSettings build() {
    _ensureHydrateStarted();
    return const AppSettings();
  }

  /// Resolves after the first SharedPreferences read finishes.
  Future<void> ensureReady() async {
    _ensureHydrateStarted();
    if (_hydrated) {
      return;
    }
    final ready = _ready;
    if (ready != null) {
      await ready.future;
    }
  }

  void _ensureHydrateStarted() {
    if (_hydrateStarted) {
      return;
    }
    _hydrateStarted = true;
    _ready = Completer<void>();
    unawaited(_hydrate());
  }

  Future<void> _hydrate() async {
    try {
      final loaded = await AppSettingsStore.read();
      if (!ref.mounted) {
        return;
      }
      _hydrated = true;
      L10n.setLanguage(loaded.language);
      state = loaded;
      _syncRadius(loaded);
    } finally {
      final ready = _ready;
      if (ready != null && !ready.isCompleted) {
        ready.complete();
      }
    }
  }

  void update(AppSettings settings) {
    L10n.setLanguage(settings.language);
    state = settings;
    _syncRadius(settings);
    unawaited(AppSettingsStore.write(settings));
  }

  void setLanguage(AppLanguage language) {
    update(state.copyWith(language: language));
  }

  void setThemePreference(AppThemePreference themePreference) {
    update(state.copyWith(themePreference: themePreference));
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
