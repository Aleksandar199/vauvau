import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adoption_controller.dart';
import '../adoption_strings.dart';
import '../widgets/add_adoption_dog_sheet.dart';
import '../widgets/adoption_card.dart';
import 'adoption_detail_screen.dart';

class AdoptionScreen extends ConsumerWidget {
  const AdoptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogs = ref.watch(adoptionControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AdoptionStrings.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const AddAdoptionDogScreen(),
            ),
          ).then((saved) {
            if (saved == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AdoptionStrings.published)),
              );
            }
          });
        },
        backgroundColor: const Color(0xFF2A2D3E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AdoptionStrings.addCta),
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
            child: dogs.isEmpty
                ? const Center(child: Text(AdoptionStrings.empty))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                  ),
          ),
        ],
      ),
    );
  }
}
