import 'discover_profile.dart';
import 'geo_query.dart';

/// Thrown when the user already spent their Super Like in the last 24 hours.
class SuperLikeDailyLimitException implements Exception {
  const SuperLikeDailyLimitException();

  @override
  String toString() => 'SuperLikeDailyLimitException';
}

abstract class DiscoverRepository {
  Stream<List<DiscoverProfile>> watchProfiles({
    required String excludeOwnerId,
    GeoQuery? geo,
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
