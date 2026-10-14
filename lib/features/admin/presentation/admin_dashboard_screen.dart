import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_cards.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/discover_controller.dart';
import '../../map/domain/models/poi_model.dart';
import '../../map/presentation/user_poi_controller.dart';
import '../../moderation/presentation/report_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import 'admin_controller.dart';
import 'admin_strings.dart';
import 'tabs/admin_feedback_tab.dart';
import 'tabs/admin_groups_tab.dart';
import 'tabs/admin_moments_tab.dart';
import 'tabs/admin_reports_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'widgets/admin_edit_poi_dialog.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(AdminStrings.title)),
        body: Center(child: Text(AdminStrings.denied)),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AdminStrings.title),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            tabs: [
              Tab(text: AdminStrings.statsTab),
              Tab(text: AdminStrings.usersTab),
              Tab(text: AdminStrings.reportsTab),
              Tab(text: AdminStrings.contentTab),
              Tab(text: AdminStrings.groupsTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StatsTab(),
            AdminUsersTab(),
            AdminReportsTab(),
            _ContentTab(),
            AdminGroupsTab(),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final userCount = usersAsync.asData?.value.length ?? 0;
    final dogs = <String, DiscoverProfile>{
      for (final dog in ref.watch(discoverProfilesProvider)) dog.id: dog,
      for (final dog in ref.watch(profileControllerProvider).dogs) dog.id: dog,
    };
    final dogCount = dogs.length;
    final reportCount = ref.watch(activeReportsProvider).length;
    final pendingCount = ref.watch(pendingPoisProvider).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _StatTile(
                label: AdminStrings.statUsers,
                value: '$userCount',
                icon: Icons.groups_outlined,
                color: const Color(0xFF2563EB),
              ),
              _StatTile(
                label: AdminStrings.statDogs,
                value: '$dogCount',
                icon: Icons.pets,
                color: const Color(0xFFEA580C),
              ),
              _StatTile(
                label: AdminStrings.statReports,
                value: '$reportCount',
                icon: Icons.flag_outlined,
                color: const Color(0xFFDC2626),
              ),
              _StatTile(
                label: AdminStrings.statPending,
                value: '$pendingCount',
                icon: Icons.place_outlined,
                color: const Color(0xFF15803D),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AdminStrings.feedbackTab,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        const Expanded(child: AdminFeedbackTab()),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardTokens.softShadow(0.08),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.05,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentTab extends StatelessWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: AdminStrings.contentMoments),
              Tab(text: AdminStrings.contentPending),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AdminMomentsTab(),
                _PendingPoisTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPoisTab extends ConsumerWidget {
  const _PendingPoisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingPoisProvider);
    if (pending.isEmpty) {
      return Center(child: Text(AdminStrings.emptyPending));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final poi = pending[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppCardTokens.softShadow(0.06),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(poi.name, style: Theme.of(context).textTheme.titleMedium),
              Text(poi.address),
              Text(poi.category.name),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () async {
                      await ref
                          .read(userPoiSubmissionsProvider.notifier)
                          .approve(poi.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AdminStrings.approved)),
                        );
                      }
                    },
                    child: Text(AdminStrings.approve),
                  ),
                  OutlinedButton(
                    onPressed: () => _editPoi(context, ref, poi),
                    child: Text(AdminStrings.edit),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(userPoiSubmissionsProvider.notifier)
                          .reject(poi.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AdminStrings.rejected)),
                        );
                      }
                    },
                    child: Text(AdminStrings.reject),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editPoi(
    BuildContext context,
    WidgetRef ref,
    PoiModel poi,
  ) async {
    final result = await showAdminEditPoiDialog(
      context: context,
      ref: ref,
      poi: poi,
    );
    if (result != AdminEditPoiResult.cancelled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminStrings.saved)),
      );
    }
  }
}
