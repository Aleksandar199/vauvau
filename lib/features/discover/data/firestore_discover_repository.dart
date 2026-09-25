import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/geo/geo.dart';
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
  }) {
    if (geo == null) {
      return _dogs.snapshots().map(
            (snapshot) => _fromDocs(snapshot.docs, geo),
          );
    }
    final prefixes = GeoHash.coveragePrefixes(
      latitude: geo.origin.latitude,
      longitude: geo.origin.longitude,
      radiusKm: geo.radiusKm,
    );
    return _mergeGeohashQueries(prefixes, geo);
  }

  Stream<List<DiscoverProfile>> _mergeGeohashQueries(
    List<String> prefixes,
    GeoQuery geo,
  ) {
    final controller = StreamController<List<DiscoverProfile>>.broadcast();
    final latest = List<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>.filled(
      prefixes.length,
      null,
    );
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() {
      final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final docs in latest) {
        if (docs == null) {
          continue;
        }
        for (final doc in docs) {
          byId[doc.id] = doc;
        }
      }
      if (!controller.isClosed) {
        controller.add(_fromDocs(byId.values, geo));
      }
    }

    for (var i = 0; i < prefixes.length; i++) {
      final prefix = prefixes[i];
      subs.add(
        _dogs
            .orderBy('geohash')
            .startAt([prefix])
            .endAt(['$prefix\uf8ff'])
            .snapshots()
            .listen((snapshot) {
          latest[i] = snapshot.docs;
          emit();
        }),
      );
    }

    controller.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };
    return controller.stream;
  }

  List<DiscoverProfile> _fromDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    GeoQuery? geo,
  ) {
    final profiles = <DiscoverProfile>[];
    for (final doc in docs) {
      final data = doc.data();
      final profile = discoverProfileFromMap(doc.id, data);
      debugPrint(
        '🐶 DOG DEBUG: Name: ${profile.name}, imageUrl: ${profile.imageUrl}, photoUrl: ${data['photoUrl']}, photos: ${data['photos']}',
      );
      debugPrint(
        '🐶 DOG DEBUG RAW id=${profile.id} photoUrls=${data['photoUrls']} galleryUrls=${data['galleryUrls']} imageUrl=${data['imageUrl']} image=${data['image']}',
      );
      profiles.add(profile);
    }
    return geo == null ? profiles : geo.apply(profiles);
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
      'photoUrl': resolvedDogPhotoUrl(target.photoUrls),
      'peerUserId': target.ownerId,
      'lastMessage': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'isNewMatch': true,
      'unreadCount': 0,
    }, SetOptions(merge: true));
    return true;
  }
}
