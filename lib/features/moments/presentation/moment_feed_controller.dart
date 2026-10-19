import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../follows/presentation/follow_controller.dart';
import '../../location/presentation/home_city_provider.dart';
import '../../moderation/presentation/block_controller.dart';
import '../domain/moment_model.dart';
import '../domain/moments_repository.dart';
import 'moments_controller.dart';

/// Why a tab has nothing to load (instead of "no posts yet").
enum MomentFeedBlocker { none, noFollowing, noCity }

class MomentFeedState {
  const MomentFeedState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.loadMoreFailed = false,
    this.isOffline = false,
    this.blocker = MomentFeedBlocker.none,
  });

  final List<MomentModel> items;

  /// The first page has not arrived yet ([items] may hold the previous
  /// result, shown while refreshing).
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;

  /// First page failed (nothing to show).
  final Object? error;
  final bool loadMoreFailed;

  /// Served from the offline cache.
  final bool isOffline;
  final MomentFeedBlocker blocker;

  MomentFeedState copyWith({
    List<MomentModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
    bool? loadMoreFailed,
    bool? isOffline,
  }) {
    return MomentFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      isOffline: isOffline ?? this.isOffline,
      blocker: blocker,
    );
  }
}

/// One feed tab: pages of `kind == 'post'` moments, newest first.
///
/// "Pratim" reads the authors from `follows` (followingIdsProvider), so a
/// follow / unfollow reloads it. "U blizini" uses the user's home city and
/// only posts whose author tagged that city.
class MomentFeedController extends Notifier<MomentFeedState> {
  MomentFeedController(this.feed);

  final MomentFeed feed;

  static const int pageSize = 10;

  var _generation = 0;
  Object? _cursor;
  MomentFeedRequest? _request;

  @override
  MomentFeedState build() {
    final repo = ref.watch(momentsRepositoryProvider);
    final me = ref.watch(momentsMemberIdProvider);
    final ready = !isFirebaseReady ||
        ref.watch(
          firestoreAuthReadyProvider.select((ready) => ready.value ?? false),
        );
    final generation = ++_generation;
    _cursor = null;
    final stale = stateOrNull?.items ?? const <MomentModel>[];

    MomentFeedRequest? request;
    switch (feed) {
      case MomentFeed.forYou:
        request = const MomentFeedRequest.forYou();
      case MomentFeed.following:
        final following = ref.watch(followingIdsProvider);
        final ids = following.value;
        if (ids == null) {
          return MomentFeedState(items: stale);
        }
        if (ids.isEmpty) {
          return const MomentFeedState(
            isLoading: false,
            blocker: MomentFeedBlocker.noFollowing,
          );
        }
        request = MomentFeedRequest.following(ids.toList());
      case MomentFeed.nearby:
        final cityId = ref.watch(homeCityProvider.select((city) => city?.id));
        if (cityId == null || cityId.isEmpty) {
          return const MomentFeedState(
            isLoading: false,
            blocker: MomentFeedBlocker.noCity,
          );
        }
        request = MomentFeedRequest.nearby(cityId);
    }
    _request = request;
    if (!ready || me.isEmpty) {
      return MomentFeedState(items: stale);
    }
    unawaited(Future.microtask(() => _loadFirst(generation, repo)));
    return MomentFeedState(items: stale);
  }

  Future<void> _loadFirst(int generation, MomentsRepository repo) async {
    final request = _request;
    if (request == null) {
      return;
    }
    try {
      final page = await repo.fetchFeedPage(request, limit: pageSize);
      if (generation != _generation || !ref.mounted) {
        return;
      }
      _cursor = page.nextCursor;
      ref
          .read(momentPatchesProvider.notifier)
          .loaded(page.items.map((moment) => moment.id));
      state = MomentFeedState(
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore && page.nextCursor != null,
        isOffline: page.isFromCache,
      );
    } catch (error, stack) {
      if (generation != _generation || !ref.mounted) {
        return;
      }
      debugPrint('Moments feed ${feed.name}: $error');
      if (FirestoreAuthGuard.isPermissionDenied(error)) {
        FirestoreAuthGuard.logPermissionDenied(
          error,
          stack,
          label: 'moments.feed.${feed.name}',
        );
      }
      state = MomentFeedState(
        items: state.items,
        isLoading: false,
        error: error,
        isOffline: FirestoreAuthGuard.isSoftFailError(error) &&
            !FirestoreAuthGuard.isPermissionDenied(error),
      );
    }
  }

