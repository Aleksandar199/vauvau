/// Who may view a story. Stored as [key] in `stories.audience`.
enum StoryAudience {
  /// "Svi korisnici": every signed-in user the author has not blocked.
  everyone('all'),

  /// "Moji pratioci": users who follow the author.
  followers('followers'),

  /// "Osobe koje ja pratim": users the author follows.
  following('following');

  const StoryAudience(this.key);

  final String key;

  static StoryAudience fromKey(String? key) {
    for (final value in values) {
      if (value.key == key) {
        return value;
      }
    }
    // Unknown / missing → the most restrictive reading is not possible
    // without data, so treat as followers-only rather than public.
    return StoryAudience.followers;
  }
}

enum StoryMediaType {
  image('image');

  const StoryMediaType(this.key);

  final String key;
}

class Story {
  const Story({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.mediaPath,
    required this.audience,
    required this.createdAt,
    required this.expiresAt,
    this.authorPhotoUrl = '',
    this.dogId = '',
    this.dogName = '',
    this.dogPhotoUrl = '',
    this.mediaType = StoryMediaType.image,
    this.caption = '',
  });

  static const Duration lifetime = Duration(hours: 24);
  static const int maxCaptionLength = 500;

  /// `stories/{authorUid}/{storyId}/media` — the only accepted media path.
  static String mediaPathFor(String authorUserId, String storyId) =>
      'stories/$authorUserId/$storyId/media';

  final String id;
  final String authorUserId;
  final String authorName;
  final String authorPhotoUrl;
  final String dogId;
  final String dogName;
  final String dogPhotoUrl;
  final StoryMediaType mediaType;
  final String mediaPath;
  final String caption;
  final StoryAudience audience;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isActive(DateTime now) => expiresAt.isAfter(now);

  // Stories are immutable after publishing: the id identifies the content.
  @override
  bool operator ==(Object other) =>
      other is Story && other.id == id && other.mediaPath == mediaPath;

  @override
  int get hashCode => Object.hash(id, mediaPath);
}

/// One account's active stories in the bar / viewer, oldest first.
class StoryAuthorGroup {
  StoryAuthorGroup({
    required this.authorUserId,
    required this.authorName,
    required this.authorPhotoUrl,
    required List<Story> stories,
  }) : stories = [...stories]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  factory StoryAuthorGroup.of(List<Story> stories) {
    final latest = stories.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
    return StoryAuthorGroup(
      authorUserId: latest.authorUserId,
      authorName: latest.authorName,
      authorPhotoUrl: latest.authorPhotoUrl,
      stories: stories,
    );
  }

  final String authorUserId;
  final String authorName;
  final String authorPhotoUrl;
  final List<Story> stories;

  DateTime get latest => stories.last.createdAt;

  bool hasUnseen(Set<String> seen) =>
      stories.any((story) => !seen.contains(story.id));
}

/// A viewer of my story (author only), with whether they liked it.
class StoryViewer {
  const StoryViewer({
    required this.userId,
    required this.viewedAt,
    this.liked = false,
  });

  final String userId;
  final DateTime viewedAt;
  final bool liked;
}

/// Draft before publishing (preview screen).
class StoryDraft {
  const StoryDraft({
    required this.audience,
    this.caption = '',
    this.dogId = '',
    this.dogName = '',
    this.dogPhotoUrl = '',
  });

  final StoryAudience audience;
  final String caption;
  final String dogId;
  final String dogName;
  final String dogPhotoUrl;
}

/// Groups active stories by author: [me] first, then unseen, then newest.
List<StoryAuthorGroup> groupStoriesByAuthor(
  Iterable<Story> stories, {
  required String me,
  required Set<String> seen,
  required DateTime now,
  Set<String> blocked = const {},
}) {
  final byAuthor = <String, List<Story>>{};
  final ids = <String>{};
  for (final story in stories) {
    if (!story.isActive(now) ||
        blocked.contains(story.authorUserId) ||
        !ids.add(story.id)) {
      continue;
    }
    byAuthor.putIfAbsent(story.authorUserId, () => []).add(story);
  }
  final groups = [
    for (final items in byAuthor.values) StoryAuthorGroup.of(items),
  ];
  groups.sort((a, b) {
    final aMine = a.authorUserId == me;
    final bMine = b.authorUserId == me;
    if (aMine != bMine) {
      return aMine ? -1 : 1;
    }
    final aUnseen = a.hasUnseen(seen);
    final bUnseen = b.hasUnseen(seen);
    if (aUnseen != bUnseen) {
      return aUnseen ? -1 : 1;
    }
    return b.latest.compareTo(a.latest);
  });
  return groups;
}
