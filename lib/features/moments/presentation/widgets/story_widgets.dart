import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/story_highlight.dart';
import '../highlight_sheets.dart';
import '../moments_controller.dart';
import '../moments_strings.dart';
import '../pointer_safe.dart';
import '../stories_controller.dart';
import '../story_viewer.dart';

const _storyGradient = SweepGradient(
  colors: [
    Color(0xFFF59E0B),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFFA855F7),
    Color(0xFFF59E0B),
  ],
);

/// Circular avatar with the Instagram-style ring: gradient while there is
/// something unseen, grey once everything was watched.
class StoryRing extends StatelessWidget {
  const StoryRing({
    super.key,
    required this.url,
    required this.seed,
    this.unseen = true,
    this.size = 68,
    this.badge,
  });

  final String url;
  final String seed;
  final bool unseen;
  final double size;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final ringWidth = unseen ? 3.0 : 1.5;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(ringWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unseen ? _storyGradient : null,
              color: unseen ? null : AppColors.lightOutline,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ClipOval(
                child: url.isEmpty
                    ? const ColoredBox(
                        color: AppColors.primarySoft,
                        child: Center(
                          child: Icon(
                            Icons.auto_stories_outlined,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      )
                    : DogImage(url: url, seed: seed),
              ),
            ),
          ),
          if (badge != null) Positioned(right: -2, bottom: -2, child: badge!),
        ],
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

class _CircleItem extends StatelessWidget {
  const _CircleItem({
    super.key,
    required this.label,
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  static const double width = 78;

  final String label;
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal rail on top of the Moments screen.
class StoriesRail extends ConsumerWidget {
  const StoriesRail({super.key, required this.onAddStory});

  final VoidCallback onAddStory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(activeStoryGroupsProvider);
    final seen = ref.watch(seenStoriesProvider);
    final me = ref.watch(momentsMemberIdProvider);
    final mine = me.isEmpty
        ? const <StoryGroup>[]
        : [
            for (final group in groups)
              if (group.authorUserId == me) group,
          ];
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          if (mine.isEmpty)
            _CircleItem(
              label: MomentsStrings.yourStory,
              onTap: onAddStory,
              child: const StoryRing(
                url: '',
                seed: '',
                unseen: false,
                badge: _AddBadge(),
              ),
            ),
          for (var i = 0; i < groups.length; i++)
            _CircleItem(
              key: ValueKey('story-${groups[i].dogId}'),
              label: groups[i].authorUserId == me
                  ? MomentsStrings.yourStory
                  : groups[i].dogName,
              onTap: () =>
                  openStoryViewer(context, groups: groups, initialGroup: i),
              onLongPress: groups[i].authorUserId == me ? onAddStory : null,
              child: StoryRing(
                url: groups[i].dogPhotoUrl,
                seed: groups[i].dogId,
                unseen: hasUnseen(groups[i], seen),
                badge: groups[i] == (mine.isEmpty ? null : mine.first)
                    ? const _AddBadge()
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Highlights of one dog. [editable] adds "Novo", long-press edit and
/// reordering for the owner.
class StoryHighlightsRow extends ConsumerWidget {
  const StoryHighlightsRow({
    super.key,
    required this.dogId,
    this.editable = false,
    this.showHeader = true,
  });

  final String dogId;
  final bool editable;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlights =
        ref.watch(dogHighlightsProvider(dogId)).asData?.value ??
        const <StoryHighlight>[];
    final all = ref.watch(momentsControllerProvider).asData?.value ?? const [];
    final entries = <({StoryHighlight highlight, StoryGroup? group})>[
      for (final highlight in highlights)
        (highlight: highlight, group: resolveHighlight(highlight, all)),
    ].where((entry) => editable || entry.group != null).toList();
    final playable = [
      for (final entry in entries)
        if (entry.group != null) entry.group!,
    ];

    if (!editable && entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader)
          Row(
            children: [
              Expanded(
                child: Text(
                  MomentsStrings.highlights,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (editable && entries.length > 1)
                TextButton.icon(
                  onPressed: () => showArrangeHighlightsSheet(context, dogId),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text(MomentsStrings.arrangeHighlights),
                ),
            ],
          ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final entry in entries)
                _CircleItem(
                  key: ValueKey('highlight-${entry.highlight.id}'),
                  label: entry.highlight.title,
                  onTap: () {
                    final group = entry.group;
                    if (group != null) {
                      openStoryViewer(
                        context,
                        groups: playable,
                        initialGroup: playable.indexOf(group),
                      );
                    } else if (editable) {
                      showHighlightEditor(
                        context,
                        dogId: dogId,
                        existing: entry.highlight,
                      );
                    }
                  },
                  onLongPress: editable
                      ? () => _showOptions(context, ref, entry.highlight)
                      : null,
                  child: StoryRing(
                    url: highlightCoverUrl(entry.highlight, all),
                    seed: entry.highlight.id,
                    unseen: false,
                    size: 64,
                  ),
                ),
              if (editable)
                _CircleItem(
                  label: MomentsStrings.newHighlight,
                  onTap: () => showHighlightEditor(context, dogId: dogId),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lightOutline,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.add, size: 30),
                  ),
                ),
            ],
          ),
        ),
        if (editable && entries.isEmpty)
          Text(
            MomentsStrings.storiesHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Future<void> _showOptions(
    BuildContext context,
    WidgetRef ref,
    StoryHighlight highlight,
  ) {
    return afterPointerSettles(() async {
      if (!context.mounted) {
        return;
      }
      final action = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(highlight.title),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop('edit'),
              child: const Text(MomentsStrings.editHighlightTitle),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop('delete'),
              child: const Text(
                MomentsStrings.highlightDelete,
                style: TextStyle(color: Color(0xFFB91C1C)),
              ),
            ),
          ],
        ),
      );
      if (!context.mounted || action == null) {
        return;
      }
      if (action == 'edit') {
        await showHighlightEditor(context, dogId: dogId, existing: highlight);
      } else if (action == 'delete') {
        await confirmDeleteHighlight(context, ref, highlight);
      }
    });
  }
}

/// "Priče" block of another dog's profile: the live story (if any) and the
/// owner's highlights, read only.
class DogStoriesSection extends ConsumerWidget {
  const DogStoriesSection({super.key, required this.dogId});

