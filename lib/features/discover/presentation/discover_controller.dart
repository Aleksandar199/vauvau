import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../dogs/presentation/dog_providers.dart';
import '../../location/presentation/location_controller.dart';
import '../../moderation/presentation/block_controller.dart';
import '../../moderation/presentation/report_controller.dart';
import '../../profile/domain/matching_filters.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/dog_profile_mapper.dart';
import '../data/firestore_discover_repository.dart';
import '../data/local_discover_repository.dart';
import '../data/mock_discover_profiles.dart';
import '../domain/discover_profile.dart';
import '../domain/discover_repository.dart';
import '../domain/geo_query.dart';

enum DiscoverCategory { all, walking, small, medium, large }

class DiscoverState {
  const DiscoverState({
    required this.catalog,
    required this.myDog,
    this.query = '',
    this.category = DiscoverCategory.all,
  });

  final List<DiscoverProfile> catalog;
  final DiscoverProfile myDog;
  final String query;
  final DiscoverCategory category;

  List<DiscoverProfile> get visible {
    final needle = query.trim().toLowerCase();
    return catalog.where((profile) {
      if (!_matchesCategory(profile)) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      return profile.name.toLowerCase().contains(needle) ||
          profile.breed.toLowerCase().contains(needle) ||
          profile.location.toLowerCase().contains(needle) ||
          profile.ownerName.toLowerCase().contains(needle);
    }).toList();
  }

  bool get isEmpty => visible.isEmpty;

  bool _matchesCategory(DiscoverProfile profile) {
    switch (category) {
      case DiscoverCategory.all:
        return true;
      case DiscoverCategory.walking:
        return profile.walking;
      case DiscoverCategory.small:
        return profile.size == 'mali';
      case DiscoverCategory.medium:
        return profile.size == 'srednji';
      case DiscoverCategory.large:
        return profile.size == 'veliki';
    }
  }

  DiscoverState copyWith({
    List<DiscoverProfile>? catalog,
    DiscoverProfile? myDog,
    String? query,
    DiscoverCategory? category,
  }) {
    return DiscoverState(
      catalog: catalog ?? this.catalog,
      myDog: myDog ?? this.myDog,
      query: query ?? this.query,
      category: category ?? this.category,
    );
  }
}

class DiscoverController extends Notifier<DiscoverState> {
  @override
  DiscoverState build() {
    return DiscoverState(
      catalog: ref
          .watch(matchingFiltersProvider)
          .apply(ref.watch(discoverFeedProvider)),
      myDog: ref.watch(currentDiscoverDogProvider),
    );
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCategory(DiscoverCategory category) {
    state = state.copyWith(category: category);
  }

  Future<bool> swipe(DiscoverProfile target, String action) {
    final user = ref.read(authStateProvider).asData?.value;
    final uid = user?.uid ?? 'local-user';
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email ?? 'Neko');
    return ref
        .read(discoverRepositoryProvider)
        .swipe(
          userId: uid,
          myDogId: state.myDog.id,
          target: target,
          action: action,
          likerName: name,
        );
  }

  Future<bool> sendSuperLike(DiscoverProfile target) {
    final user = ref.read(authStateProvider).asData?.value;
    final uid = user?.uid ?? 'local-user';
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email ?? 'Neko');
    return ref
        .read(discoverRepositoryProvider)
        .sendSuperLike(
          userId: uid,
          myDogId: state.myDog.id,
          target: target,
          likerName: name,
        );
  }

  void resetFilters() {
    ref.read(matchingFiltersProvider.notifier).apply(const MatchingFilters());
    state = state.copyWith(query: '', category: DiscoverCategory.all);
  }
}

final discoverProfilesProvider = Provider<List<DiscoverProfile>>((ref) {
  return mockDiscoverProfiles;
});

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreDiscoverRepository(FirebaseFirestore.instance);
  }
  return LocalDiscoverRepository(seed: ref.watch(discoverProfilesProvider));
});

final liveDiscoverProfilesProvider = StreamProvider<List<DiscoverProfile>>((
  ref,
) {
  final location = ref.watch(userLocationProvider);
  final radius = ref.watch(matchingFiltersProvider).radiusKm;
  return ref
      .watch(discoverRepositoryProvider)
      .watchProfiles(
        excludeOwnerId: ref.watch(authStateProvider).asData?.value?.uid ?? '',
        geo: GeoQuery(origin: location.coord, radiusKm: radius),
      );
});

final discoverFeedProvider = Provider<List<DiscoverProfile>>((ref) {
  final hidden = ref.watch(hiddenContentProvider);
  final blocked = ref.watch(blockedUserIdsProvider);
  final List<DiscoverProfile> source;
  if (isFirebaseReady) {
    source = ref.watch(liveDiscoverProfilesProvider).asData?.value ?? const [];
  } else {
    final location = ref.watch(userLocationProvider);
    final radius = ref.watch(matchingFiltersProvider).radiusKm;
    source = GeoQuery(
      origin: location.coord,
      radiusKm: radius,
    ).apply(ref.watch(discoverProfilesProvider));
  }
  final ownerName =
      ref.watch(authStateProvider).asData?.value?.displayName ?? '';
  final ownDogs = ref.watch(ownerDogsProvider).asData?.value ?? const [];
  final byId = <String, DiscoverProfile>{
    for (final profile in source) profile.id: profile,
  };
  for (final dog in ownDogs) {
    if (dog.id == 'local-luna') {
      continue;
    }
    byId[dog.id] = discoverProfileFromDog(dog, ownerName: ownerName);
  }
  return [
    for (final profile in byId.values)
      if (!hidden.contains(profile.id) && !blocked.contains(profile.ownerId))
        profile,
  ]..forEach(_debugDogPhotos);
});

void _debugDogPhotos(DiscoverProfile dog) {
  debugPrint(
    '🐶 DOG DEBUG: Name: ${dog.name}, imageUrl: ${dog.imageUrl}, photoUrl: ${dog.photoUrl}, photos: ${dog.photos}',
  );
}

final discoverControllerProvider =
    NotifierProvider<DiscoverController, DiscoverState>(DiscoverController.new);
