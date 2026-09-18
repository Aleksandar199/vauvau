import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/discover_profile.dart';
import '../domain/discover_repository.dart';
import 'dog_profile_mapper.dart';

class FirestoreDiscoverRepository implements DiscoverRepository {
  FirestoreDiscoverRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _dogs =>
      _firestore.collection('dogs');

  CollectionReference<Map<String, dynamic>> get _swipes =>
      _firestore.collection('swipes');

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  @override
  Stream<List<DiscoverProfile>> watchProfiles({required String excludeOwnerId}) {
    return _dogs.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => discoverProfileFromMap(doc.id, doc.data()))
          .where((profile) => profile.ownerId != excludeOwnerId)
          .toList();
    });
  }

  @override
  Future<bool> swipe({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    required String action,
  }) async {
    final swipeRef = _swipes.doc();
    await swipeRef.set({
      'id': swipeRef.id,
      'userId': userId,
      'targetDogId': target.id,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (action != 'like') {
      return false;
    }
    final reciprocal = await _swipes
        .where('userId', isEqualTo: target.ownerId)
        .where('targetDogId', isEqualTo: myDogId)
        .where('action', isEqualTo: 'like')
        .limit(1)
        .get();
    if (reciprocal.docs.isEmpty) {
      return false;
    }
    final ids = [userId, target.ownerId]..sort();
    final matchId = ids.join('_');
    await _matches.doc(matchId).set({
      'id': matchId,
      'dogIds': [myDogId, target.id],
      'userIds': [userId, target.ownerId],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _chats.doc(matchId).set({
      'id': matchId,
      'participantIds': [userId, target.ownerId],
      'dogIds': [myDogId, target.id],
      'dogId': target.id,
      'dogName': target.name,
      'ownerName': target.ownerName,
      'breed': target.breed,
      'location': target.location,
      'photoUrl': target.photoUrls.isEmpty ? '' : target.photoUrls.first,
      'peerUserId': target.ownerId,
      'lastMessage': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'isNewMatch': true,
      'unreadCount': 0,
    }, SetOptions(merge: true));
    return true;
  }
}
