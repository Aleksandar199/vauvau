import 'dart:async';
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
        // Never the email: the name is shown to the dog's owner.
        : 'Neko';
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
        // Never the email: the name is shown to the dog's owner.
        : 'Neko';
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
  // Only the city matters here, not every update of the auth user.
  final userCity = ref.watch(
    authStateProvider.select((auth) {
      final user = auth.value;
      return user == null ? null : (user.cityId, user.cityName);
    }),
  );
  final explicitCity = filters.cityId;
  final cityId = explicitCity ??
      (userCity == null
          ? null
          : SerbiaLocations.resolveCityId(userCity.$1, userCity.$2));
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

/// What Discover has loaded so far for the current user and area.
class DiscoverFeedState {
  const DiscoverFeedState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  final List<DiscoverProfile> items;

  /// No page has arrived yet for the current user / area. [items] may still
  /// hold the previous area's cards, which stay visible while refreshing.
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
}

/// Paginates Discover: a small live first page + older pages via [loadMore].
///
/// Rebuilds (auth user enriched from Firestore, GPS fix, home city, radius)
/// keep the previous cards until the new first page arrives, so the feed
/// never blinks to the empty state while it is only reloading.
class DiscoverFeedController extends Notifier<DiscoverFeedState> {
  static const int pageSize = 8;

  /// Fetch the next page once at most this many cards are left to see.
  static const int prefetchThreshold = 3;

  /// An empty answer from the offline cache is not trusted as "no dogs"
  /// until the server answers or this much time passes (offline).
  static const Duration cacheGrace = Duration(seconds: 6);

  var _generation = 0;
  var _uid = '';
  GeoQuery? _geo;
  var _gotFirstPage = false;
  var _loadingMore = false;
  List<DiscoverProfile> _stale = const [];
  List<DiscoverProfile> _live = const [];
  Object? _liveCursor;
  var _liveHasMore = false;

  /// Live cards pushed out of the first page by newer dogs after paging
  /// started; they would otherwise fall into the gap before [_older].
  List<DiscoverProfile> _pushedOut = const [];
  List<DiscoverProfile> _older = const [];
  var _paged = false;
  Object? _cursor;
  var _olderHasMore = false;

  bool get hasMore => state.hasMore;
  bool get isLoadingMore => state.isLoadingMore;

  @override
  DiscoverFeedState build() {
    final area = ref.watch(discoverAreaProvider);
    final uid = ref.watch(
      authStateProvider.select((auth) => auth.value?.uid ?? ''),
    );
    // `.value` keeps `true` while the provider re-checks; `asData` would drop
    // to null and blank the feed on every auth user update.
    final authReady = ref.watch(
      firestoreAuthReadyProvider.select((ready) => ready.value ?? false),
    );
    final repo = ref.watch(discoverRepositoryProvider);

    final generation = ++_generation;
    final previous = stateOrNull;
    _stale = previous != null && uid == _uid ? previous.items : const [];
    _uid = uid;
    _geo = area.geo;
    _gotFirstPage = false;
    _loadingMore = false;
    _live = const [];
    _liveCursor = null;
    _liveHasMore = false;
    _pushedOut = const [];
    _older = const [];
    _paged = false;
    _cursor = null;
    _olderHasMore = false;

    // Firestore needs a signed-in user; the local repository does not.
    if (isFirebaseReady && (!authReady || uid.isEmpty)) {
      return DiscoverFeedState(items: _stale);
    }

    Timer? grace;
    final sub = repo
        .watchProfiles(excludeOwnerId: uid, geo: _geo, limit: pageSize)
        .listen(
          (page) {
            if (generation != _generation) {
              return;
            }
            if (page.isFromCache && page.items.isEmpty && !_gotFirstPage) {
              grace ??= Timer(cacheGrace, () {
                if (generation == _generation && !_gotFirstPage) {
                  _onFirstPage(page);
                }
              });
              return;
            }
            grace?.cancel();
            _onFirstPage(page);
          },
          onError: (Object error, StackTrace stack) {
            if (generation != _generation) {
              return;
            }
            if (FirestoreAuthGuard.isPermissionDenied(error)) {
              FirestoreAuthGuard.logPermissionDenied(
                error,
                stack,
                label: 'discover.feed',
              );
            } else {
              debugPrint('Discover feed stream: $error');
            }
            grace?.cancel();
            if (!_gotFirstPage) {
              _onFirstPage(const DiscoverPage(items: []));
            }
          },
        );
    ref.onDispose(() {
      sub.cancel();
      grace?.cancel();
    });
    return DiscoverFeedState(items: _stale);
  }

  void _onFirstPage(DiscoverPage page) {
    if (_paged) {
      final ids = {for (final profile in page.items) profile.id};
      _pushedOut = [
        ..._pushedOut,
        for (final profile in _live)
          if (!ids.contains(profile.id)) profile,
      ];
    }
    _live = page.items;
    _liveCursor = page.nextCursor;
    _liveHasMore = page.hasMore && page.nextCursor != null;
    _gotFirstPage = true;
    _stale = const [];
    _publish();
  }

  void _publish() {
    state = DiscoverFeedState(
      items: _gotFirstPage ? _merged() : _stale,
      isLoading: !_gotFirstPage,
      isLoadingMore: _loadingMore,
      hasMore: _gotFirstPage && (_paged ? _olderHasMore : _liveHasMore),
    );
  }

  List<DiscoverProfile> _merged() {
    final seen = <String>{};
    return [
      for (final profile in [..._live, ..._pushedOut, ..._older])
        if (seen.add(profile.id)) profile,
    ];
  }

  /// Loads the next page in the background; no-op while busy or exhausted.
  Future<void> loadMore() async {
    if (_loadingMore || !state.hasMore) {
      return;
    }
    final cursor = _paged ? _cursor : _liveCursor;
    if (cursor == null) {
      return;
    }
    final generation = _generation;
    final repo = ref.read(discoverRepositoryProvider);
    _loadingMore = true;
    _publish();
    var hasMore = false;
    Object? next;
    var items = const <DiscoverProfile>[];
    try {
      final page = await repo.fetchProfilesPage(
        excludeOwnerId: _uid,
        geo: _geo,
        cursor: cursor,
        limit: pageSize,
      );
      items = page.items;
      next = page.nextCursor;
      hasMore = page.hasMore && next != null;
    } catch (error, stack) {
      // Stop paging this area instead of retrying in a loop.
      debugPrint('Discover loadMore failed: $error\n$stack');
    }
    if (!ref.mounted || generation != _generation) {
      return;
    }
    _older = [..._older, ...items];
    _paged = true;
    _cursor = next;
    _olderHasMore = hasMore;
    _loadingMore = false;
    _publish();
  }
}

final discoverFeedControllerProvider =
    NotifierProvider<DiscoverFeedController, DiscoverFeedState>(
  DiscoverFeedController.new,
);

final liveDiscoverProfilesProvider = Provider<List<DiscoverProfile>>((ref) {
  return ref.watch(discoverFeedControllerProvider.select((feed) => feed.items));
});

final discoverFeedProvider = Provider<List<DiscoverProfile>>((ref) {
  final hidden = ref.watch(hiddenContentProvider);
  final blocked = ref.watch(blockedUserIdsProvider);
  final source = ref.watch(liveDiscoverProfilesProvider);
  final myUid = ref.watch(
    authStateProvider.select((auth) => auth.value?.uid ?? ''),
  );
  // `.value` keeps the last list while the provider reloads.
  final ownDogIds = {
    for (final dog in ref.watch(ownerDogsProvider).value ?? const []) dog.id,
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
