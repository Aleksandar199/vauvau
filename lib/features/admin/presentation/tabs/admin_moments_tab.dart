import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/dog_image.dart';
import '../../../moments/domain/moment_model.dart';
import '../../../moments/presentation/moments_controller.dart';
import '../../../moments/presentation/moments_strings.dart';
import '../admin_strings.dart';
import '../widgets/admin_confirm_dialog.dart';

class AdminMomentsTab extends ConsumerWidget {
  const AdminMomentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(momentsControllerProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              const Center(child: Text(AdminStrings.loadError)),
          data: (moments) {
            if (moments.isEmpty) {
              return const Center(child: Text(AdminStrings.emptyMoments));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: moments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _ModerationCard(
                moment: moments[index],
              ),
            );
          },
        );
  }
}

class _ModerationCard extends ConsumerWidget {
  const _ModerationCard({required this.moment});

  final MomentModel moment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: buildDogImage(moment.momentPhotoUrl, seed: moment.id),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${moment.dogName} • ${moment.authorName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${MomentsStrings.locationPin(moment.locationName)} • '
                  '${AdminStrings.timestamp(moment.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(moment.caption),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(AdminStrings.deleteMoment),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAdminDelete(
      context,
      message: AdminStrings.confirmDeleteMoment,
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(momentsControllerProvider.notifier).delete(moment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AdminStrings.momentDeleted)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AdminStrings.actionFailed)),
        );
      }
    }
  }
}
