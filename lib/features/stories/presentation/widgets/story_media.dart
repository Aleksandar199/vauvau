import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/story.dart';
import '../stories_strings.dart';
import '../story_providers.dart';

/// Story photo loaded through the Storage SDK (never a public URL), so the
/// audience / block / expiry rules are checked on every load.
class StoryMediaImage extends ConsumerWidget {
  const StoryMediaImage({
    super.key,
    required this.story,
    this.fit = BoxFit.cover,
    this.onLoaded,
    this.compact = false,
  });

  final Story story;
  final BoxFit fit;
  final VoidCallback? onLoaded;

  /// Thumbnail mode (chat bubble): icon only on error, no text.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(storyMediaProvider(story));
    return media.when(
      data: (bytes) {
        if (onLoaded != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded!());
        }
        return Image.memory(
          bytes,
          fit: fit,
          gaplessPlayback: true,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, _, _) => _Unavailable(compact: compact),
        );
      },
      loading: () => Center(
        child: SizedBox(
          width: compact ? 16 : 28,
          height: compact ? 16 : 28,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white70,
          ),
        ),
      ),
      error: (_, _) => _Unavailable(compact: compact),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Center(
        child: Icon(Icons.auto_stories_outlined, color: Colors.white70),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hide_image_outlined, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            StoriesStrings.unavailable,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
