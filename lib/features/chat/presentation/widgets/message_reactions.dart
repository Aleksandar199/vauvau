import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/message_reactions.dart';

/// Emoji row at the top of the long-press menu (WhatsApp style). Tapping the
/// emoji I already chose removes my reaction ([onSelected] gets null).
class ReactionPickerRow extends StatelessWidget {
  const ReactionPickerRow({
    super.key,
    required this.onSelected,
    this.current,
  });

  final String? current;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final emoji in messageReactionEmojis)
            InkResponse(
              key: ValueKey('reaction-$emoji'),
              radius: 28,
              onTap: () => onSelected(emoji == current ? null : emoji),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: emoji == current
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small pill under a bubble with the chosen emoji and their count.
///
/// Drawn on the surface color with a border and shadow so it is visible on
/// both the orange (mine) and the light grey (peer) bubbles.
class ReactionBadge extends StatelessWidget {
  const ReactionBadge({
    super.key,
    required this.likes,
    required this.currentUserId,
    this.onTap,
  });

  final List<String> likes;
  final String currentUserId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final summary = MessageReactions.summary(likes);
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final total = summary.fold<int>(0, (sum, item) => sum + item.count);
    final mine = MessageReactions.reactionOf(likes, currentUserId) != null;
    return GestureDetector(
      key: const ValueKey('message-reactions'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: mine
                ? AppColors.primary.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in summary.take(3))
              Text(item.emoji, style: const TextStyle(fontSize: 14)),
            if (total > 1) ...[
              const SizedBox(width: 3),
              Text(
                '$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// [bubble] with its [ReactionBadge] tucked under the bottom edge.
class BubbleWithReactions extends StatelessWidget {
  const BubbleWithReactions({
    super.key,
    required this.bubble,
    required this.likes,
    required this.currentUserId,
    required this.isMine,
    this.onReactionsTap,
  });

  final Widget bubble;
  final List<String> likes;
  final String currentUserId;
  final bool isMine;
  final VoidCallback? onReactionsTap;

  @override
  Widget build(BuildContext context) {
    if (likes.isEmpty) {
      return bubble;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        Transform.translate(
          offset: const Offset(0, -6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ReactionBadge(
              likes: likes,
              currentUserId: currentUserId,
              onTap: onReactionsTap,
            ),
          ),
        ),
      ],
    );
  }
}
