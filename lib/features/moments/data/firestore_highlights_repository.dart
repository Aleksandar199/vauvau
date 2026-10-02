import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/highlights_repository.dart';
import '../domain/story_highlight.dart';

/// Highlights live on the dog document (`storyHighlights` map) so they work
/// with the already-deployed owner update rules on `/dogs/{dogId}`.
class FirestoreHighlightsRepository implements HighlightsRepository {
  FirestoreHighlightsRepository({
    required this.firestore,
    required this.currentUserId,
  });

  final FirebaseFirestore firestore;
  final String currentUserId;

  static const _field = 'storyHighlights';

  DocumentReference<Map<String, dynamic>> _dog(String dogId) =>
      firestore.collection('dogs').doc(dogId);

  @override
  Stream<List<StoryHighlight>> watchForDog(String dogId) {
    if (dogId.isEmpty) {
      return Stream.value(const []);
    }
    return _dog(dogId).snapshots().map((snap) {
      final raw = snap.data()?[_field];
      if (raw is! Map) {
        return const <StoryHighlight>[];
      }
      return sortHighlights([
        for (final entry in raw.entries)
          if (entry.value is Map)
            _fromMap(
              id: entry.key.toString(),
              dogId: dogId,
              data: Map<String, dynamic>.from(entry.value as Map),
            ),
      ]);
    });
  }

  @override
  Future<String> create(StoryHighlight highlight) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    if (highlight.dogId.isEmpty) {
      throw StateError('Pas nije izabran.');
    }
    final id = _dog(highlight.dogId).collection('_ids').doc().id;
    try {
      await _dog(highlight.dogId).set({
        _field: {
          id: _payload(highlight, includeOwner: true),
        },
      }, SetOptions(merge: true));
    } catch (error, stack) {
      debugPrint('Highlight create failed: $error');
      debugPrint('$stack');
      rethrow;
    }
    return id;
  }

  @override
  Future<void> update(StoryHighlight highlight) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    try {
      await _dog(highlight.dogId).set({
        _field: {
          highlight.id: _payload(highlight, includeOwner: false),
        },
      }, SetOptions(merge: true));
    } catch (error, stack) {
      debugPrint('Highlight update failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  @override
  Future<void> delete(StoryHighlight highlight) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    try {
      await _dog(highlight.dogId).update({
        '$_field.${highlight.id}': FieldValue.delete(),
      });
    } catch (error, stack) {
      debugPrint('Highlight delete failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  @override
  Future<void> reorder(List<StoryHighlight> ordered) async {
    if (ordered.isEmpty) {
      return;
    }
    final dogId = ordered.first.dogId;
    final patch = <String, Object?>{
      for (var i = 0; i < ordered.length; i++)
        '$_field.${ordered[i].id}.order': i,
    };
    try {
      await _dog(dogId).update(patch);
    } catch (error, stack) {
      debugPrint('Highlight reorder failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  Map<String, Object?> _payload(
    StoryHighlight highlight, {
    required bool includeOwner,
  }) {
    return {
      if (includeOwner) 'ownerId': currentUserId,
      'title': highlight.title.trim(),
      'momentIds': highlight.momentIds,
      'coverMomentId': highlight.coverMomentId,
      'order': highlight.order,
      'createdAt': Timestamp.fromDate(highlight.createdAt),
    };
  }

  StoryHighlight _fromMap({
    required String id,
    required String dogId,
    required Map<String, dynamic> data,
  }) {
    final created = data['createdAt'];
    return StoryHighlight(
      id: id,
      ownerId: data['ownerId'] as String? ?? '',
      dogId: dogId,
      title: data['title'] as String? ?? '',
      momentIds: [
        for (final value in data['momentIds'] as List? ?? const [])
          if (value is String) value,
      ],
      coverMomentId: data['coverMomentId'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}
