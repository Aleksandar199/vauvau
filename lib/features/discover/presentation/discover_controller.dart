import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/firebase/firebase_status.dart';
import '../../../core/geo/geo.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../dogs/presentation/dog_providers.dart';
import '../../location/presentation/location_controller.dart';
import '../../map/presentation/walk_controller.dart';
import '../../moderation/presentation/block_controller.dart';
import '../../moderation/presentation/report_controller.dart';
import '../../profile/domain/matching_filters.dart';
import '../../profile/presentation/profile_controller.dart';
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
  DiscoverCategory _category = DiscoverCategory.all;
  String _query = '';

  @override
  DiscoverState build() {
    final walkActive = ref.watch(
      walkControllerProvider.select((walk) => walk.isActive),
    );
    final walkStatus = ref.watch(
      walkControllerProvider.select((walk) => walk.statusMessage),
    );
    var myDog = ref.watch(currentDiscoverDogProvider);
    if (walkActive) {
      final status = (walkStatus ?? '').trim();
      myDog = myDog.copyWith(
        walking: true,
        activityStatus: status.isEmpty ? 'U šetnji' : status,
      );
    }
    final area = ref.watch(discoverAreaProvider);
    return DiscoverState(
      catalog: ref
          .watch(matchingFiltersProvider)
          .apply(ref.watch(discoverFeedProvider))
          .where(area.allows)
          .toList(),
      myDog: myDog,
      query: _query,
      category: _category,
    );
  }

  void setQuery(String query) {
    _query = query;
    state = state.copyWith(query: query);
  }

  void setCategory(DiscoverCategory category) {
    _category = category;
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
    _query = '';
    _category = DiscoverCategory.all;
    ref.read(matchingFiltersProvider.notifier).apply(const MatchingFilters());
    state = state.copyWith(query: '', category: DiscoverCategory.all);
  }
}

/// Where Discover searches: origin + radius, limited to one city when known.
class DiscoverArea {
  const DiscoverArea({
    required this.origin,
    required this.radiusKm,
    this.cityId,
  });

  /// GPS within this distance of a city center counts as "in that city".
  static const double cityReachKm = 30;

  final GeoCoord origin;
  final double radiusKm;
  final String? cityId;

  GeoQuery get geo => GeoQuery(origin: origin, radiusKm: radiusKm);

  bool allows(DiscoverProfile profile) {
    final wanted = cityId;
    if (wanted == null) {
      return true;
    }
    final dogCity = SerbiaLocations.cityIdForLabel(profile.location);
    return dogCity == null || dogCity == wanted;
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoverArea &&
      other.origin == origin &&
      other.radiusKm == radiusKm &&
      other.cityId == cityId;

  @override
  int get hashCode => Object.hash(origin, radiusKm, cityId);
}

final discoverAreaProvider = Provider<DiscoverArea>((ref) {
  final location = ref.watch(userLocationProvider);
  final filters = ref.watch(matchingFiltersProvider);
  final user = ref.watch(authStateProvider).asData?.value;
  final explicitCity = filters.cityId;
  final cityId = explicitCity ??
      (user == null
          ? null
          : SerbiaLocations.resolveCityId(user.cityId, user.cityName));
  if (cityId == null) {
    return DiscoverArea(origin: location.coord, radiusKm: filters.radiusKm);
  }
  final center = GeoCoord.forCityId(cityId);
  final gpsInCity = !location.isFallback &&
      haversineKm(location.coord, center) <= DiscoverArea.cityReachKm;
  return DiscoverArea(
    origin: gpsInCity ? location.coord : center,
    radiusKm: explicitCity != null
        ? math.max(filters.radiusKm, DiscoverArea.cityReachKm)
        : filters.radiusKm,
    cityId: cityId,
  );
});

final discoverProfilesProvider = Provider<List<DiscoverProfile>>((ref) {
  return mockDiscoverProfiles;
});

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreDiscoverRepository(FirebaseFirestore.instance);
  }
  return LocalDiscoverRepository(seed: ref.watch(discoverProfilesProvider));
});

/// Paginates Discover: live first page (15) + older pages via [loadMore].
class DiscoverFeedController extends Notifier<List<DiscoverProfile>> {
  static const int pageSize = 15;

