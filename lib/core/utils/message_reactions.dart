/// Emoji a chat message can be reacted with (long press, WhatsApp style).
///
/// Keep in sync with `reactionEntries()` in firestore.rules.
const List<String> messageReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

const String _heart = '❤️';

/// One emoji reaction and how many people chose it.
typedef ReactionCount = ({String emoji, int count});

/// Reactions live in a message's `likes` list, the only field the deployed
/// rules let participants change. A bare uid is a ❤️ (older app versions
/// only wrote that); any other emoji is stored as `uid:emoji`. Each user has
/// at most one reaction.
abstract final class MessageReactions {
  static String _uidOf(String entry) {
    final i = entry.indexOf(':');
    return i < 0 ? entry : entry.substring(0, i);
  }

  static String _emojiOf(String entry) {
    final i = entry.indexOf(':');
    if (i < 0) {
      return _heart;
    }
    final emoji = entry.substring(i + 1);
    return messageReactionEmojis.contains(emoji) ? emoji : _heart;
  }

  /// The emoji [uid] reacted with, or null.
  static String? reactionOf(List<String> likes, String uid) {
    if (uid.isEmpty) {
      return null;
    }
    for (final entry in likes) {
      if (_uidOf(entry) == uid) {
        return _emojiOf(entry);
      }
    }
    return null;
  }

  /// Reactions grouped by emoji, most chosen first (palette order on ties).
  static List<ReactionCount> summary(List<String> likes) {
    final counts = <String, int>{};
    final seen = <String>{};
    for (final entry in likes) {
      // One reaction per user even if old data holds duplicates.
      if (!seen.add(_uidOf(entry))) {
        continue;
      }
      final emoji = _emojiOf(entry);
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    final result = [
      for (final emoji in messageReactionEmojis)
        if ((counts[emoji] ?? 0) > 0) (emoji: emoji, count: counts[emoji]!),
    ];
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  /// [likes] with [uid]'s reaction replaced by [emoji] (null removes it).
  static List<String> apply(List<String> likes, String uid, String? emoji) {
    final next = [
      for (final entry in likes)
        if (_uidOf(entry) != uid) entry,
    ];
    if (uid.isEmpty || emoji == null) {
      return next;
    }
    if (!messageReactionEmojis.contains(emoji)) {
      throw ArgumentError.value(emoji, 'emoji', 'Nije podržana reakcija');
    }
    next.add(emoji == _heart ? uid : '$uid:$emoji');
    return next;
  }
}
