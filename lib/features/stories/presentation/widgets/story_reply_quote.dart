import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../stories_strings.dart';
import '../story_player_screen.dart';
import '../story_providers.dart';
import 'story_media.dart';

/// Story context on top of a chat message that replied to a story.
/// The thumbnail is loaded through the story's own rules: it shows only
/// while the story is active and visible to whoever looks at the chat.
class StoryReplyQuote extends ConsumerWidget {
  const StoryReplyQuote({
    super.key,
    required this.storyId,
    required this.caption,
    required this.isMine,
  });

  final String storyId;
  final String caption;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(storyByIdProvider(storyId)).value;
    final bar = isMine ? Colors.white.withValues(alpha: 0.85) : AppColors.primary;
    final bg = isMine
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.primary.withValues(alpha: 0.1);
    final titleColor = isMine ? Colors.white : AppColors.primaryDeep;
    final bodyColor =
        isMine ? Colors.white.withValues(alpha: 0.9) : AppColors.ink;
    return GestureDetector(
      key: const ValueKey('story-reply-quote'),
      onTap: () => openStoryById(context, ref, storyId),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: bar, width: 3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 36,
                height: 52,
                child: ColoredBox(
                  color: Colors.black26,
                  child: story == null
                      ? const Icon(
                          Icons.auto_stories_outlined,
                          color: Colors.white70,
                          size: 20,
                        )
                      : StoryMediaImage(story: story, compact: true),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    StoriesStrings.replyToStory,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  if (caption.trim().isNotEmpty)
                    Text(
                      caption.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: bodyColor, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
