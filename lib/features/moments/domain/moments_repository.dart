import 'moment_model.dart';

/// Tabs of the Moments feed.
enum MomentFeed { forYou, following, nearby }

/// What one feed page reads. Only `kind == 'post'` documents are returned.
class MomentFeedRequest {
  const MomentFeedRequest.forYou()
      : feed = MomentFeed.forYou,
        authorIds = const [],
        cityId = '';

  const MomentFeedRequest.following(this.authorIds)
      : feed = MomentFeed.following,
        cityId = '';

  const MomentFeedRequest.nearby(this.cityId)
      : feed = MomentFeed.nearby,
        authorIds = const [];

  /// Firestore `in` takes at most 30 values; larger follow lists are read as
  /// several queries and merged (capped at [maxFollowedAuthors]).
  static const int inQueryLimit = 30;
  static const int maxFollowedAuthors = 300;

  final MomentFeed feed;
  final List<String> authorIds;
  final String cityId;

  List<List<String>> get authorChunks {
    final ids = (authorIds.toSet().toList()..sort()).take(maxFollowedAuthors);
    final list = ids.toList();
    return [
      for (var i = 0; i < list.length; i += inQueryLimit)
        list.sublist(
          i,
          i + inQueryLimit > list.length ? list.length : i + inQueryLimit,
        ),
    ];
  }
}

abstract class MomentsRepository {
  /// Live first window of ALL documents (posts and legacy), newest first.
  /// Used by admin moderation.
  Stream<List<MomentModel>> watchMoments({int limit = 20});

  /// One-shot page of ALL documents for the admin list. [cursor] is opaque
  /// (Firestore doc or local offset).
  Future<MomentsPage> fetchMomentsPage({
    Object? cursor,
    int limit = 20,
  });

  /// One page of feed posts for [request]. Pass the previous page's
  /// [MomentsPage.nextCursor] to continue.
  Future<MomentsPage> fetchFeedPage(
    MomentFeedRequest request, {
    Object? cursor,
    int limit = 10,
  });

  /// Moments by id (highlights). Missing / deleted ids are skipped.
  Future<List<MomentModel>> fetchByIds(List<String> ids);

  /// The author's own moments (posts and legacy), newest first.
  Future<List<MomentModel>> fetchByAuthor(String userId, {int limit = 60});

  /// Number of feed posts (`kind: post`) the author published ("Objave").
  Future<int> countByAuthor(String userId);

  /// Latest [limit] comments, oldest first.
  Stream<List<MomentComment>> watchComments(String momentId, {int limit = 30});

  /// New document id. A draft keeps it across retries, so publishing twice
  /// never creates two posts.
  String newMomentId();

  /// New comment id, reused when sending the same comment again.
  String newCommentId(String momentId);

  /// Idempotent like / unlike by the current user.
  Future<void> setLike(String momentId, {required bool liked});

  Future<void> toggleLike(String momentId);

  Future<void> toggleCommentLike(String momentId, String commentId);

  /// Writes the comment and `commentsCount + 1` together. With the same
  /// [commentId] a retry does not add a second comment.
  Future<String> addComment(
    String momentId,
    String text, {
    String? commentId,
    String replyToCommentId = '',
    String replyToAuthorName = '',
  });

  /// Comment author, the moment's author or admin.
  Future<void> deleteComment(String momentId, String commentId);

  /// Creates `moments/{moment.id}` (generated when empty). Retrying with the
  /// same id is a no-op once the post exists. A [MomentKind.legacy] moment is
  /// written without `kind` (highlight-only copy of a story, never in feed).
  Future<String> createMoment(MomentModel moment);

  /// Deletes the comments, the document and (author only) the photo.
  Future<void> deleteMoment(String momentId);
}

class MomentsPage {
  const MomentsPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
    this.isFromCache = false,
  });

  final List<MomentModel> items;
  final Object? nextCursor;
  final bool hasMore;

  /// Served from the offline cache (no connection).
  final bool isFromCache;
}
