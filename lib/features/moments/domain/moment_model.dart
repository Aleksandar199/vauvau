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
  });

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

  static const Duration storyLifetime = Duration(hours: 24);

  int get likeCount => likes.length;

  bool isActiveStory(DateTime now) => now.difference(createdAt) < storyLifetime;

  bool isLikedBy(String uid) => uid.isNotEmpty && likes.contains(uid);

  MomentModel copyWith({List<String>? likes, int? commentsCount}) {
    return MomentModel(
      id: id,
      authorUserId: authorUserId,
      authorName: authorName,
      dogId: dogId,
      dogName: dogName,
      dogBreed: dogBreed,
      dogPhotoUrl: dogPhotoUrl,
      momentPhotoUrl: momentPhotoUrl,
      caption: caption,
      locationName: locationName,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
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
  });

  final String id;
  final String authorUserId;
  final String authorName;
  final String text;
  final DateTime createdAt;
}
