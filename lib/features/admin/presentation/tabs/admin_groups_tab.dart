import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_cards.dart';
import '../../../groups/domain/groups_models.dart';
import '../../../groups/presentation/groups_controller.dart';
import '../../domain/admin_models.dart';
import '../admin_strings.dart';
import '../widgets/admin_ref_widgets.dart';
import 'admin_content_list.dart';
import 'admin_reports_tab.dart';

/// Pending groups (approve / reject) and all groups (delete).
class AdminGroupsTab extends StatelessWidget {
  const AdminGroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: primary,
            indicatorColor: primary,
            tabs: [
              Tab(text: AdminStrings.groupsPendingTab),
              Tab(text: AdminStrings.groupsAllTab),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _PendingGroups(),
                AdminContentList(kind: AdminContentKind.group),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingGroups extends ConsumerWidget {
  const _PendingGroups();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingGroupsProvider);
    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(AdminStrings.loadError)),
      data: (pending) {
        final groups = List<BreedGroup>.from(pending.whereType<BreedGroup>());
        if (groups.isEmpty) {
          return Center(child: Text(AdminStrings.emptyPendingGroups));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _PendingGroupCard(
            group: groups[index],
          ),
        );
      },
    );
  }
}

class _PendingGroupCard extends ConsumerWidget {
  const _PendingGroupCard({required this.group});

  final BreedGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardTokens.softShadow(0.08),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            group.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          AdminUserLabel(
            uid: group.createdBy,
            prefix: AdminStrings.createdByLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            onTap: () => openAdminUser(context, group.createdBy),
          ),
          SizedBox(height: 2),
          Text(
            AdminStrings.groupCreatedAt(group.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(groupsControllerProvider.notifier)
                        .approveGroup(group.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AdminStrings.groupApproved),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AdminStrings.actionFailed),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(AdminStrings.approveGroup),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(groupsControllerProvider.notifier)
                        .deleteGroup(group.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AdminStrings.groupDeleted),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AdminStrings.actionFailed),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(AdminStrings.rejectGroup),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
