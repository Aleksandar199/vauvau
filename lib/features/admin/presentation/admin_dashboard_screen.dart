import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/content_validation_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/discover_controller.dart';
import '../../map/domain/models/poi_model.dart';
import '../../map/presentation/user_poi_controller.dart';
import '../../moderation/domain/content_report.dart';
import '../../moderation/presentation/report_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import 'admin_strings.dart';
import 'tabs/admin_feedback_tab.dart';
import 'tabs/admin_moments_tab.dart';
import 'tabs/admin_users_tab.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text(AdminStrings.title)),
        body: const Center(child: Text(AdminStrings.denied)),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AdminStrings.title),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: AdminStrings.feedbackTab),
              Tab(text: AdminStrings.momentsTab),
              Tab(text: AdminStrings.usersTab),
              Tab(text: AdminStrings.pendingTab),
              Tab(text: AdminStrings.reportsTab),
              Tab(text: AdminStrings.searchTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminFeedbackTab(),
            AdminMomentsTab(),
            AdminUsersTab(),
            _PendingPoisTab(),
            _ReportsTab(),
            _SearchTab(),
          ],
        ),
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
      return const Center(child: Text(AdminStrings.emptyPending));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final poi = pending[index];
        return Card(
          child: Padding(
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
                            const SnackBar(content: Text(AdminStrings.approved)),
                          );
                        }
                      },
                      child: const Text(AdminStrings.approve),
                    ),
                    OutlinedButton(
                      onPressed: () => _editPoi(context, ref, poi),
                      child: const Text(AdminStrings.edit),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(userPoiSubmissionsProvider.notifier)
                            .reject(poi.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(AdminStrings.rejected)),
                          );
                        }
                      },
                      child: const Text(AdminStrings.reject),
                    ),
                  ],
                ),
              ],
            ),
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
    final name = TextEditingController(text: poi.name);
    final address = TextEditingController(text: poi.address);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AdminStrings.editTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: AdminStrings.name),
              ),
              TextField(
                controller: address,
                decoration:
                    const InputDecoration(labelText: AdminStrings.address),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Otkaži'),
            ),
            FilledButton(
              onPressed: () {
                final invalid =
                    ContentValidationService.validateTitle(name.text) ??
                        ContentValidationService.validateText(address.text);
                if (invalid != null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(invalid)),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sačuvaj'),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      await ref.read(userPoiSubmissionsProvider.notifier).updatePoi(
            poi.copyWith(
              name: name.text.trim(),
              address: address.text.trim(),
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AdminStrings.saved)),
        );
      }
    }
    name.dispose();
    address.dispose();
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(activeReportsProvider);
    if (reports.isEmpty) {
      return const Center(child: Text(AdminStrings.emptyReports));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.reason,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${report.contentTypeKey} • ${report.targetId}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () async {
                        ref
                            .read(hiddenContentProvider.notifier)
                            .hide(report.targetId);
                        if (report.contentType == ReportContentType.poi) {
                          await ref
                              .read(userPoiSubmissionsProvider.notifier)
                              .reject(report.targetId);
                        }
                        await ref
                            .read(reportControllerProvider)
                            .resolve(report.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AdminStrings.blocked),
                            ),
                          );
                        }
                      },
                      child: const Text(AdminStrings.block),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(reportControllerProvider)
                            .dismiss(report.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AdminStrings.dismissed),
                            ),
                          );
                        }
                      },
                      child: const Text(AdminStrings.dismiss),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab();

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final dogs = <DiscoverProfile>[
      ...ref.watch(discoverProfilesProvider),
      ...ref.watch(profileControllerProvider).dogs,
    ];
    final byId = <String, DiscoverProfile>{
      for (final dog in dogs) dog.id: dog,
    };
    final uniqueDogs = byId.values.toList();
    final visibleDogs = uniqueDogs.where((dog) {
      if (needle.isEmpty) {
        return true;
      }
      return dog.name.toLowerCase().contains(needle) ||
          dog.ownerName.toLowerCase().contains(needle) ||
          dog.breed.toLowerCase().contains(needle);
    }).toList();

    final owners = <String>{
      for (final dog in uniqueDogs) dog.ownerName,
    }.toList();
    final visibleOwners = owners.where((owner) {
      if (needle.isEmpty) {
        return true;
      }
      return owner.toLowerCase().contains(needle);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: AdminStrings.searchHint,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                AdminStrings.users,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (visibleOwners.isEmpty)
                const Text(AdminStrings.noSearch)
              else
                for (final owner in visibleOwners)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(owner),
                  ),
              const SizedBox(height: 16),
              Text(
                AdminStrings.dogs,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (visibleDogs.isEmpty)
                const Text(AdminStrings.noSearch)
              else
                for (final dog in visibleDogs)
                  ListTile(
                    leading: const Icon(Icons.pets),
                    title: Text(dog.name),
                    subtitle: Text('${dog.ownerName} • ${dog.breed}'),
                    trailing: IconButton(
                      tooltip: AdminStrings.block,
                      onPressed: () {
                        ref.read(hiddenContentProvider.notifier).hide(dog.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(AdminStrings.blocked)),
                        );
                      },
                      icon: const Icon(Icons.block),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
