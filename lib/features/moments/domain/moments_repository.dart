import 'moment_model.dart';

abstract class MomentsRepository {
  /// Live first page / window window. [limit] keeps the feed scalable.
  Stream<List<MomentModel>> watchMoments({int limit = 20});

  /// One-shot page for infinite scroll. [cursor] is opaque (Firestore doc or
  /// local offset). Returns an empty [nextCursor] when there is no more data.
  Future<MomentsPage> fetchMomentsPage({
    Object? cursor,
    int limit = 20,
  });

  Stream<List<MomentComment>> watchComments(String momentId);

  Future<void> toggleLike(String momentId);

  Future<void> toggleCommentLike(String momentId, String commentId);

  Future<void> addComment(String momentId, String text);

  Future<String> createMoment(MomentModel moment);

  Future<void> deleteMoment(String momentId);
}

class MomentsPage {
  const MomentsPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<MomentModel> items;
  final Object? nextCursor;
  final bool hasMore;
}
