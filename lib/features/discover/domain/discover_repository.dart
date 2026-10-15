import 'discover_profile.dart';
import 'geo_query.dart';

/// Thrown when the user already spent their Super Like in the last 24 hours.
class SuperLikeDailyLimitException implements Exception {
  const SuperLikeDailyLimitException();

  @override
  String toString() => 'SuperLikeDailyLimitException';
}

class DiscoverPage {
  const DiscoverPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
    this.isFromCache = false,
  });

  final List<DiscoverProfile> items;

  /// Continue after this point with [DiscoverRepository.fetchProfilesPage]
  /// (a Firestore document, or an index for the local repository).
  final Object? nextCursor;
  final bool hasMore;

  /// Served from the offline cache only; may be partial until the server
  /// answers.
  final bool isFromCache;
}

abstract class DiscoverRepository {
  /// Live first page of the Discover feed (newest first): [limit] dogs are
  /// read, then filtered (owner, [geo]). [DiscoverPage.nextCursor] continues
  /// after the last dog read, for [fetchProfilesPage].
  Stream<DiscoverPage> watchProfiles({
    required String excludeOwnerId,
    GeoQuery? geo,
    int limit = 8,
  });

  /// One-shot page after [cursor]. Every filtered dog that was read is
  /// returned (none skipped), so a page may hold more or fewer than [limit].
  Future<DiscoverPage> fetchProfilesPage({
    required String excludeOwnerId,
    GeoQuery? geo,
    Object? cursor,
    int limit = 8,
  });

  Future<bool> swipe({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    required String action,
    String likerName = '',
  });

  Future<bool> hasLiked({required String userId, required String dogId});

  Future<void> unlike({required String userId, required String dogId});

  /// Returns `true` when a reciprocal match was created.
  /// Throws [SuperLikeDailyLimitException] if the daily quota is used up.
  Future<bool> sendSuperLike({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    String likerName = '',
  });

  Future<bool> hasUsedSuperLikeToday({required String userId});
}
