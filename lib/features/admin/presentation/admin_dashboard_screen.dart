import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_cards.dart';
import '../../app_update/domain/app_update.dart';
import '../../app_update/presentation/app_update_host.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../map/domain/models/poi_model.dart';
import '../../map/presentation/user_poi_controller.dart';
import '../../moderation/presentation/report_controller.dart';
import '../domain/admin_models.dart';
import 'admin_controller.dart';
import 'admin_strings.dart';
import 'tabs/admin_content_list.dart';
import 'tabs/admin_feedback_tab.dart';
import 'tabs/admin_groups_tab.dart';
import 'tabs/admin_moments_tab.dart';
import 'tabs/admin_reports_tab.dart';
import 'tabs/admin_rewards_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'widgets/admin_edit_poi_dialog.dart';

/// Tab order (the home "needs attention" tiles jump to these).
abstract final class AdminTabs {
  static const home = 0;
  static const users = 1;
  static const reports = 2;
  static const feedback = 3;
  static const content = 4;
  static const groups = 5;
  static const rewards = 6;
  static const count = 7;
}

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
    final reports = ref.watch(activeReportsProvider).length;
    final feedback = ref.watch(newFeedbackCountProvider);
    return DefaultTabController(
      length: AdminTabs.count,
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
              _CountTab(label: AdminStrings.reportsTab, count: reports),
              _CountTab(label: AdminStrings.feedbackTab, count: feedback),
              Tab(text: AdminStrings.contentTab),
              Tab(text: AdminStrings.groupsTabShort),
              Tab(text: AdminStrings.rewardsTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HomeTab(),
            AdminUsersTab(),
            AdminReportsTab(),
            AdminFeedbackTab(),
            _ContentTab(),
            AdminGroupsTab(),
            AdminRewardsTab(),
          ],
        ),
      ),
    );
  }
}

