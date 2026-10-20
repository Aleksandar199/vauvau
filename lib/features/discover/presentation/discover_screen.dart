import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moderation/domain/content_report.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/discover_profile.dart';
import 'discover_controller.dart';
import 'discover_strings.dart';
import 'widgets/directory_cards.dart';
import 'widgets/discover_empty_state.dart';
import 'widgets/discover_filter_chip.dart';
import 'widgets/discover_skeleton.dart';
import 'widgets/swipe_dog_card.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  static List<(DiscoverCategory, String)> get _chips => [
        (DiscoverCategory.all, DiscoverStrings.chipAll),
        (DiscoverCategory.walking, DiscoverStrings.chipWalking),
        (DiscoverCategory.small, DiscoverStrings.chipSmall),
        (DiscoverCategory.medium, DiscoverStrings.chipMedium),
        (DiscoverCategory.large, DiscoverStrings.chipLarge),
      ];

  var _loadMoreScheduled = false;

  /// Asks for the next page after this frame (never while building).
  void _scheduleLoadMore() {
    if (_loadMoreScheduled) {
      return;
    }
    final feed = ref.read(discoverFeedControllerProvider);
    if (feed.isLoading || feed.isLoadingMore || !feed.hasMore) {
      return;
    }
    _loadMoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoreScheduled = false;
      if (mounted) {
        ref.read(discoverFeedControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverControllerProvider);
    final filters = ref.watch(matchingFiltersProvider);
    final controller = ref.read(discoverControllerProvider.notifier);
    final feed = ref.watch(discoverFeedControllerProvider);
    final dogs = state.visible;
    final theme = Theme.of(context);
    // Filters may hide a whole page: keep fetching before saying "no dogs".
    final waiting = feed.isLoading || feed.isLoadingMore || feed.hasMore;
    if (dogs.isEmpty && feed.hasMore) {
      _scheduleLoadMore();
    }
    final footerCount = feed.isLoadingMore ? 2 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DiscoverStrings.nearbyTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DiscoverStrings.locationBadge(
                      state.myDog.cityName,
                      filters.radiusKm,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _chips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _chips[index];
              return DiscoverFilterChip(
                label: item.$2,
                selected: state.category == item.$1,
                leading: item.$1 == DiscoverCategory.walking
                    ? const WalkStatusDot()
                    : null,
                onTap: () => controller.setCategory(item.$1),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: dogs.isNotEmpty
                ? GridView.builder(
                    key: const ValueKey('discover-grid'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: dogs.length + footerCount,
                    itemBuilder: (context, index) {
                      if (index >= dogs.length) {
                        return const DiscoverSkeletonCard();
                      }
                      // Prefetch while the last few cards come into view.
                      if (index >=
                          dogs.length - DiscoverFeedController.prefetchThreshold) {
                        _scheduleLoadMore();
                      }
                      final dog = dogs[index];
                      return DiscoverGridCard(
                        profile: dog,
                        isMine: dog.id == state.myDog.id ||
                            (dog.ownerId.isNotEmpty &&
                                dog.ownerId == state.myDog.ownerId),
                        onTap: () => _openDetails(context, ref, dog),
                        onLongPress: () => showContentReportSheet(
                          context: context,
                          ref: ref,
                          targetType: ReportContentType.dog,
                          targetId: dog.id,
                          reportedUserId: dog.ownerId,
                        ),
                      );
                    },
                  )
                : waiting
                    ? const DiscoverSkeletonGrid(
                        key: ValueKey('discover-skeleton'),
                      )
                    : const DiscoverEmptyState(
                        key: ValueKey('discover-empty'),
                      ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    WidgetRef ref,
    DiscoverProfile profile,
  ) {
    return showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DogDetailSheet(profile: profile),
    );
  }
}
