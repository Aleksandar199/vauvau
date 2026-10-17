import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feed_state.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../moments/presentation/widgets/story_widgets.dart';
import '../../domain/story.dart';
import '../create_story_sheet.dart';
import '../stories_strings.dart';
import '../story_player_screen.dart';
import '../story_providers.dart';

/// Instagram-style bar on top of Otkrij: my story first, then the active
/// stories of accounts I follow (unseen first).
class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  static const double height = 104;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bar = ref.watch(storyBarProvider);
    final seen = ref.watch(seenStoriesStoreProvider);
    final myPhoto = ref.watch(
      authStateProvider.select((auth) => auth.value?.ownerAvatarUrl ?? ''),
    );
    final mine = bar.mine;

    return SizedBox(
      height: height,
      child: ListView(
        key: const ValueKey('stories-bar'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _BarItem(
            key: const ValueKey('stories-bar-mine'),
            label: StoriesStrings.yourStory,
            onTap: mine == null
                ? () => showCreateStorySheet(context)
                : () => openStoryPlayer(context, groups: [mine]),
            onLongPress: () => showCreateStorySheet(context),
            child: StoryRing(
              url: myPhoto,
              seed: 'me',
              unseen: mine != null && mine.hasUnseen(seen),
              size: 64,
              badge: GestureDetector(
                key: const ValueKey('stories-bar-add'),
                onTap: () => showCreateStorySheet(context),
                child: Semantics(
                  button: true,
                  label: StoriesStrings.addStory,
                  child: const _AddBadge(),
                ),
              ),
            ),
          ),
          if (bar.isLoading && bar.groups.isEmpty)
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.fromLTRB(7, 8, 7, 28),
                child: SoftPlaceholder(width: 64, height: 64, borderRadius: 32),
              )
          else if (bar.groups.isEmpty)
            _EmptyHint(
              text: bar.followsAnyone
                  ? StoriesStrings.emptyNoStories
                  : StoriesStrings.emptyNoFollows,
            )
          else
            for (var i = 0; i < bar.groups.length; i++)
              _BarItem(
                key: ValueKey('stories-bar-${bar.groups[i].authorUserId}'),
                label: bar.groups[i].authorName,
                onTap: () => openStoryPlayer(
                  context,
                  groups: bar.groups,
                  initialGroup: i,
                ),
                child: _GroupRing(group: bar.groups[i], seen: seen),
              ),
        ],
      ),
    );
  }
}

class _GroupRing extends StatelessWidget {
  const _GroupRing({required this.group, required this.seen});

  final StoryAuthorGroup group;
  final Set<String> seen;

  @override
  Widget build(BuildContext context) {
    final unseen = group.hasUnseen(seen);
    final count = group.stories.length;
    return Semantics(
      label: unseen ? '${group.authorName}, nove priče' : group.authorName,
      child: StoryRing(
        url: group.authorPhotoUrl,
        seed: group.authorUserId,
        unseen: unseen,
        size: 64,
        badge: count > 1
            ? Container(
                key: const ValueKey('story-count-badge'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeep,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    super.key,
    required this.label,
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBadge extends StatelessWidget {
  const _AddBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2.5,
        ),
      ),
      child: const Icon(Icons.add, size: 16, color: Colors.white),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        key: const ValueKey('stories-bar-empty'),
        constraints: const BoxConstraints(maxWidth: 240),
        margin: const EdgeInsets.only(left: 6, bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primarySoft.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primaryDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