class _CountTab extends StatelessWidget {
  const _CountTab({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatSpec {
  const _StatSpec(this.label, this.value, this.icon, this.color, {this.tab});

  final String label;
  final int? value;
  final IconData icon;
  final Color color;
  final int? tab;
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final s = statsAsync.value ?? const AdminStats();
    final pendingGroups =
        ref.watch(pendingGroupsProvider).value?.length ?? s.groupsPending;
    final attention = [
      _StatSpec(
        AdminStrings.statOpenReports,
        ref.watch(activeReportsProvider).length,
        Icons.flag_outlined,
        const Color(0xFFDC2626),
        tab: AdminTabs.reports,
      ),
      _StatSpec(
        AdminStrings.statNewFeedback,
        ref.watch(newFeedbackCountProvider),
        Icons.mail_outline,
        const Color(0xFFEA580C),
        tab: AdminTabs.feedback,
      ),
      _StatSpec(
        AdminStrings.statGroupsPending,
        pendingGroups,
        Icons.groups_outlined,
        const Color(0xFF7C3AED),
        tab: AdminTabs.groups,
      ),
      _StatSpec(
        AdminStrings.statPending,
        ref.watch(pendingPoisProvider).length,
        Icons.place_outlined,
        const Color(0xFF15803D),
        tab: AdminTabs.content,
      ),
    ];
    const blue = Color(0xFF2563EB);
    const orange = Color(0xFFEA580C);
    const green = Color(0xFF15803D);
    const teal = Color(0xFF0E7490);
    final sections = <(String, List<_StatSpec>)>[
      (
        AdminStrings.sectionCommunity,
        [
          _StatSpec(AdminStrings.statUsers, s.users, Icons.people_outline, blue,
              tab: AdminTabs.users),
          _StatSpec(AdminStrings.statNew7, s.newUsers7, Icons.person_add_alt, blue),
          _StatSpec(AdminStrings.statNew30, s.newUsers30, Icons.person_add_alt_1, blue),
          _StatSpec(AdminStrings.statSuspended, s.suspendedUsers, Icons.block,
              const Color(0xFFB91C1C), tab: AdminTabs.users),
          _StatSpec(AdminStrings.statAllDogs, s.dogs, Icons.pets, orange),
          _StatSpec(AdminStrings.statMatches, s.matches, Icons.favorite_border, orange),
        ],
      ),
      (
        AdminStrings.sectionActivity,
        [
          _StatSpec(AdminStrings.statChats, s.activeChats7, Icons.chat_bubble_outline, teal),
          _StatSpec(AdminStrings.statStories, s.activeStories, Icons.auto_stories_outlined, teal),
          _StatSpec(AdminStrings.statMoments, s.moments, Icons.photo_outlined, teal,
              tab: AdminTabs.content),
          _StatSpec(AdminStrings.statEvents, s.eventsUpcoming, Icons.event_outlined, teal,
              tab: AdminTabs.content),
        ],
      ),
      (
        AdminStrings.sectionHelp,
        [
          _StatSpec(AdminStrings.statLost, s.lostDogsActive, Icons.campaign_outlined,
              const Color(0xFFDC2626), tab: AdminTabs.content),
          _StatSpec(AdminStrings.statAdoption, s.adoptionsAvailable, Icons.home_outlined,
              green, tab: AdminTabs.content),
        ],
      ),
      (
        AdminStrings.sectionRewards,
        [
          _StatSpec(AdminStrings.statWalks, s.walks, Icons.directions_walk, green),
          _StatSpec(AdminStrings.statKm, s.walkKm, Icons.route_outlined, green),
          _StatSpec(AdminStrings.statClaimed, s.couponsClaimed,
              Icons.confirmation_number_outlined, orange, tab: AdminTabs.rewards),
          _StatSpec(AdminStrings.statRedeemed, s.couponsRedeemed, Icons.task_alt,
              orange, tab: AdminTabs.rewards),
          _StatSpec(AdminStrings.statPartners, s.partners, Icons.storefront_outlined,
              orange, tab: AdminTabs.rewards),
        ],
      ),
    ];

    final title = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        );
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminStatsProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Expanded(child: Text(AdminStrings.attention, style: title)),
              IconButton(
                tooltip: AdminStrings.refresh,
                onPressed: () => ref.invalidate(adminStatsProvider),
                icon: statsAsync.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          _StatGrid(items: attention),
          for (final (name, items) in sections) ...[
            const SizedBox(height: 16),
            Text(name, style: title),
            const SizedBox(height: 8),
            _StatGrid(items: items),
          ],
          const SizedBox(height: 8),
          Text(
            AdminStrings.statUnavailable,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          const _AppConfigCard(),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<_StatSpec> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(width: width, height: 84, child: _StatTile(spec: item)),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.spec});

  final _StatSpec spec;

  @override
  Widget build(BuildContext context) {
    final tab = spec.tab;
    return Material(
      color: Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: tab == null
            ? null
            : () => DefaultTabController.of(context).animateTo(tab),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppCardTokens.softShadow(0.06),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(spec.icon, color: spec.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      spec.value == null ? '–' : '${spec.value}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      spec.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `app_config/android` {minBuild, latestBuild} – the update prompt.
class _AppConfigCard extends ConsumerWidget {
  const _AppConfigCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAppConfigProvider);
    final config = async.value;
    // The +N of pubspec.yaml this admin app was built with.
    final installed = ref.watch(installedBuildNumberProvider).value;
    final canPublish = installed != null &&
        !async.isLoading &&
        !async.hasError &&
        installed > (config?.latestBuild ?? 0);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: Text(AdminStrings.appConfigTitle),
            subtitle: Text(
              async.isLoading
                  ? AdminStrings.loadingName
                  : async.hasError
                      ? AdminStrings.loadError
                      : config == null
                          ? AdminStrings.appConfigMissing
                          : AdminStrings.appConfigSummary(
                              config.minBuild,
                              config.latestBuild,
                            ),
            ),
            trailing: TextButton(
              onPressed: () => _edit(context, ref, config, installed),
              child: Text(AdminStrings.edit2),
            ),
          ),
          if (installed != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AdminStrings.appConfigThisBuild(installed),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (canPublish) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      key: const ValueKey('admin-publish-build'),
                      onPressed: () => _save(
                        context,
                        ref,
                        AppUpdateConfig(
                          minBuild: config?.minBuild ?? 0,
                          latestBuild: installed,
                        ),
                      ),
                      icon: const Icon(Icons.publish_outlined),
                      label: Text(AdminStrings.appConfigPublish(installed)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AdminStrings.appConfigPublishHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AppUpdateConfig config,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).saveAppConfig(config);
      ref.invalidate(adminAppConfigProvider);
      messenger.showSnackBar(SnackBar(content: Text(AdminStrings.saved)));
    } catch (error) {
      debugPrint('app_config save failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(AdminStrings.actionFailed)));
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AppUpdateConfig? current,
    int? installed,
  ) async {
    final latest = TextEditingController(
      text: '${current?.latestBuild ?? installed ?? 0}',
    );
    final min = TextEditingController(text: '${current?.minBuild ?? 0}');
    final form = GlobalKey<FormState>();
    String? validate(String? v) =>
        int.tryParse(v ?? '') == null ? AdminStrings.rewardsNumber : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AdminStrings.appConfigTitle),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: latest,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: AdminStrings.appConfigLatest),
                validator: validate,
              ),
              TextFormField(
                controller: min,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: AdminStrings.appConfigMin),
                validator: (v) {
                  final base = validate(v);
                  if (base != null) return base;
                  final l = int.tryParse(latest.text) ?? 0;
                  return int.parse(v!) > l ? AdminStrings.appConfigInvalid : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AdminStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(AdminStrings.save),
          ),
        ],
      ),
    );
    final config = AppUpdateConfig(
      minBuild: int.tryParse(min.text) ?? 0,
      latestBuild: int.tryParse(latest.text) ?? 0,
    );
    if (ok != true || !context.mounted) return;
    await _save(context, ref, config);
  }
}

class _ContentTab extends StatelessWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: AdminStrings.contentMoments),
              Tab(text: AdminStrings.contentPending),
              Tab(text: AdminStrings.contentLost),
              Tab(text: AdminStrings.contentAdoption),
              Tab(text: AdminStrings.contentEvents),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AdminMomentsTab(),
                _PendingPoisTab(),
                AdminContentList(kind: AdminContentKind.lostDog),
                AdminContentList(kind: AdminContentKind.adoption),
                AdminContentList(kind: AdminContentKind.event),
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
