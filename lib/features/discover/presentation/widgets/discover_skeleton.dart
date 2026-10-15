import 'package:flutter/material.dart';

import '../../../../core/theme/app_cards.dart';
import '../../../../core/widgets/feed_state.dart';
import '../discover_strings.dart';

/// Placeholder with the same frame as [DiscoverGridCard]: photo + two lines.
class DiscoverSkeletonCard extends StatelessWidget {
  const DiscoverSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: AppCardTokens.borderRadius,
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SoftPlaceholder(borderRadius: 0)),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoftPlaceholder(width: 110, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                SoftPlaceholder(width: 72, height: 11, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of [DiscoverSkeletonCard]s shown until the first feed page arrives.
class DiscoverSkeletonGrid extends StatelessWidget {
  const DiscoverSkeletonGrid({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: DiscoverStrings.loadingDogs,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const DiscoverSkeletonCard(),
      ),
    );
  }
}