  var _hasMore = true;
  var _loadingMore = false;
  List<DiscoverProfile> _older = const [];
  Object? _cursor;
  List<DiscoverProfile>? _live;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  @override
  List<DiscoverProfile> build() {
    final area = ref.watch(discoverAreaProvider);
    final exclude =
        ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final authReady =
        ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
    // Reset paging when location / radius / auth changes (rebuild).
    _older = const [];
    _cursor = null;
    _hasMore = true;
    _live = null;
    if (!authReady || exclude.isEmpty) {
      return const [];
    }
    final geo = area.geo;
    final sub = ref
        .watch(discoverRepositoryProvider)
        .watchProfiles(
          excludeOwnerId: exclude,
          geo: geo,
          limit: pageSize,
        )
        .listen(
          (profiles) {
            _live = profiles;
            if (_older.isEmpty) {
              _hasMore = profiles.length >= pageSize;
            }
            state = _merged();
          },
          onError: (Object error, StackTrace stack) {
            if (FirestoreAuthGuard.isPermissionDenied(error)) {
              FirestoreAuthGuard.logPermissionDenied(
                error,
                stack,
                label: 'discover.feed',
              );
              _live = const [];
              state = _merged();
              return;
            }
            debugPrint('Discover feed stream: $error');
          },
        );
    ref.onDispose(sub.cancel);
    return _merged();
  }

  List<DiscoverProfile> _merged() {
    final live = _live ?? const <DiscoverProfile>[];
    if (_older.isEmpty) {
      return live;
    }
    final seen = {for (final profile in live) profile.id};
    return [
      ...live,
      for (final profile in _older)
        if (seen.add(profile.id)) profile,
    ];
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) {
      return;
    }
    _loadingMore = true;
    state = _merged();
    try {
      final exclude =
          ref.read(authStateProvider).asData?.value?.uid ?? '';
      final repo = ref.read(discoverRepositoryProvider);
      final geo = ref.read(discoverAreaProvider).geo;

      // First loadMore: advance cursor past the live first page (avoid dupes).
      if (_cursor == null) {
        final seed = await repo.fetchProfilesPage(
          excludeOwnerId: exclude,
          geo: geo,
          limit: pageSize,
        );
        _cursor = seed.nextCursor;
        _hasMore = seed.hasMore && seed.nextCursor != null;
        if (_cursor == null) {
          return;
        }
      }

      final page = await repo.fetchProfilesPage(
        excludeOwnerId: exclude,
        geo: geo,
        cursor: _cursor,
        limit: pageSize,
      );
      final seen = {for (final profile in _merged()) profile.id};
      final fresh = [
        for (final profile in page.items)
          if (seen.add(profile.id)) profile,
      ];
      _older = [..._older, ...fresh];
      _cursor = page.nextCursor;
      _hasMore = page.hasMore && page.nextCursor != null;
      state = _merged();
    } catch (error, stack) {
      debugPrint('Discover loadMore failed: $error\n$stack');
    } finally {
      _loadingMore = false;
      state = _merged();
    }
  }
}

final discoverFeedControllerProvider =
    NotifierProvider<DiscoverFeedController, List<DiscoverProfile>>(
  DiscoverFeedController.new,
);

final liveDiscoverProfilesProvider = Provider<List<DiscoverProfile>>((ref) {
  return ref.watch(discoverFeedControllerProvider);
});

final discoverFeedProvider = Provider<List<DiscoverProfile>>((ref) {
  final hidden = ref.watch(hiddenContentProvider);
  final blocked = ref.watch(blockedUserIdsProvider);
  final source = ref.watch(liveDiscoverProfilesProvider);
  final myUid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
  final ownDogIds = {
    for (final dog in ref.watch(ownerDogsProvider).asData?.value ?? const [])
      dog.id,
  };

  // Never show the current user's own dogs in Discover — others still see them
  // via Firestore (excludeOwnerId only filters the viewer's feed).
  final feed = [
    for (final profile in source)
      if (!hidden.contains(profile.id) &&
          !blocked.contains(profile.ownerId) &&
          (myUid.isEmpty || profile.ownerId != myUid) &&
          !ownDogIds.contains(profile.id))
        profile,
  ]..sort(DiscoverProfile.compareFeedOrder);
  return feed;
});

final discoverControllerProvider =
    NotifierProvider<DiscoverController, DiscoverState>(DiscoverController.new);
