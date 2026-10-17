/// Follow = one owner account following another (never per dog).
///
/// Stored as `follows/{followerUserId}_{followedUserId}`: the id itself makes
/// a duplicate relationship impossible.
abstract class FollowRepository {
  static String docId(String followerUserId, String followedUserId) =>
      '${followerUserId}_$followedUserId';

  /// Owners the user follows ("Osobe koje ja pratim").
  Stream<Set<String>> watchFollowing(String userId);

  /// Owners who follow the user ("Moji pratioci").
  Stream<Set<String>> watchFollowers(String userId);

  /// Idempotent: following twice keeps one relationship. Returns true when
  /// a new relationship was created (false if it already existed).
  Future<bool> follow({
    required String followerUserId,
    required String followedUserId,
  });

  /// Idempotent: unfollowing someone not followed is a no-op.
  Future<void> unfollow({
    required String followerUserId,
    required String followedUserId,
  });
}

class FollowException implements Exception {
  const FollowException(this.message);

  final String message;

  @override
  String toString() => message;
}
