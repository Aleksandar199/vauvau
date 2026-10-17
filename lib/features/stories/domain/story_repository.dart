import 'dart:typed_data';

import 'story.dart';

/// Relationship of the viewer to one author, used to ask only for stories
/// the rules will allow (rules are the real check).
class StoryRelation {
  const StoryRelation({
    required this.authorUserId,
    required this.iFollowAuthor,
    required this.authorFollowsMe,
  });

  final String authorUserId;
  final bool iFollowAuthor;
  final bool authorFollowsMe;

  Set<StoryAudience> get visibleAudiences => {
        StoryAudience.everyone,
        if (iFollowAuthor) StoryAudience.followers,
        if (authorFollowsMe) StoryAudience.following,
      };
}

class StoryAccessException implements Exception {
  const StoryAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class StoryRepository {
  /// My active stories (live).
  Stream<List<Story>> watchMyStories(String me);

  /// Active stories of [relations] (accounts I follow) that I may view.
  /// Queries are bounded per author chunk and per audience.
  Future<List<Story>> fetchStoriesOf({
    required String me,
    required List<StoryRelation> relations,
  });

  /// One story, or null when it is gone, expired or not visible to me.
  Future<Story?> fetchStory(String storyId);

  /// Uploads the photo, then creates the story doc. If creating the doc
  /// fails the uploaded media is removed again.
  Future<Story> publish({
    required String me,
    required String authorName,
    required String authorPhotoUrl,
    required StoryDraft draft,
    required Uint8List bytes,
    String? mimeType,
    void Function(double progress)? onProgress,
  });

  /// Author only: removes the story, its media and its views / likes.
  Future<void> delete(Story story);

  /// Story media bytes; throws [StoryAccessException] when not allowed.
  Future<Uint8List> loadMedia(Story story);

  /// Records that [me] viewed [story] (idempotent, never for the author).
  Future<void> markViewed(Story story, String me);

  Future<bool> isLiked(Story story, String me);

  /// Returns true when a new like was created (false: already liked).
  Future<bool> like(Story story, String me);

  Future<void> unlike(Story story, String me);

  /// Author only: who viewed / liked the story.
  Future<List<StoryViewer>> fetchViewers(Story story);

  /// Author only, best effort: deletes my expired stories and their media
  /// (Firestore never deletes them on its own; TTL is a backup).
  Future<int> cleanupExpired(String me);
}