  /// Pull to refresh / "Pokušaj ponovo": first page again, keeping the
  /// current cards on screen until it arrives.
  Future<void> refresh() async {
    final generation = ++_generation;
    _cursor = null;
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadFirst(generation, ref.read(momentsRepositoryProvider));
  }

  Future<void> loadMore() async {
    final request = _request;
    final cursor = _cursor;
    if (request == null ||
        cursor == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await ref
          .read(momentsRepositoryProvider)
          .fetchFeedPage(request, cursor: cursor, limit: pageSize);
      if (generation != _generation || !ref.mounted) {
        return;
      }
      _cursor = page.nextCursor;
      ref
          .read(momentPatchesProvider.notifier)
          .loaded(page.items.map((moment) => moment.id));
      final seen = {for (final moment in state.items) moment.id};
      state = state.copyWith(
        items: [
          ...state.items,
          for (final moment in page.items)
            if (seen.add(moment.id)) moment,
        ],
        isLoadingMore: false,
        hasMore: page.hasMore && page.nextCursor != null,
        isOffline: page.isFromCache,
      );
    } catch (error) {
      debugPrint('Moments feed ${feed.name} loadMore: $error');
      if (generation == _generation && ref.mounted) {
        state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
      }
    }
  }
}

final momentFeedProvider = NotifierProvider.family<MomentFeedController,
    MomentFeedState, MomentFeed>(MomentFeedController.new);

/// What a tab shows: loaded pages + my local changes (likes, comments,
/// new and deleted posts), without blocked authors.
final visibleMomentFeedProvider =
    Provider.family<MomentFeedState, MomentFeed>((ref, feed) {
      final state = ref.watch(momentFeedProvider(feed));
      final patches = ref.watch(momentPatchesProvider);
      final blocked = ref.watch(blockedUserIdsProvider);
      final me = ref.watch(momentsMemberIdProvider);
      if (state.blocker != MomentFeedBlocker.none) {
        return state;
      }
      final cityId = feed == MomentFeed.nearby
          ? ref.watch(homeCityProvider.select((city) => city?.id ?? ''))
          : '';
      final created = switch (feed) {
        MomentFeed.forYou => patches.created,
        MomentFeed.nearby => [
          for (final moment in patches.created)
            if (moment.cityId.isNotEmpty && moment.cityId == cityId) moment,
        ],
        MomentFeed.following => const <MomentModel>[],
      };
      final seen = <String>{};
      final items = [
        for (final moment in [...created, ...state.items])
          if (seen.add(moment.id) &&
              !patches.deleted.contains(moment.id) &&
              !blocked.contains(moment.authorUserId))
            patches.apply(moment, me),
      ];
      return state.copyWith(items: items);
    });

// --- Highlights / archive (legacy compatibility) ------------------------------

/// My moments (posts and legacy), newest first – the archive the highlight
/// editor picks from.
final myMomentArchiveProvider = FutureProvider<List<MomentModel>>((ref) async {
  final me = ref.watch(momentsMemberIdProvider);
  if (me.isEmpty) {
    return const [];
  }
  ref.watch(momentPatchesProvider.select((patches) => patches.deleted));
  return ref.watch(momentsRepositoryProvider).fetchByAuthor(me);
});

/// Moments referenced by ids (highlights), keyed by the sorted id list.
final momentsByIdsProvider =
    FutureProvider.family<List<MomentModel>, String>((ref, joinedIds) async {
      final ids = [
        for (final id in joinedIds.split(','))
          if (id.isNotEmpty) id,
      ];
      if (ids.isEmpty) {
        return const [];
      }
      final deleted = ref.watch(
        momentPatchesProvider.select((patches) => patches.deleted),
      );
      final moments =
          await ref.watch(momentsRepositoryProvider).fetchByIds(ids);
      return [
        for (final moment in moments)
          if (!deleted.contains(moment.id)) moment,
      ];
    });

String momentIdsKey(Iterable<String> ids) {
  final sorted = ids.where((id) => id.isNotEmpty).toSet().toList()..sort();
  return sorted.join(',');
}
