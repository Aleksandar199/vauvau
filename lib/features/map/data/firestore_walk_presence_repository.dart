import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/geo/firestore_geo.dart';
import '../../../core/geo/geo.dart';
import '../../discover/data/dog_profile_mapper.dart';
import '../domain/walk_presence_repository.dart';

class FirestoreWalkPresenceRepository implements WalkPresenceRepository {
  FirestoreWalkPresenceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _dogs =>
      _firestore.collection('dogs');

  @override
  Future<void> setWalking({
    required String userId,
    String? dogId,
    required bool isWalking,
    required GeoCoord location,
    String? statusMessage,
  }) {
    final payload = firestoreLocationFields(location, isWalking: isWalking);
    if (isWalking) {
      payload['walkStartedAt'] = FieldValue.serverTimestamp();
      payload['walkStatus'] = statusMessage ?? '';
    } else {
      payload['walkStartedAt'] = FieldValue.delete();
      payload['walkStatus'] = '';
    }
    return _writePresence(userId: userId, dogId: dogId, payload: payload);
  }

  @override
  Future<void> updateLocation({
    required String userId,
    String? dogId,
    required GeoCoord location,
  }) {
    return _writePresence(
      userId: userId,
      dogId: dogId,
      payload: firestoreLocationFields(location),
    );
  }

  /// Caps live walkers to avoid unbounded presence reads.
  static const int maxLiveWalkers = 50;

  @override
  Stream<List<WalkingPresence>> watchWalking({required String excludeUserId}) {
    return FirestoreAuthGuard.guardedStream<List<WalkingPresence>>(
      label: 'map.watchWalking',
      empty: const [],
      create: () => _dogs
          .where('isWalking', isEqualTo: true)
          .limit(maxLiveWalkers)
          .snapshots()
          .map((snapshot) {
        final items = <WalkingPresence>[];
        for (final doc in snapshot.docs) {
          final item = _presenceFrom(doc.id, doc.data());
          if (item == null || item.profile.ownerId == excludeUserId) {
            continue;
          }
          items.add(item);
        }
        return items;
      }),
    );
  }

  Future<void> _writePresence({
    required String userId,
    required String? dogId,
    required Map<String, dynamic> payload,
  }) async {
    await _users.doc(userId).set(payload, SetOptions(merge: true));
    if (dogId != null && dogId.isNotEmpty) {
      await _dogs.doc(dogId).set(payload, SetOptions(merge: true));
      return;
    }
    final snapshot = await _dogs.where('ownerId', isEqualTo: userId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.set(payload, SetOptions(merge: true));
    }
  }

  WalkingPresence? _presenceFrom(String id, Map<String, dynamic> data) {
    final coord = geoCoordFromMap(data);
    if (coord == null) {
      return null;
    }
    final profile = discoverProfileFromMap(id, data);
    final status = data['walkStatus'] as String? ?? '';
    return WalkingPresence(
      profile: profile.copyWith(walking: true),
      coord: coord,
      status: status.isEmpty ? '${profile.name} je u šetnji.' : status,
    );
  }
}

