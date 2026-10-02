import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/widgets/feed_state.dart';
import 'create_moment_sheet.dart';
import 'moments_controller.dart';
import 'moments_strings.dart';
import 'stories_controller.dart';
import 'story_viewer.dart';
import 'widgets/story_widgets.dart';

class MomentsScreen extends ConsumerWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(visibleMomentsProvider);
    // Keep Scaffold stable: do NOT watch seenStories here — that rebuilds the
    // whole scaffold (and used to blow up Flutter web hit-testing the FAB)
    // every time a story is marked seen under an open viewer.
    void addStory() => showCreateMomentSheet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(MomentsStrings.title),
        actions: [
          IconButton(
            tooltip: MomentsStrings.share,
            onPressed: addStory,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: moments.when(
        loading: () => FeedStateView.loadingBody(),
        error: (error, stack) => FeedStateView(
          icon: Icons.error_outline,
          title: MomentsStrings.loadError,
          onRetry: () => ref.read(momentsControllerProvider.notifier).reload(),
          retryLabel: MomentsStrings.retry,
        ),
        data: (_) => _MomentsBody(onAddStory: addStory),
      ),
    );
  }
}

class _MomentsBody extends ConsumerWidget {
  const _MomentsBody({required this.onAddStory});

  final VoidCallback onAddStory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(activeStoryGroupsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StoriesRail(onAddStory: onAddStory),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    MomentsStrings.storiesHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (groups.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: FeedStateView(
              icon: Icons.photo_camera_outlined,
              title: MomentsStrings.noStories,
              subtitle: MomentsStrings.noStoriesSubtitle,
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                MomentsStrings.activeStories,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.62,
              ),
              itemCount: groups.length,
              itemBuilder: (context, i) => _StoryTile(
                group: groups[i],
                onTap: () => openStoryViewer(
                  context,
                  groups: groups,
                  initialGroup: i,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StoryTile extends ConsumerWidget {
  const _StoryTile({required this.group, required this.onTap});

  final StoryGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unseen = hasUnseen(group, ref.watch(seenStoriesProvider));
    final latest = group.moments.last;
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DogImage(url: group.coverUrl, seed: latest.id),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.3, 0.6, 1],
                  colors: [
                    Color(0x66000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xB3000000),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: StoryRing(
                url: group.dogPhotoUrl,
                seed: group.dogId,
                unseen: unseen,
                size: 42,
              ),
            ),
            if (group.moments.length > 1)
              Positioned(
                right: 8,
                top: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    MomentsStrings.storyCount(group.moments.length),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.dogName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (latest.caption.trim().isNotEmpty)
                    Text(
                      latest.caption.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    MomentsStrings.timeAgo(latest.createdAt, DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
