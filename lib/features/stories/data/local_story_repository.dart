import 'dart:async';
import 'dart:typed_data';

import '../domain/story.dart';
import '../domain/story_repository.dart';

/// In-memory stories that apply the same access checks as firestore.rules
/// and storage.rules (author, audience, block, 24h expiry). Used by tests and
/// the offline demo.
class LocalStoryRepository implements StoryRepository {
  LocalStoryRepository({
    bool Function(String followerUserId, String followedUserId)? isFollowing,
    bool Function(String authorUserId, String viewerUserId)? isBlockedBy,
    DateTime Function()? clock,
    Iterable<Story> seed = const [],
  }) : _isFollowing = isFollowing ?? ((_, _) => false),
       _isBlockedBy = isBlockedBy ?? ((_, _) => false),
       _clock = clock ?? DateTime.now {
    for (final story in seed) {
      _stories[story.id] = story;
      _media[story.mediaPath] = Uint8List.fromList(const [1, 2, 3]);
    }
  }

  final bool Function(String, String) _isFollowing;
  final bool Function(String, String) _isBlockedBy;
  final DateTime Function() _clock;

  final Map<String, Story> _stories = {};
  final Map<String, Uint8List> _media = {};
  final Map<String, Map<String, DateTime>> _views = {};
  final Map<String, Set<String>> _likes = {};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  /// When set, the next publish fails while uploading (tests: retry flow).
  Object? failNextUpload;

  int get storyCount => _stories.length;
  bool hasMedia(String path) => _media.containsKey(path);
  Set<String> likesOf(String storyId) => {...?_likes[storyId]};

  /// Same decision as `storyVisible` in firestore.rules (with expiry).
  bool canView(Story story, String viewer) {
    if (viewer.isEmpty) {
      return false;
    }
    if (viewer == story.authorUserId) {
      return true;
    }
    if (!story.isActive(_clock()) || _isBlockedBy(story.authorUserId, viewer)) {
      return false;
    }
    return switch (story.audience) {
      StoryAudience.everyone => true,
      StoryAudience.followers => _isFollowing(viewer, story.authorUserId),
      StoryAudience.following => _isFollowing(story.authorUserId, viewer),
    };
  }

  String _viewer = '';

  /// The signed-in user for reads that do not take one (fetchStory, media).
  set currentUserId(String uid) => _viewer = uid;

  @override
  Stream<List<Story>> watchMyStories(String me) async* {
    _viewer = me;
    List<Story> mine() => [
          for (final story in _stories.values)
            if (story.authorUserId == me && story.isActive(_clock())) story,
        ];
    yield mine();
    yield* _changes.stream.map((_) => mine());
  }

  @override
  Future<List<Story>> fetchStoriesOf({
    required String me,
    required List<StoryRelation> relations,
  }) async {
    _viewer = me;
    final authors = {for (final r in relations) r.authorUserId};
    return [
      for (final story in _stories.values)
        if (authors.contains(story.authorUserId) &&
            story.authorUserId != me &&
            canView(story, me))
          story,
    ];
  }

  @override
  Future<Story?> fetchStory(String storyId) async {
    final story = _stories[storyId];
    if (story == null || !story.isActive(_clock()) || !canView(story, _viewer)) {
      return null;
    }
    return story;
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
    onProgress?.call(0.3);
    final failure = failNextUpload;
    if (failure != null) {
      failNextUpload = null;
      throw failure;
    }
    final id = 'story-${_nextId++}';
    final now = _clock();
    final story = Story(
      id: id,
      authorUserId: me,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      dogId: draft.dogId,
      dogName: draft.dogName,
      dogPhotoUrl: draft.dogPhotoUrl,
      mediaType: draft.mediaType,
      mediaPath: Story.mediaPathFor(me, id),
      caption: draft.caption.trim(),
      audience: draft.audience,
      createdAt: now,
      expiresAt: now.add(Story.lifetime),
    );
    _media[story.mediaPath] = bytes;
    _stories[id] = story;
    onProgress?.call(1);
    _changes.add(null);
    return story;
  }

  @override
  Future<void> delete(Story story) async {
    if (_viewer.isNotEmpty && _viewer != story.authorUserId) {
      throw const StoryAccessException('Možete obrisati samo svoje priče.');
    }
    _stories.remove(story.id);
    _media.remove(story.mediaPath);
    _views.remove(story.id);
    _likes.remove(story.id);
    _changes.add(null);
  }

  @override
  Future<Uint8List> loadMedia(Story story) async {
    final current = _stories[story.id];
    final bytes = _media[story.mediaPath];
    if (current == null || bytes == null || !canView(current, _viewer)) {
      throw const StoryAccessException('Priča nije dostupna.');
    }
    return bytes;
  }

  @override
  Future<String> loadMediaUrl(Story story) async {
    final bytes = await loadMedia(story);
    return Uri.dataFromBytes(bytes, mimeType: 'image/jpeg').toString();
  }

  /// In-memory only: there is no file for a player (tests).
  @override
  Future<String> loadVideoSource(Story story) async {
    await loadMedia(story);
    throw const StoryAccessException('Video nije dostupan.');
  }

  @override
  Future<void> markViewed(Story story, String me) async {
    if (me.isEmpty || me == story.authorUserId || !canView(story, me)) {
      return;
    }
    _views.putIfAbsent(story.id, () => {}).putIfAbsent(me, _clock);
  }

  @override
  Future<bool> isLiked(Story story, String me) async =>
      _likes[story.id]?.contains(me) ?? false;

  @override
  Future<bool> like(Story story, String me) async {
    if (me.isEmpty || me == story.authorUserId) {
      return false;
    }
    if (!canView(story, me)) {
      throw const StoryAccessException('Priča nije dostupna.');
    }
    return _likes.putIfAbsent(story.id, () => {}).add(me);
  }

  @override
  Future<void> unlike(Story story, String me) async {
    _likes[story.id]?.remove(me);
  }

  @override
  Future<List<StoryViewer>> fetchViewers(Story story) async {
    if (_viewer.isNotEmpty && _viewer != story.authorUserId) {
      throw const StoryAccessException('Samo autor vidi preglede.');
    }
    final liked = _likes[story.id] ?? const <String>{};
    final views = _views[story.id] ?? const <String, DateTime>{};
    return [
      for (final entry in views.entries)
        StoryViewer(
          userId: entry.key,
          viewedAt: entry.value,
          liked: liked.contains(entry.key),
        ),
      for (final uid in liked)
        if (!views.containsKey(uid))
          StoryViewer(userId: uid, viewedAt: _clock(), liked: true),
    ];
  }

  @override
  Future<int> cleanupExpired(String me) async {
    final expired = [
      for (final story in _stories.values)
        if (story.authorUserId == me && !story.isActive(_clock())) story,
    ];
    for (final story in expired) {
      await delete(story);
    }
    return expired.length;
  }

  void dispose() => _changes.close();
}
