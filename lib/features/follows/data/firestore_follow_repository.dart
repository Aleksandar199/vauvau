import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../domain/follow_repository.dart';

class FirestoreFollowRepository implements FollowRepository {
  FirestoreFollowRepository(this._firestore);

  /// Bounds the follow lists read for the stories bar / audience checks.
  static const int listLimit = 500;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _follows =>
      _firestore.collection('follows');

  @override
  Stream<Set<String>> watchFollowing(String userId) {
    return _watchIds(
      field: 'followerUserId',
      userId: userId,
      other: 'followedUserId',
      label: 'follows.following',
    );
  }

  @override
  Stream<Set<String>> watchFollowers(String userId) {
    return _watchIds(
      field: 'followedUserId',
      userId: userId,
      other: 'followerUserId',
      label: 'follows.followers',
    );
  }

  Stream<Set<String>> _watchIds({
    required String field,
    required String userId,
    required String other,
    required String label,
  }) {
    if (userId.isEmpty) {
      return Stream.value(const <String>{});
    }
    return FirestoreAuthGuard.retryingStream<Set<String>>(
      label: label,
      empty: const <String>{},
      create: () => _follows
          .where(field, isEqualTo: userId)
          .limit(listLimit)
          .snapshots()
          .map(
            (snapshot) => {
              for (final doc in snapshot.docs)
                if ((doc.data()[other] as String? ?? '').isNotEmpty)
                  doc.data()[other] as String,
            },
          ),
    );
  }

  @override
  Future<bool> follow({
    required String followerUserId,
    required String followedUserId,
  }) async {
    _validate(followerUserId, followedUserId);
    final ref = _follows.doc(
      FollowRepository.docId(followerUserId, followedUserId),
    );
    // Transaction: a double tap / retry never writes twice, and rules only
    // allow create (an existing relationship is never rewritten).
    return _firestore.runTransaction<bool>((tx) async {
      final snapshot = await tx.get(ref);
      if (snapshot.exists) {
        return false;
      }
      tx.set(ref, {
        'followerUserId': followerUserId,
        'followedUserId': followedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  @override
  Future<void> unfollow({
    required String followerUserId,
    required String followedUserId,
  }) async {
    _validate(followerUserId, followedUserId);
    await _follows
        .doc(FollowRepository.docId(followerUserId, followedUserId))
        .delete();
  }

  void _validate(String followerUserId, String followedUserId) {
    if (followerUserId.isEmpty || followedUserId.isEmpty) {
      throw const FollowException('Morate biti prijavljeni.');
    }
    if (followerUserId == followedUserId) {
      throw const FollowException('Ne možete pratiti sebe.');
    }
  }
}
