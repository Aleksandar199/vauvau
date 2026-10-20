import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feed_state.dart';
import '../../location/presentation/home_city_provider.dart';
import '../domain/moments_repository.dart';
import 'create_moment_sheet.dart';
import 'moment_feed_controller.dart';
import 'moments_strings.dart';
import 'widgets/moment_post_card.dart';

/// VauVau Moments: the permanent community feed (posts stay until the author
/// deletes them or moderation removes them). 24h stories are a separate
/// feature – the stories bar on Početna (`home_feed_screen.dart`).
class MomentsScreen extends ConsumerWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(MomentsStrings.title),
          actions: [
            IconButton(
              tooltip: MomentsStrings.newPost,
              onPressed: () => showCreateMomentSheet(context),
              icon: const Icon(Icons.add_box_outlined),
            ),
          ],
          bottom: TabBar(
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: MomentsStrings.tabForYou),
              Tab(text: MomentsStrings.tabFollowing),
              Tab(text: MomentsStrings.tabNearby),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'moments-new-post',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () => showCreateMomentSheet(context),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(MomentsStrings.newPost),
        ),
        body: const TabBarView(
          children: [
            MomentFeedView(feed: MomentFeed.forYou),
            MomentFeedView(feed: MomentFeed.following),
            MomentFeedView(feed: MomentFeed.nearby),
          ],
        ),
      ),
    );
  }
}

/// One tab: pull to refresh, infinite scroll, loading / empty / offline /
/// error states.
class MomentFeedView extends ConsumerStatefulWidget {
  const MomentFeedView({super.key, required this.feed});

  final MomentFeed feed;

  @override
  ConsumerState<MomentFeedView> createState() => _MomentFeedViewState();
}

class _MomentFeedViewState extends ConsumerState<MomentFeedView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  MomentFeedController get _controller =>
      ref.read(momentFeedProvider(widget.feed).notifier);

  /// No own ScrollController: inside Početna the list shares the
  /// NestedScrollView's controller (stories bar scrolls away with the feed).
  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 900) {
      _controller.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(visibleMomentFeedProvider(widget.feed));

    // Everything loaded so far was hidden (blocked authors): fetch on.
    if (!state.isLoading &&
        state.items.isEmpty &&
        state.hasMore &&
        !state.isLoadingMore &&
        !state.loadMoreFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.loadMore();
        }
      });
    }

    if (state.isLoading && state.items.isEmpty) {
      return const _FeedSkeleton();
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: _emptyOrError(state),
              ),
            ],
          ),
        ),
      );
    }

    final cityName = widget.feed == MomentFeed.nearby
        ? ref.watch(homeCityProvider.select((city) => city?.name ?? ''))
        : '';
    final header = <Widget>[
      if (state.isOffline) const _OfflineBanner(),
      if (cityName.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
          child: Text(
            MomentsStrings.nearbyHeader(cityName),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
    ];

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        itemCount: header.length + state.items.length + 1,
        itemBuilder: (context, index) {
          if (index < header.length) {
            return header[index];
          }
          final i = index - header.length;
          if (i < state.items.length) {
            return MomentPostCard(moment: state.items[i]);
          }
          return _FeedFooter(
            state: state,
            onRetry: _controller.loadMore,
          );
        },
        ),
      ),
    );
  }

  Widget _emptyOrError(MomentFeedState state) {
    if (state.error != null) {
      return FeedStateView(
        icon: state.isOffline ? Icons.wifi_off : Icons.error_outline,
        title: state.isOffline
            ? MomentsStrings.offline
            : MomentsStrings.feedError,
        subtitle: MomentsStrings.feedErrorSubtitle,
        retryLabel: MomentsStrings.retry,
        onRetry: _controller.refresh,
      );
    }
    switch (widget.feed) {
      case MomentFeed.forYou:
        return FeedStateView(
          icon: Icons.photo_camera_outlined,
          title: MomentsStrings.emptyForYou,
          subtitle: MomentsStrings.emptyForYouSubtitle,
        );
      case MomentFeed.following:
        final none = state.blocker == MomentFeedBlocker.noFollowing;
        return FeedStateView(
          icon: Icons.people_outline,
          title: none
              ? MomentsStrings.emptyFollowingNone
              : MomentsStrings.emptyFollowing,
          subtitle: none
              ? MomentsStrings.emptyFollowingNoneSubtitle
              : MomentsStrings.emptyFollowingSubtitle,
        );
      case MomentFeed.nearby:
        if (state.blocker == MomentFeedBlocker.noCity) {
          return FeedStateView(
            icon: Icons.location_city_outlined,
            title: MomentsStrings.emptyNearbyNoCity,
            subtitle: MomentsStrings.emptyNearbyNoCitySubtitle,
          );
        }
        final city = ref.read(homeCityProvider)?.name ?? '';
        return FeedStateView(
          icon: Icons.place_outlined,
          title: MomentsStrings.emptyNearby(city),
          subtitle: MomentsStrings.emptyNearbySubtitle,
        );
    }
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('moments-offline'),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: AppColors.primaryDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              MomentsStrings.offline,
              style: const TextStyle(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({required this.state, required this.onRetry});

  final MomentFeedState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.isLoadingMore || (state.hasMore && !state.loadMoreFailed)) {
      child = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (state.loadMoreFailed) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(MomentsStrings.loadMoreError),
          TextButton(onPressed: onRetry, child: Text(MomentsStrings.retry)),
        ],
      );
    } else {
      child = Text(
        MomentsStrings.endOfFeed,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(child: child),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: MomentsStrings.feedLoading,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        children: [
          for (var i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      SoftPlaceholder(width: 40, height: 40, borderRadius: 20),
                      SizedBox(width: 10),
                      SoftPlaceholder(width: 140, height: 14),
                    ],
                  ),
                  SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: SoftPlaceholder(borderRadius: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
