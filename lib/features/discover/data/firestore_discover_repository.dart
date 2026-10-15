import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../domain/discover_profile.dart';
import '../domain/discover_repository.dart';
import '../domain/geo_query.dart';
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
  Stream<List<DiscoverProfile>> watchProfiles({
    required String excludeOwnerId,
    GeoQuery? geo,
    int limit = 15,
  }) {
    return FirestoreAuthGuard.guardedStream<List<DiscoverProfile>>(
      label: 'discover.watchProfiles',
      empty: const [],
      create: () => _dogs
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => _filterProfiles(
              snapshot.docs,
              excludeOwnerId: excludeOwnerId,
              geo: geo,
            ),
          ),
    );
  }

  @override
  Future<DiscoverPage> fetchProfilesPage({
    required String excludeOwnerId,
    GeoQuery? geo,
    Object? cursor,
    int limit = 15,
  }) {
    return FirestoreAuthGuard.run(
      label: 'discover.fetchProfilesPage',
      fallback: const DiscoverPage(items: [], hasMore: false),
      action: () async {
        // Oversample when geo-filtering so a page still yields nearby dogs.
        final fetchSize = geo == null ? limit : limit * 3;
        var collected = <DiscoverProfile>[];
        Object? next = cursor;
        var rawExhausted = false;
        // Cap fan-out: at most a few round-trips per loadMore call.
        for (var attempt = 0;
            attempt < 3 && collected.length < limit;
            attempt++) {
          Query<Map<String, dynamic>> query =
              _dogs.orderBy('createdAt', descending: true).limit(fetchSize);
          final start = next;
          if (start is DocumentSnapshot<Map<String, dynamic>>) {
            query = query.startAfterDocument(start);
          } else if (start is QueryDocumentSnapshot<Map<String, dynamic>>) {
            query = query.startAfterDocument(start);
          }
          final snapshot = await query.get();
          if (snapshot.docs.isEmpty) {
            rawExhausted = true;
            next = null;
            break;
          }
          next = snapshot.docs.last;
          rawExhausted = snapshot.docs.length < fetchSize;
          collected = [
            ...collected,
            ..._filterProfiles(
              snapshot.docs,
              excludeOwnerId: excludeOwnerId,
              geo: geo,
            ),
          ];
          final seen = <String>{};
          collected = [
            for (final profile in collected)
              if (seen.add(profile.id)) profile,
          ];
          if (rawExhausted) {
            break;
          }
        }
        final page = collected.take(limit).toList();
        return DiscoverPage(
          items: page,
          nextCursor: rawExhausted && page.length < limit ? null : next,
          hasMore: !rawExhausted || collected.length > limit,
        );
      },
    );
  }

  List<DiscoverProfile> _filterProfiles(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String excludeOwnerId,
    GeoQuery? geo,
  }) {
    final profiles = <DiscoverProfile>[];
    for (final doc in docs) {
      final profile = discoverProfileFromMap(doc.id, doc.data());
      if (excludeOwnerId.isNotEmpty && profile.ownerId == excludeOwnerId) {
        continue;
      }
      profiles.add(profile);
    }
    final filtered = geo == null ? profiles : geo.apply(profiles);
    return filtered..sort(DiscoverProfile.compareFeedOrder);
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
    if (action == 'like') {
      await _recordLike(
        userId: userId,
        myDogId: myDogId,
        likerName: likerName,
        target: target,
        type: action,
      );
      return _tryCreateMatch(userId: userId, myDogId: myDogId, target: target);
    }
    await _swipes.doc('${userId}_${target.id}').set({
      'fromUserId': userId,
      'fromDogId': myDogId,
      'toDogId': target.id,
      'type': action,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return false;
  }

  @override
  Future<bool> hasUsedSuperLikeToday({required String userId}) async {
    if (userId.isEmpty) {
      return false;
    }
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final snapshot = await _firestore
          .collection('super_likes')
          .where('fromUserId', isEqualTo: userId)
          .limit(25)
          .get();
      for (final doc in snapshot.docs) {
        final created = doc.data()['createdAt'];
        final at = created is Timestamp ? created.toDate() : null;
        if (at != null && at.isAfter(cutoff)) {
          return true;
        }
      }
      return false;
    } catch (error) {
      debugPrint('hasUsedSuperLikeToday failed: $error');
      return false;
    }
  }

  @override
  Future<bool> sendSuperLike({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    String likerName = '',
  }) async {
    if (userId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    if (await hasUsedSuperLikeToday(userId: userId)) {
      throw const SuperLikeDailyLimitException();
    }

    // One counted super like per user per dog: marker super_likes/{uid}_{dog}
    // and superLikesCount +1 go in one batch (rules check both together).
    final marker =
        _firestore.collection('super_likes').doc('${userId}_${target.id}');
    if (!await _existsSafely(marker)) {
      final batch = _firestore.batch()
        ..set(marker, {
          'fromUserId': userId,
          'targetDogId': target.id,
          'targetOwnerId': target.ownerId,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..set(
          _firestore.collection('dogs').doc(target.id),
          {'superLikesCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      await batch.commit();
    }

    await _recordLike(
      userId: userId,
      myDogId: myDogId,
      likerName: likerName,
      target: target,
      type: 'superLike',
    );

    await _notifySuperLike(
      userId: userId,
      myDogId: myDogId,
      likerName: likerName,
      target: target,
    );

    return _tryCreateMatch(userId: userId, myDogId: myDogId, target: target);
  }

  Future<void> _notifySuperLike({
    required String userId,
    required String myDogId,
    required String likerName,
    required DiscoverProfile target,
  }) async {
    if (target.ownerId.isEmpty || target.ownerId == userId) {
      return;
    }
    var senderName = likerName.trim();
    if (senderName.isEmpty) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      senderName = (data?['name'] as String?)?.trim() ?? '';
      if (senderName.isEmpty) {
        // Never fall back to email: it would be shown to the recipient.
        senderName = 'Neko';
      }
    }
    final title = '⭐ Super Like!';
    final body = '$senderName je dao Super Like vašem psu ${target.name}!';
    try {
      await _firestore.collection('notifications').add({
        'recipientId': target.ownerId,
        'toUserId': target.ownerId,
        'senderId': userId,
        'fromUserId': userId,
        'senderUserId': userId,
        'type': 'SUPER_LIKE',
        'title': title,
        'message': body,
        'body': body,
        'dogId': target.id,
        'senderDogId': myDogId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (error) {
      debugPrint('Super Like obaveštenje nije upisano: $error');
    }
  }

  /// Reading a missing chat room / super-like marker is denied by the
  /// previous firestore.rules; treat that as "does not exist yet".
  Future<bool> _existsSafely(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      return (await ref.get()).exists;
    } catch (error) {
      debugPrint('existence check ${ref.path} failed: $error');
      return false;
    }
  }

  Future<bool> _tryCreateMatch({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
  }) async {
    try {
      final reciprocal = await _swipes
          .where('fromUserId', isEqualTo: target.ownerId)
          .where('toDogId', isEqualTo: myDogId)
          .limit(5)
          .get();
      final likedBack = reciprocal.docs.any((doc) {
        final type = doc.data()['type'] as String?;
        return type == null || type == 'like' || type == 'superLike';
      });
      if (!likedBack) {
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
      // Re-match must not reset an existing room's lastMessage / unread.
      final room = _chats.doc(matchId);
      if (await _existsSafely(room)) {
        return true;
      }
      await room.set({
        'id': matchId,
        'participantIds': [userId, target.ownerId],
        'dogIds': [myDogId, target.id],
        'dogId': target.id,
        'dogName': target.name,
        'ownerName': target.ownerName,
        'breed': target.breed,
        'location': target.location,
        'photoUrl': resolvedDogPhotoUrl(target.photoUrls),
        'peerUserId': target.ownerId,
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'isNewMatch': true,
        'unreadCount': 0,
      }, SetOptions(merge: true));
      return true;
    } catch (error) {
      debugPrint('Match after like failed: $error');
      return false;
    }
  }

  @override
  Future<bool> hasLiked({required String userId, required String dogId}) async {
    try {
      final likeSnap = await _firestore
          .collection('dogs')
          .doc(dogId)
          .collection('likes')
          .doc(userId)
          .get();
      if (likeSnap.exists) {
        return true;
      }
      final snapshot = await _swipes.doc('${userId}_$dogId').get();
      final type = snapshot.data()?['type'] as String?;
      return snapshot.exists &&
          (type == null || type == 'like' || type == 'superLike');
    } catch (error) {
      debugPrint('hasLiked failed: $error');
      return false;
    }
  }

  @override
  Future<void> unlike({required String userId, required String dogId}) async {
    if (userId.isEmpty || dogId.isEmpty) {
      return;
    }
    final likeRef = _firestore
        .collection('dogs')
        .doc(dogId)
        .collection('likes')
        .doc(userId);
    final likeSnap = await likeRef.get();
    if (likeSnap.exists) {
      // Rules require the like doc and likesCount to change in one batch.
      // The super-like marker (and superLikesCount) stays: it counts once.
      final batch = _firestore.batch()
        ..delete(likeRef)
        ..set(
          _firestore.collection('dogs').doc(dogId),
          {'likesCount': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );
      try {
        await batch.commit();
      } catch (error) {
        debugPrint('unlike failed: $error');
      }
    }
    try {
      await _swipes.doc('${userId}_$dogId').delete();
    } catch (_) {}
  }

  Future<void> _recordLike({
    required String userId,
    required String myDogId,
    required String likerName,
    required DiscoverProfile target,
    required String type,
  }) async {
    final dogId = target.id;
    final swipeRef = _swipes.doc('${userId}_$dogId');
    final existing = await swipeRef.get();
    await swipeRef.set({
      'fromUserId': userId,
      'fromDogId': myDogId,
      'toDogId': dogId,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final dogRef = _firestore.collection('dogs').doc(dogId);
    final likeRef = dogRef.collection('likes').doc(userId);
    final likeExisting = await likeRef.get();
    // Keep a super like marked as such when the user later swipes like.
    final likeType =
        likeExisting.data()?['type'] == 'superLike' ? 'superLike' : type;
    // Rules only accept likesCount changes in the same batch as the like doc.
    final batch = _firestore.batch()
      ..set(likeRef, {
        'userId': userId,
        'type': likeType,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    if (!likeExisting.exists) {
      batch.set(
        dogRef,
        {'likesCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    // ignore: avoid_print
    print('DOG LIKE SUCCESS for: $dogId');
    if (!existing.exists && type != 'superLike') {
      try {
        await _notifyLike(
          userId: userId,
          myDogId: myDogId,
          likerName: likerName,
          target: target,
        );
      } catch (error) {
        debugPrint('Obaveštenje o lajku nije upisano: $error');
      }
    }
  }

  Future<void> _notifyLike({
    required String userId,
    required String myDogId,
    required String likerName,
    required DiscoverProfile target,
  }) async {
    if (target.ownerId.isEmpty || target.ownerId == userId) {
      return;
    }
    var senderName = likerName.trim();
    if (senderName.isEmpty) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      senderName = (data?['name'] as String?)?.trim() ?? '';
      if (senderName.isEmpty) {
        // Never fall back to email: it would be shown to the recipient.
        senderName = 'Neko';
      }
    }
    final payload = <String, dynamic>{
      'fromUserId': userId,
      'senderUserId': userId,
      'toUserId': target.ownerId,
      'title': 'Novi lajk! 🐾',
      'body': '$senderName je lajkovao/la tvog psa ${target.name}!',
      'type': 'like',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'dogId': myDogId,
      'senderDogId': myDogId,
    };
    try {
      await _firestore.collection('notifications').add(payload);
    } catch (error) {
      debugPrint('Obaveštenje sa dogId nije upisano, retry: $error');
      await _firestore.collection('notifications').add({
        'fromUserId': userId,
        'toUserId': target.ownerId,
        'title': payload['title'],
        'body': payload['body'],
        'type': 'like',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
