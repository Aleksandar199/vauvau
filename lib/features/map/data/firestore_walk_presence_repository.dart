import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/geo/firestore_geo.dart';
import '../../../core/geo/geo.dart';
import '../../../core/geo/shared_location.dart';
import '../../auth/data/user_document.dart';
import '../../discover/data/dog_profile_mapper.dart';
import '../domain/walk_presence_repository.dart';

class FirestoreWalkPresenceRepository implements WalkPresenceRepository {
  FirestoreWalkPresenceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _dogs =>
      _firestore.collection('dogs');

  /// Last grid cell published per dog/user: a new fix inside the same cell
  /// changes nothing others can see, so it is not written (fewer writes).
  final Map<String, GeoCoord> _sharedCell = {};

  String _key(String userId, String? dogId) =>
      (dogId != null && dogId.isNotEmpty) ? dogId : userId;

  @override
  Future<void> setWalking({
    required String userId,
    String? dogId,
    required bool isWalking,
    required GeoCoord location,
    String? statusMessage,
  }) async {
    // Others only ever get the centre of a coarse cell, never the GPS point.
    final shared = SharedLocation.approximate(location);
    _sharedCell[_key(userId, dogId)] = shared;
    final payload = firestoreLocationFields(shared, isWalking: isWalking);
    if (isWalking) {
      payload['walkStartedAt'] = FieldValue.serverTimestamp();
      payload['walkStatus'] = statusMessage ?? '';
    } else {
      payload['walkStartedAt'] = FieldValue.delete();
      payload['walkStatus'] = '';
    }
    try {
      await _writePresence(userId: userId, dogId: dogId, payload: payload);
    } catch (_) {
      _sharedCell.remove(_key(userId, dogId));
      rethrow;
    }
  }

  @override
  Future<void> updateLocation({
    required String userId,
    String? dogId,
    required GeoCoord location,
  }) async {
    final shared = SharedLocation.approximate(location);
    final key = _key(userId, dogId);
    if (_sharedCell[key] == shared) {
      return;
    }
    _sharedCell[key] = shared;
    try {
      await _writePresence(
        userId: userId,
        dogId: dogId,
        payload: firestoreLocationFields(shared),
      );
    } catch (_) {
      _sharedCell.remove(key);
      rethrow;
    }
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
    // Owner's own copy goes to the private doc (public users/{uid} is
    // readable by everyone). Nothing reads it — the map reads walkers from
    // dogs — so a rejected write must not stop the dog presence update.
    try {
      await userPrivateDoc(_firestore, userId).set(
        payload,
        SetOptions(merge: true),
      );
    } catch (_) {}
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

