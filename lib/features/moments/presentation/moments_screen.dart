import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_moment_sheet.dart';
import 'moments_controller.dart';
import 'moments_strings.dart';
import 'widgets/moment_card.dart';

class MomentsScreen extends ConsumerWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(momentsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(MomentsStrings.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateMomentSheet(context),
        icon: const Icon(Icons.add),
        label: const Text(MomentsStrings.share),
      ),
      body: moments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _MomentsPlaceholder(
          message: MomentsStrings.loadError,
          onRetry: () => ref.read(momentsControllerProvider.notifier).reload(),
        ),
        data: (items) => items.isEmpty
            ? const _MomentsPlaceholder(message: MomentsStrings.empty)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    MomentCard(moment: items[index]),
              ),
      ),
    );
  }
}

class _MomentsPlaceholder extends StatelessWidget {
  const _MomentsPlaceholder({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📸', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(MomentsStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
