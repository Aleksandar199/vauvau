import 'dart:async';

import '../domain/follow_repository.dart';

/// In-memory follows for tests and the offline demo.
class LocalFollowRepository implements FollowRepository {
  LocalFollowRepository({Iterable<(String, String)> seed = const []}) {
    for (final (follower, followed) in seed) {
      _edges.add(FollowRepository.docId(follower, followed));
    }
  }

  final Set<String> _edges = {};
  final _changes = StreamController<void>.broadcast();

  /// Every follow() call that created a relationship (for tests).
  int createdCount = 0;

  Set<String> get edges => Set.unmodifiable(_edges);

  Set<String> _following(String userId) => {
        for (final edge in _edges)
          if (edge.startsWith('${userId}_')) edge.substring(userId.length + 1),
      };

  Set<String> _followers(String userId) => {
        for (final edge in _edges)
          if (edge.endsWith('_$userId'))
            edge.substring(0, edge.length - userId.length - 1),
      };

  Stream<Set<String>> _watch(Set<String> Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<Set<String>> watchFollowing(String userId) =>
      _watch(() => _following(userId));

  @override
  Stream<Set<String>> watchFollowers(String userId) =>
      _watch(() => _followers(userId));

  @override
  Future<bool> follow({
    required String followerUserId,
    required String followedUserId,
  }) async {
    if (followerUserId.isEmpty || followedUserId.isEmpty) {
      throw const FollowException('Morate biti prijavljeni.');
    }
    if (followerUserId == followedUserId) {
      throw const FollowException('Ne možete pratiti sebe.');
    }
    final added = _edges.add(
      FollowRepository.docId(followerUserId, followedUserId),
    );
    if (added) {
      createdCount++;
      _changes.add(null);
    }
    return added;
  }

  @override
  Future<void> unfollow({
    required String followerUserId,
    required String followedUserId,
  }) async {
    if (_edges.remove(FollowRepository.docId(followerUserId, followedUserId))) {
      _changes.add(null);
    }
  }

  void dispose() => _changes.close();
}
