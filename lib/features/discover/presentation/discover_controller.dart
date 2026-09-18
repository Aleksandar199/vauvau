import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../profile/domain/matching_filters.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/firestore_discover_repository.dart';
import '../data/local_discover_repository.dart';
import '../data/mock_discover_profiles.dart';
import '../domain/discover_profile.dart';
import '../domain/discover_repository.dart';

enum DiscoverCategory { all, nearby, walking, small, large, playful }

class DiscoverState {
  const DiscoverState({
    required this.catalog,
    required this.myDog,
    this.query = '',
    this.category = DiscoverCategory.all,
    this.gridMode = true,
  });

  final List<DiscoverProfile> catalog;
  final DiscoverProfile myDog;
  final String query;
  final DiscoverCategory category;
  final bool gridMode;

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
      case DiscoverCategory.nearby:
        return profile.distanceKm <= 3;
      case DiscoverCategory.walking:
        return profile.walking;
      case DiscoverCategory.small:
        return profile.size == 'mali';
      case DiscoverCategory.large:
        return profile.size == 'veliki';
      case DiscoverCategory.playful:
        return profile.energyLevel == 'visoka' ||
            profile.traits.any(
              (tag) =>
                  tag.contains('lopt') ||
                  tag.contains('Igračka') ||
                  tag.contains('Energičan'),
            );
    }
  }

  DiscoverState copyWith({
    List<DiscoverProfile>? catalog,
    DiscoverProfile? myDog,
    String? query,
    DiscoverCategory? category,
    bool? gridMode,
  }) {
    return DiscoverState(
      catalog: catalog ?? this.catalog,
      myDog: myDog ?? this.myDog,
      query: query ?? this.query,
      category: category ?? this.category,
      gridMode: gridMode ?? this.gridMode,
    );
  }
}

class DiscoverController extends Notifier<DiscoverState> {
  @override
  DiscoverState build() {
    return DiscoverState(
      catalog: ref.watch(matchingFiltersProvider).apply(
            ref.watch(discoverFeedProvider),
          ),
      myDog: ref.watch(currentDiscoverDogProvider),
    );
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCategory(DiscoverCategory category) {
    state = state.copyWith(category: category);
  }

  void toggleView() {
    state = state.copyWith(gridMode: !state.gridMode);
  }

  Future<bool> swipe(DiscoverProfile target, String action) {
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? 'local-user';
    return ref.read(discoverRepositoryProvider).swipe(
          userId: uid,
          myDogId: state.myDog.id,
          target: target,
          action: action,
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
  return LocalDiscoverRepository(
    seed: ref.watch(discoverProfilesProvider),
  );
});

final liveDiscoverProfilesProvider =
    StreamProvider<List<DiscoverProfile>>((ref) {
  return ref.watch(discoverRepositoryProvider).watchProfiles(
        excludeOwnerId: ref.watch(authStateProvider).asData?.value?.uid ?? '',
      );
});

final discoverFeedProvider = Provider<List<DiscoverProfile>>((ref) {
  if (isFirebaseReady) {
    return ref.watch(liveDiscoverProfilesProvider).asData?.value ??
        ref.watch(discoverProfilesProvider);
  }
  return ref.watch(discoverProfilesProvider);
});

final discoverControllerProvider =
    NotifierProvider<DiscoverController, DiscoverState>(DiscoverController.new);
