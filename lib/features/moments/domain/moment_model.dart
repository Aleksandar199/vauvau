/// What a `moments/{id}` document is.
///
/// [post] = permanent community post (`kind: 'post'`), shown in the Moments
/// feed until the author deletes it or moderation removes it.
/// [legacy] = document written before the redesign (no `kind`). The old app
/// presented those as 24h stories, so they never enter the permanent feed;
/// they stay reachable through dog highlights and the author's archive.
enum MomentKind { post, legacy }

class MomentModel {
  const MomentModel({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.dogId,
    required this.dogName,
    required this.dogBreed,
    required this.dogPhotoUrl,
    required this.momentPhotoUrl,
    required this.caption,
    required this.locationName,
    required this.likes,
    required this.commentsCount,
    required this.createdAt,
    this.kind = MomentKind.post,
    this.cityId = '',
    this.authorPhotoUrl = '',
  });

  static const String postKind = 'post';
  static const int maxCaptionLength = 2200;

  final String id;
  final String authorUserId;
  final String authorName;
  final String dogId;
  final String dogName;
  final String dogBreed;
  final String dogPhotoUrl;
  final String momentPhotoUrl;
  final String caption;
  final String locationName;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;
  final MomentKind kind;

  /// [SerbiaLocations] id the author picked (empty on legacy documents).
  final String cityId;
  final String authorPhotoUrl;

  bool get isPost => kind == MomentKind.post;

  bool get hasDog => dogId.trim().isNotEmpty;

  int get likeCount => likes.length;

  bool isLikedBy(String uid) => uid.isNotEmpty && likes.contains(uid);

  MomentModel copyWith({
    String? id,
    List<String>? likes,
    int? commentsCount,
    String? momentPhotoUrl,
    DateTime? createdAt,
  }) {
    return MomentModel(
      id: id ?? this.id,
      authorUserId: authorUserId,
      authorName: authorName,
      dogId: dogId,
      dogName: dogName,
      dogBreed: dogBreed,
      dogPhotoUrl: dogPhotoUrl,
      momentPhotoUrl: momentPhotoUrl ?? this.momentPhotoUrl,
      caption: caption,
      locationName: locationName,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      kind: kind,
      cityId: cityId,
      authorPhotoUrl: authorPhotoUrl,
    );
  }
}

class MomentComment {
  const MomentComment({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.likes = const [],
    this.replyToCommentId = '',
    this.replyToAuthorName = '',
  });

  static const int maxTextLength = 1000;

  final String id;
  final String authorUserId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final List<String> likes;

  /// Root comment this one answers (one level of replies).
  final String replyToCommentId;
  final String replyToAuthorName;

  bool get isReply => replyToCommentId.isNotEmpty;

  int get likeCount => likes.length;

  bool isLikedBy(String uid) => uid.isNotEmpty && likes.contains(uid);

  MomentComment copyWith({List<String>? likes}) {
    return MomentComment(
      id: id,
      authorUserId: authorUserId,
      authorName: authorName,
      text: text,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      replyToCommentId: replyToCommentId,
      replyToAuthorName: replyToAuthorName,
    );
  }
}

/// Roots in time order, each followed by its replies. A reply whose root is
/// not loaded (older page) is shown as a root.
List<({MomentComment comment, bool nested})> threadComments(
  List<MomentComment> comments,
) {
  final sorted = [...comments]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final ids = {for (final comment in sorted) comment.id};
  final replies = <String, List<MomentComment>>{};
  final roots = <MomentComment>[];
  for (final comment in sorted) {
    if (comment.isReply && ids.contains(comment.replyToCommentId)) {
      replies.putIfAbsent(comment.replyToCommentId, () => []).add(comment);
    } else {
      roots.add(comment);
    }
  }
  return [
    for (final root in roots) ...[
      (comment: root, nested: false),
      for (final reply in replies[root.id] ?? const <MomentComment>[])
        (comment: reply, nested: true),
    ],
  ];
}
