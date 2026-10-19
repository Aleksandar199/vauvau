import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_models.dart';
import '../admin_controller.dart';
import '../admin_strings.dart';
import '../screens/admin_user_detail_screen.dart';
import '../widgets/admin_ref_widgets.dart';

enum _UserFilter { all, admins, partners, suspended }

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final _search = TextEditingController();
  var _filter = _UserFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _keep(AdminUserEntry user) {
    if (!user.matches(_search.text)) return false;
    return switch (_filter) {
      _UserFilter.all => true,
      _UserFilter.admins => user.isAdmin,
      _UserFilter.partners => user.isPartner,
      _UserFilter.suspended => user.isSuspended,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(adminUsersProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text(AdminStrings.loadError)),
          data: (users) {
            if (users.isEmpty) {
              return Center(child: Text(AdminStrings.emptyUsers));
            }
            final shown = users.where(_keep).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: AdminStrings.searchUsers,
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    children: [
                      for (final f in _UserFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(switch (f) {
                              _UserFilter.all => AdminStrings.filterAll,
                              _UserFilter.admins => AdminStrings.filterAdmins,
                              _UserFilter.partners =>
                                AdminStrings.filterPartners,
                              _UserFilter.suspended =>
                                AdminStrings.filterSuspended,
                            }),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: Text(
                        AdminStrings.totalUsers(users.length),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: shown.length == users.length
                          ? null
                          : Text(
                              AdminStrings.shownUsers(
                                shown.length,
                                users.length,
                              ),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: shown.length,
                    itemBuilder: (context, index) =>
                        _UserCard(user: shown[index]),
                  ),
                ),
              ],
            );
          },
        );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AdminUserEntry user;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AdminUserDetailScreen(uid: user.uid),
          ),
        ),
        leading: AdminAvatar(url: user.photoUrl, size: 40),
        title: Row(
          children: [
            Expanded(child: Text(user.name)),
            if (user.isSuspended)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: AdminRoleBadge(role: '', suspended: true),
              ),
            if (user.role != AdminRoles.user)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: AdminRoleBadge(role: user.role),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email.isEmpty ? AdminStrings.noEmail : user.email),
            Text(
              [
                if (user.city.isNotEmpty) user.city,
                AdminStrings.joinedOn(user.createdAt),
              ].join(' · '),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