  final String dogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(activeStoryGroupsProvider);
    final seen = ref.watch(seenStoriesProvider);
    final active = activeStoryForDog(groups, dogId);
    final highlights =
        ref.watch(dogHighlightsProvider(dogId)).asData?.value ??
        const <StoryHighlight>[];
    final all = ref.watch(momentsControllerProvider).asData?.value ?? const [];
    final resolved = [
      for (final highlight in highlights)
        if (resolveHighlight(highlight, all) case final group?)
          (group: group, cover: highlightCoverUrl(highlight, all)),
    ];
    final playable = [for (final entry in resolved) entry.group];

    if (active == null && playable.isEmpty) {
      return Text(
        MomentsStrings.highlightsEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (active != null)
            _CircleItem(
              label: MomentsStrings.story,
              onTap: () => openStoryViewer(context, groups: [active]),
              child: StoryRing(
                url: active.coverUrl,
                seed: active.dogId,
                unseen: hasUnseen(active, seen),
                size: 64,
              ),
            ),
          for (var i = 0; i < playable.length; i++)
            _CircleItem(
              label: playable[i].title ?? '',
              onTap: () =>
                  openStoryViewer(context, groups: playable, initialGroup: i),
              child: StoryRing(
                url: resolved[i].cover,
                seed: '${playable[i].dogId}-$i',
                unseen: false,
                size: 64,
              ),
            ),
        ],
      ),
    );
  }
}
