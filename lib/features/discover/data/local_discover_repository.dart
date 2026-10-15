import '../domain/discover_profile.dart';
import '../domain/discover_repository.dart';
import '../domain/geo_query.dart';
import 'mock_discover_profiles.dart';

class LocalDiscoverRepository implements DiscoverRepository {
  LocalDiscoverRepository({List<DiscoverProfile>? seed})
    : _profiles = seed ?? mockDiscoverProfiles;

  final List<DiscoverProfile> _profiles;
  final Set<String> _likes = {};
  final Map<String, DateTime> _lastSuperLikeAt = {};
  final Set<String> _superLikedDogs = {};

  @override
  Stream<DiscoverPage> watchProfiles({
    required String excludeOwnerId,
    GeoQuery? geo,
    int limit = 8,
  }) {
    return Stream.fromFuture(
      fetchProfilesPage(
        excludeOwnerId: excludeOwnerId,
        geo: geo,
        limit: limit,
      ),
    );
  }

  @override
  Future<DiscoverPage> fetchProfilesPage({
    required String excludeOwnerId,
    GeoQuery? geo,
    Object? cursor,
    int limit = 8,
  }) async {
    final all = _page(_profiles, excludeOwnerId, geo);
    final start = cursor is int ? cursor : 0;
    final end = (start + limit).clamp(0, all.length);
    final items = all.sublist(start.clamp(0, all.length), end);
    final next = end < all.length ? end : null;
    return DiscoverPage(
      items: items,
      nextCursor: next,
      hasMore: next != null,
    );
  }

  List<DiscoverProfile> _page(
    List<DiscoverProfile> source,
    String excludeOwnerId,
    GeoQuery? geo,
  ) {
    var list = [
      for (final profile in source)
        if (excludeOwnerId.isEmpty || profile.ownerId != excludeOwnerId) profile,
    ];
    if (geo != null) {
      list = geo.apply(list);
    }
    return list..sort(DiscoverProfile.compareFeedOrder);
  }

  @override
  Future<bool> swipe({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    required String action,
    String likerName = '',
  }) async {
    if (action == 'superLike') {
      return sendSuperLike(
        userId: userId,
        myDogId: myDogId,
        target: target,
        likerName: likerName,
      );
    }
    if (action != 'like') {
      return false;
    }
    _likes.add('$userId:${target.id}');
    // ignore: avoid_print
    print('DOG LIKE SUCCESS for: ${target.id}');
    return false;
  }

  @override
  Future<bool> hasLiked({required String userId, required String dogId}) async {
    return _likes.contains('$userId:$dogId');
  }

  @override
  Future<void> unlike({required String userId, required String dogId}) async {
    _likes.remove('$userId:$dogId');
  }

  @override
  Future<bool> hasUsedSuperLikeToday({required String userId}) async {
    final last = _lastSuperLikeAt[userId];
    if (last == null) {
      return false;
    }
    return DateTime.now().difference(last) < const Duration(hours: 24);
  }

  @override
  Future<bool> sendSuperLike({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    String likerName = '',
  }) async {
    if (await hasUsedSuperLikeToday(userId: userId)) {
      throw const SuperLikeDailyLimitException();
    }
    _lastSuperLikeAt[userId] = DateTime.now();
    _superLikedDogs.add('$userId:${target.id}');
    _likes.add('$userId:${target.id}');
    // ignore: avoid_print
    print('DOG SUPER LIKE SUCCESS for: ${target.id}');
    return false;
  }
}
