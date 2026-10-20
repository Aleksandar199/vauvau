import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../stories/presentation/create_story_sheet.dart';
import '../../stories/presentation/stories_strings.dart';
import '../../stories/presentation/widgets/stories_bar.dart';
import '../domain/moments_repository.dart';
import 'create_moment_sheet.dart';
import 'moments_screen.dart';
import 'moments_strings.dart';

/// Početna (Instagram-style home): stories bar on top, then the Moments
/// feed with Za tebe / Pratim / U blizini. The stories bar scrolls away
/// with the feed; the tab bar stays pinned.
class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: const ValueKey('home-feed'),
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'home-new-post',
          tooltip: MomentsStrings.newPost,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () => showCreateMomentSheet(context),
          child: const Icon(Icons.add_a_photo_outlined),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 6),
                child: StoriesBar(),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeader(
                color: theme.scaffoldBackgroundColor,
                tabBar: TabBar(
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: MomentsStrings.tabForYou),
                    Tab(text: MomentsStrings.tabFollowing),
                    Tab(text: MomentsStrings.tabNearby),
                  ],
                ),
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              MomentFeedView(feed: MomentFeed.forYou),
              MomentFeedView(feed: MomentFeed.following),
              MomentFeedView(feed: MomentFeed.nearby),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarHeader extends SliverPersistentHeaderDelegate {
  _TabBarHeader({required this.tabBar, required this.color});

  final TabBar tabBar;
  final Color color;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(color: color, child: tabBar);

  @override
  bool shouldRebuild(_TabBarHeader oldDelegate) =>
      oldDelegate.tabBar != tabBar || oldDelegate.color != color;
}

/// Početna top bar: + (new story) · VauVau · ♥ (activity: follows, likes,
/// replies – the notifications list, with the unread badge).
class HomeFeedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeFeedAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationUnreadCountProvider);
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        key: const ValueKey('home-add-story'),
        tooltip: StoriesStrings.addStory,
        icon: const Icon(Icons.add, size: 28),
        onPressed: () => showCreateStorySheet(context),
      ),
      title: Text(
        AppStrings.appName,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        IconButton(
          key: const ValueKey('home-activity'),
          tooltip: MomentsStrings.activity,
          onPressed: () => showNotificationsSheet(context),
          icon: Badge(
            isLabelVisible: unread > 0,
            backgroundColor: const Color(0xFFE11D48),
            label: Text('$unread'),
            child: const Icon(Icons.favorite_border_rounded),
          ),
        ),
      ],
    );
  }
}
