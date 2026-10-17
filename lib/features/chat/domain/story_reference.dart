/// The story a chat message replies to. Only ids and a short caption are
/// stored in the message: the story media stays behind the story's audience
/// rules and is loaded (or not) when the bubble is shown.
class StoryReference {
  const StoryReference({
    required this.storyId,
    required this.authorUserId,
    this.caption = '',
  });

  static const int maxCaptionLength = 120;

  final String storyId;
  final String authorUserId;
  final String caption;

  bool get isValid => storyId.isNotEmpty && authorUserId.isNotEmpty;

  String get clippedCaption {
    final text = caption.trim();
    if (text.length <= maxCaptionLength) {
      return text;
    }
    return '${text.substring(0, maxCaptionLength).trimRight()}…';
  }

  Map<String, String> toFields() => {
        'storyId': storyId,
        'storyAuthorId': authorUserId,
        'storyCaption': clippedCaption,
      };
}
