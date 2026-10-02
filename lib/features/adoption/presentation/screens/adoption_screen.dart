import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/feed_state.dart';
import '../adoption_controller.dart';
import '../adoption_strings.dart';
import '../widgets/add_adoption_dog_sheet.dart';
import '../widgets/adoption_card.dart';
import 'adoption_detail_screen.dart';

class AdoptionScreen extends ConsumerWidget {
  const AdoptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogsAsync = ref.watch(adoptionControllerProvider);
    final theme = Theme.of(context);

    Future<void> addDog() async {
      final saved = await showAddAdoptionDogSheet(context);
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AdoptionStrings.published)),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AdoptionStrings.title),
        actions: [
          IconButton(
            tooltip: AdoptionStrings.addCta,
            onPressed: addDog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              AdoptionStrings.subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: dogsAsync.when(
              loading: () => FeedStateView.loadingBody(),
              error: (error, stack) => FeedStateView(
                icon: Icons.error_outline,
                title: AdoptionStrings.loadError,
                onRetry: () =>
                    ref.read(adoptionControllerProvider.notifier).reload(),
                retryLabel: AdoptionStrings.retry,
              ),
              data: (all) {
                final dogs = [
                  for (final dog in all)
                    if (!dog.isAdopted) dog,
                ];
                if (dogs.isEmpty) {
                  return const FeedStateView(
                    icon: Icons.home_outlined,
                    title: AdoptionStrings.empty,
                    subtitle: AdoptionStrings.emptySubtitle,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: dogs.length,
                  itemBuilder: (context, index) {
                    final dog = dogs[index];
                    return AdoptionCard(
                      dog: dog,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdoptionDetailScreen(dog: dog),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
