import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/walk_record.dart';

abstract class WalkHistoryRepository {
  Future<void> save(WalkRecord walk);

  Future<List<WalkRecord>> fetchRecent({
    required String userId,
    int days = 7,
  });
}

class FirestoreWalkHistoryRepository implements WalkHistoryRepository {
  FirestoreWalkHistoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _walks(String userId) =>
      _firestore.collection('users').doc(userId).collection('walks');

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _firestore.collection('users').doc(userId);

  @override
  Future<void> save(WalkRecord walk) async {
    final payload = <String, Object?>{
      'id': walk.id,
      'userId': walk.userId,
      'dogId': walk.dogId,
      'distanceKm': walk.distanceKm,
      'durationSeconds': walk.durationSeconds,
      'statusMessage': walk.statusMessage,
      'startedAt': Timestamp.fromDate(walk.startedAt),
      'endedAt': Timestamp.fromDate(walk.endedAt),
    };

    // Reliable path: owner can update own user doc (works with current rules).
    await _user(walk.userId).set(
      {
        'walkHistory': FieldValue.arrayUnion([payload]),
      },
      SetOptions(merge: true),
    );

    // Best-effort subcollection when nested rules are deployed.
    try {
      await _walks(walk.userId).doc(walk.id).set(payload);
    } catch (error) {
      debugPrint('users/{uid}/walks write skipped: $error');
    }
  }

  @override
  Future<List<WalkRecord>> fetchRecent({
    required String userId,
    int days = 7,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final byId = <String, WalkRecord>{};

    try {
      final snap = await _walks(userId)
          .where('endedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .orderBy('endedAt', descending: true)
          .limit(50)
          .get();
      for (final doc in snap.docs) {
        final walk = _fromMap(doc.id, doc.data());
        if (walk != null) byId[walk.id] = walk;
      }
    } catch (error) {
      debugPrint('walks subcollection read skipped: $error');
    }

    try {
      final userSnap = await _user(userId).get();
      final raw = userSnap.data()?['walkHistory'];
      if (raw is List) {
        for (final item in raw) {
          if (item is! Map) continue;
          final walk = _fromMap(
            item['id'] as String? ?? '',
            Map<String, dynamic>.from(item),
          );
          if (walk == null) continue;
          if (walk.endedAt.isBefore(cutoff)) continue;
          byId[walk.id] = walk;
        }
      }
    } catch (error) {
      debugPrint('walkHistory array read failed: $error');
    }

    final list = byId.values.toList()
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return list;
  }

  WalkRecord? _fromMap(String fallbackId, Map<String, dynamic> data) {
    final id = (data['id'] as String? ?? fallbackId).trim();
    if (id.isEmpty) return null;
    final started = data['startedAt'];
    final ended = data['endedAt'];
    final startedAt =
        started is Timestamp ? started.toDate() : DateTime.tryParse('$started');
    final endedAt =
        ended is Timestamp ? ended.toDate() : DateTime.tryParse('$ended');
    if (startedAt == null || endedAt == null) return null;
    return WalkRecord(
      id: id,
      userId: data['userId'] as String? ?? '',
      dogId: data['dogId'] as String? ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      startedAt: startedAt,
      endedAt: endedAt,
      statusMessage: data['statusMessage'] as String? ?? '',
    );
  }
}

class LocalWalkHistoryRepository implements WalkHistoryRepository {
  final List<WalkRecord> _items = [];

  @override
  Future<void> save(WalkRecord walk) async {
    _items.removeWhere((item) => item.id == walk.id);
    _items.insert(0, walk);
  }

  @override
  Future<List<WalkRecord>> fetchRecent({
    required String userId,
    int days = 7,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _items
        .where(
          (walk) =>
              walk.userId == userId && !walk.endedAt.isBefore(cutoff),
        )
        .toList();
  }
}
