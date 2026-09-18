import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../discover_controller.dart';
import '../discover_strings.dart';

class DiscoverEmptyState extends ConsumerWidget {
  const DiscoverEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets_outlined, size: 88, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              DiscoverStrings.emptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              DiscoverStrings.emptySubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  ref.read(discoverControllerProvider.notifier).resetFilters(),
              child: const Text(DiscoverStrings.resetFilters),
            ),
          ],
        ),
      ),
    );
  }
}
