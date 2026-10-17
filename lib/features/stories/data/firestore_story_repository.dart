import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../services/storage_service.dart';
import '../domain/story.dart';
import '../domain/story_repository.dart';

/// `stories/{storyId}` + subcollections `story_views/{uid}`, `story_likes/{uid}`.
///
/// Firestore rules enforce the audience and blocks on every query and the
/// 24h expiry on single reads; storage.rules enforce all three on the media.
/// Queries here always ask only for what the rules allow (author chunk ×
/// one audience × not expired), otherwise the whole query would be denied.
class FirestoreStoryRepository implements StoryRepository {
  FirestoreStoryRepository(this._firestore, {StorageService? storage})
    : _storage = storage ?? StorageService();

  /// Firestore `in` accepts at most 30 values.
  static const int authorChunk = 30;
  static const int perQueryLimit = 100;

  final FirebaseFirestore _firestore;
  final StorageService _storage;
  final Set<String> _viewed = {};

  CollectionReference<Map<String, dynamic>> get _stories =>
      _firestore.collection('stories');

  @override
  Stream<List<Story>> watchMyStories(String me) {
    if (me.isEmpty) {
      return Stream.value(const []);
    }
    return FirestoreAuthGuard.guardedStream<List<Story>>(
      label: 'stories.mine',
      empty: const [],
      create: () => _stories
          .where('authorUserId', isEqualTo: me)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .limit(perQueryLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) _fromDoc(doc)]),
    );
  }

  @override
  Future<List<Story>> fetchStoriesOf({
    required String me,
    required List<StoryRelation> relations,
  }) async {
    if (me.isEmpty || relations.isEmpty) {
      return const [];
    }
    final byAudience = <StoryAudience, List<String>>{};
    for (final relation in relations) {
      if (relation.authorUserId.isEmpty || relation.authorUserId == me) {
        continue;
      }
      for (final audience in relation.visibleAudiences) {
        byAudience.putIfAbsent(audience, () => []).add(relation.authorUserId);
      }
    }
    final now = Timestamp.now();
    final results = <Story>[];
    for (final entry in byAudience.entries) {
      final authors = entry.value;
      for (var i = 0; i < authors.length; i += authorChunk) {
        final chunk = authors.sublist(
          i,
          (i + authorChunk).clamp(0, authors.length),
        );
        results.addAll(await _queryChunk(chunk, entry.key, now));
      }
    }
    return results;
  }

  Future<List<Story>> _queryChunk(
    List<String> authors,
    StoryAudience audience,
    Timestamp now,
  ) async {
    Future<List<Story>> run(List<String> ids) async {
      final snapshot = await _stories
          .where('authorUserId', whereIn: ids)
          .where('audience', isEqualTo: audience.key)
          .where('expiresAt', isGreaterThan: now)
          .limit(perQueryLimit)
          .get();
      return [for (final doc in snapshot.docs) _fromDoc(doc)];
    }

    try {
      return await run(authors);
    } catch (error) {
      if (!FirestoreAuthGuard.isPermissionDenied(error) || authors.length < 2) {
        debugPrint('stories ${audience.key} query failed: $error');
        return const [];
      }
      // One stale relation (just unfollowed / blocked) denies the whole
      // chunk: ask author by author and skip the ones that are denied.
      final stories = <Story>[];
      for (final author in authors) {
        try {
          stories.addAll(await run([author]));
        } catch (_) {}
      }
      return stories;
    }
  }

  @override
  Future<Story?> fetchStory(String storyId) async {
    if (storyId.isEmpty) {
      return null;
    }
    try {
      final snapshot = await _stories.doc(storyId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final story = _fromMap(snapshot.id, snapshot.data()!, pending: false);
      return story.isActive(DateTime.now()) ? story : null;
    } catch (error) {
      // permission-denied = expired, blocked or outside the audience.
      debugPrint('fetchStory $storyId: $error');
      return null;
    }
  }

  @override
  Future<Story> publish({
    required String me,
    required String authorName,
    required String authorPhotoUrl,
    required StoryDraft draft,
    required Uint8List bytes,
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    if (me.isEmpty) {
      throw const StoryAccessException('Morate biti prijavljeni.');
    }
    final ref = _stories.doc();
    final path = Story.mediaPathFor(me, ref.id);
    await _storage.uploadPrivateBytes(
      path: path,
      bytes: bytes,
      mimeType: mimeType,
      onProgress: onProgress,
    );
    final now = DateTime.now();
    final expiresAt = now.add(Story.lifetime);
    final caption = draft.caption.trim();
    final data = <String, Object>{
      'authorUserId': me,
      'authorName': authorName.trim().isEmpty ? 'Korisnik' : authorName.trim(),
      'authorPhotoUrl': authorPhotoUrl.trim(),
      'dogId': draft.dogId.trim(),
      'dogName': draft.dogName.trim(),
      'dogPhotoUrl': draft.dogPhotoUrl.trim(),
      'mediaType': StoryMediaType.image.key,
      'mediaPath': path,
      'caption': caption.length > Story.maxCaptionLength
          ? caption.substring(0, Story.maxCaptionLength)
          : caption,
      'audience': draft.audience.key,
      'status': 'published',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
    try {
      await ref.set(data);
    } catch (error) {
      // No half-published story: the media goes away with the failed doc.
      await _storage.deletePrivatePath(path);
      rethrow;
    }
    return _fromMap(ref.id, {
      ...data,
      'createdAt': Timestamp.fromDate(now),
    }, pending: false);
  }

  @override
  Future<void> delete(Story story) async {
    final ref = _stories.doc(story.id);
    // Children first: their delete rule reads the parent story.
    for (final name in const ['story_views', 'story_likes']) {
      try {
        final children = await ref.collection(name).limit(500).get();
        if (children.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in children.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (error) {
        debugPrint('story ${story.id} $name cleanup failed: $error');
      }
    }
    await ref.delete();
    await _storage.deletePrivatePath(story.mediaPath);
  }

  @override
  Future<Uint8List> loadMedia(Story story) async {
    try {
      return await _storage.downloadPrivateBytes(story.mediaPath);
    } catch (error) {
      throw StoryAccessException('$error');
    }
  }

  @override
  Future<void> markViewed(Story story, String me) async {
    if (me.isEmpty || me == story.authorUserId || !_viewed.add(story.id)) {
      return;
    }
    try {
      await _stories.doc(story.id).collection('story_views').doc(me).set({
        'viewerUserId': me,
        'viewedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(story.expiresAt),
      });
    } catch (error) {
      // Already recorded (rules allow create only) or no longer visible.
      debugPrint('markViewed ${story.id}: $error');
    }
  }

  DocumentReference<Map<String, dynamic>> _likeRef(Story story, String me) =>
      _stories.doc(story.id).collection('story_likes').doc(me);

  @override
  Future<bool> isLiked(Story story, String me) async {
    if (me.isEmpty) {
      return false;
    }
    try {
      return (await _likeRef(story, me).get()).exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> like(Story story, String me) async {
    if (me.isEmpty || me == story.authorUserId) {
      return false;
    }
    final ref = _likeRef(story, me);
    // Doc id = my uid → one like per user; the transaction keeps a double
    // tap from turning into a rejected second create.
    return _firestore.runTransaction<bool>((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) {
        return false;
      }
      tx.set(ref, {
        'userId': me,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(story.expiresAt),
      });
      return true;
    });
  }

  @override
  Future<void> unlike(Story story, String me) async {
    if (me.isEmpty) {
      return;
    }
    await _likeRef(story, me).delete();
  }

  @override
  Future<List<StoryViewer>> fetchViewers(Story story) async {
    final ref = _stories.doc(story.id);
    final views = await ref.collection('story_views').limit(500).get();
    final likes = await ref.collection('story_likes').limit(500).get();
    final liked = {for (final doc in likes.docs) doc.id};
    final viewers = <String, StoryViewer>{};
    for (final doc in views.docs) {
      viewers[doc.id] = StoryViewer(
        userId: doc.id,
        viewedAt: _date(doc.data()['viewedAt']),
        liked: liked.contains(doc.id),
      );
    }
    // A like implies a view even if the view write was lost.
    for (final doc in likes.docs) {
      viewers.putIfAbsent(
        doc.id,
        () => StoryViewer(
          userId: doc.id,
          viewedAt: _date(doc.data()['createdAt']),
          liked: true,
        ),
      );
    }
    return viewers.values.toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
  }

  @override
  Future<int> cleanupExpired(String me) async {
    if (me.isEmpty) {
      return 0;
    }
    try {
      final snapshot = await _stories
          .where('authorUserId', isEqualTo: me)
          .where('expiresAt', isLessThanOrEqualTo: Timestamp.now())
          .limit(20)
          .get();
      var removed = 0;
      for (final doc in snapshot.docs) {
        try {
          await delete(_fromDoc(doc));
          removed++;
        } catch (error) {
          debugPrint('cleanup story ${doc.id}: $error');
        }
      }
      return removed;
    } catch (error) {
      debugPrint('stories cleanup failed: $error');
      return 0;
    }
  }

  Story _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      _fromMap(doc.id, doc.data(), pending: doc.metadata.hasPendingWrites);

  Story _fromMap(String id, Map<String, dynamic> data, {required bool pending}) {
    final created = pending || data['createdAt'] == null
        ? DateTime.now()
        : _date(data['createdAt']);
    final expires = data['expiresAt'] == null
        ? created.add(Story.lifetime)
        : _date(data['expiresAt']);
    final author = data['authorUserId'] as String? ?? '';
    return Story(
      id: id,
      authorUserId: author,
      authorName: (data['authorName'] as String? ?? '').trim().isEmpty
          ? 'Korisnik'
          : (data['authorName'] as String).trim(),
      authorPhotoUrl: data['authorPhotoUrl'] as String? ?? '',
      dogId: data['dogId'] as String? ?? '',
      dogName: data['dogName'] as String? ?? '',
      dogPhotoUrl: data['dogPhotoUrl'] as String? ?? '',
      mediaPath:
          data['mediaPath'] as String? ?? Story.mediaPathFor(author, id),
      caption: data['caption'] as String? ?? '',
      audience: StoryAudience.fromKey(data['audience'] as String?),
      createdAt: created,
      // Never trust a later expiry than 24h after creation.
      expiresAt: expires.isAfter(created.add(Story.lifetime))
          ? created.add(Story.lifetime)
          : expires,
    );
  }

  DateTime _date(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.now();
  }
}
