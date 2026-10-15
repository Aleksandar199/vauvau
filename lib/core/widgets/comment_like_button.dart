import 'package:flutter/material.dart';

/// Compact like control for comment rows (heart + count).
class CommentLikeButton extends StatelessWidget {
  const CommentLikeButton({
    super.key,
    required this.liked,
    required this.count,
    required this.onPressed,
    this.tooltip = 'Lajk',
    this.likedColor,
    this.idleColor,
  });

  final bool liked;
  final int count;
  final VoidCallback? onPressed;
  final String tooltip;

  /// Overrides for colored backgrounds (chat bubbles), where the default red
  /// / theme colors are hard to see.
  final Color? likedColor;
  final Color? idleColor;

  @override
  Widget build(BuildContext context) {
    final color = liked
        ? likedColor ?? const Color(0xFFEF4444)
        : idleColor ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: color,
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
