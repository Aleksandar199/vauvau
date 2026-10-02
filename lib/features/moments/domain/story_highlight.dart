/// A named collection of stories pinned to a dog's profile. Highlights only
/// reference moment ids, so a story stays visible here after its 24h expire.
class StoryHighlight {
  const StoryHighlight({
    required this.id,
    required this.ownerId,
    required this.dogId,
    required this.title,
    required this.momentIds,
    this.coverMomentId = '',
    this.order = 0,
    required this.createdAt,
  });

  static const int maxTitleLength = 20;

  final String id;
  final String ownerId;
  final String dogId;
  final String title;
  final List<String> momentIds;
  final String coverMomentId;
  final int order;
  final DateTime createdAt;

  StoryHighlight copyWith({
    String? title,
    List<String>? momentIds,
    String? coverMomentId,
    int? order,
  }) {
    return StoryHighlight(
      id: id,
      ownerId: ownerId,
      dogId: dogId,
      title: title ?? this.title,
      momentIds: momentIds ?? this.momentIds,
      coverMomentId: coverMomentId ?? this.coverMomentId,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
