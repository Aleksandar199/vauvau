import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_models.dart';
import '../admin_controller.dart';
import '../admin_strings.dart';
import '../widgets/admin_confirm_dialog.dart';

class AdminFeedbackTab extends ConsumerWidget {
  const AdminFeedbackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(adminFeedbackProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text(AdminStrings.loadError)),
          data: (entries) {
            if (entries.isEmpty) {
              return Center(child: Text(AdminStrings.emptyFeedback));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _FeedbackCard(
                entry: entries[index],
              ),
            );
          },
        );
  }
}

class _FeedbackCard extends ConsumerWidget {
  const _FeedbackCard({required this.entry});

  final FeedbackEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor =
        entry.isResolved ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _Tag(
                  label: entry.isResolved
                      ? AdminStrings.resolved
                      : AdminStrings.isNew,
                  color: statusColor,
                ),
              ],
            ),
            Text(
              entry.userEmail.isEmpty ? AdminStrings.noEmail : entry.userEmail,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (entry.category.isNotEmpty)
                  _Tag(label: entry.category, color: theme.colorScheme.primary),
                Text(
                  AdminStrings.timestamp(entry.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.subject,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(entry.message),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (!entry.isResolved)
                  FilledButton.tonal(
                    onPressed: () => _resolve(context, ref),
                    child: Text(AdminStrings.resolve),
                  ),
                TextButton(
                  onPressed: () => _delete(context, ref),
                  child: Text(AdminStrings.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminRepositoryProvider).resolveFeedback(entry.id);
      if (context.mounted) {
        _notify(context, AdminStrings.feedbackResolved);
      }
    } catch (_) {
      if (context.mounted) {
        _notify(context, AdminStrings.actionFailed);
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAdminDelete(
      context,
      message: AdminStrings.confirmDeleteFeedback,
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).deleteFeedback(entry.id);
      if (context.mounted) {
        _notify(context, AdminStrings.feedbackDeleted);
      }
    } catch (_) {
      if (context.mounted) {
        _notify(context, AdminStrings.actionFailed);
      }
    }
  }

  void _notify(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
