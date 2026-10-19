import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_models.dart';
import '../admin_controller.dart';
import '../admin_strings.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_ref_widgets.dart';
import 'admin_reports_tab.dart';

/// Lost dogs / adoption / events / groups: who posted it (name, not uid),
/// status, close (resolved / adopted / approved) and delete.
class AdminContentList extends ConsumerWidget {
  const AdminContentList({super.key, required this.kind});

  final AdminContentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(adminContentProvider(kind)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(AdminStrings.loadError)),
          data: (items) {
            if (items.isEmpty) {
              return Center(child: Text(AdminStrings.emptyContent));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ContentCard(item: items[i]),
            );
          },
        );
  }
}

class _ContentCard extends ConsumerWidget {
  const _ContentCard({required this.item});

  final AdminContentItem item;

  bool get _closable => switch (item.kind) {
        AdminContentKind.lostDog => item.status == 'active',
        AdminContentKind.adoption => item.status == 'available',
        AdminContentKind.group => item.status == 'pending',
        AdminContentKind.event => false,
      };

  String get _ownerLabel => switch (item.kind) {
        AdminContentKind.event => AdminStrings.organizerLabel,
        AdminContentKind.group => AdminStrings.createdByLabel,
        _ => AdminStrings.uploaderLabel,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminTargetPreview(
              icon: switch (item.kind) {
                AdminContentKind.event => Icons.event_outlined,
                AdminContentKind.group => Icons.groups_outlined,
                _ => Icons.pets,
              },
              title: item.title.isEmpty ? '–' : item.title,
              subtitle: item.subtitle,
              imageUrl: item.imageUrl,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: item.ownerId.isEmpty
                      ? const SizedBox.shrink()
                      : AdminUserLabel(
                          uid: item.ownerId,
                          prefix: _ownerLabel,
                          style: theme.textTheme.bodySmall,
                          onTap: () => openAdminUser(context, item.ownerId),
                        ),
                ),
                Text(
                  AdminStrings.contentStatus(item.status),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (item.createdAt != null)
              Text(
                AdminStrings.timestamp(item.createdAt!),
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                if (_closable)
                  FilledButton.tonal(
                    onPressed: () => _close(context, ref),
                    child: Text(AdminStrings.closeAction(item.kind)),
                  ),
                TextButton.icon(
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(AdminStrings.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).closeContent(item.kind, item.id);
      messenger.showSnackBar(SnackBar(content: Text(AdminStrings.contentClosed)));
    } catch (error) {
      debugPrint('admin close ${item.kind.name} failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(AdminStrings.actionFailed)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAdminDelete(
      context,
      message: AdminStrings.confirmDeleteContent,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).deleteContent(item.kind, item.id);
      messenger.showSnackBar(
        SnackBar(content: Text(AdminStrings.contentDeleted)),
      );
    } catch (error) {
      debugPrint('admin delete ${item.kind.name} failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(AdminStrings.actionFailed)));
    }
  }
}
