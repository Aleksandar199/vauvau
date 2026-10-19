import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../moderation/presentation/report_controller.dart';
import '../../../partners/presentation/partner_providers.dart';
import '../admin_controller.dart';
import '../admin_strings.dart';
import '../tabs/admin_reports_tab.dart';
import '../widgets/admin_ref_widgets.dart';
import '../widgets/admin_user_actions.dart';

/// Profile, dogs, reports against the user, role (user ⇄ partner) and
/// suspension.
class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(adminUserEntryProvider(uid));
    final theme = Theme.of(context);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AdminStrings.userDetail)),
        body: Center(child: Text(AdminStrings.userNotFound)),
      );
    }
    final partners = ref.watch(partnersProvider).value ?? const [];
    final partnerName = [
      for (final p in partners)
        if (p.id == user.partnerId) p.name,
    ].firstOrNull;
    final reports = [
      for (final r in ref.watch(contentReportsProvider).value ?? const [])
        if (r.reportedUserId == uid || r.targetId == uid) r,
    ];
    final dogs = ref.watch(adminUserDogsProvider(uid));
    final section = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );

    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              AdminAvatar(url: user.photoUrl, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: theme.textTheme.titleLarge),
                    Text(user.email.isEmpty ? AdminStrings.noEmail : user.email),
                    if (user.city.isNotEmpty) Text(user.city),
                    Text(
                      AdminStrings.joinedOn(user.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        AdminRoleBadge(role: user.role),
                        if (user.isSuspended)
                          const AdminRoleBadge(role: '', suspended: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: uid));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AdminStrings.idCopied)),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text('${AdminStrings.copyId} ($uid)', overflow: TextOverflow.ellipsis),
          ),
          const Divider(),
          Text(AdminStrings.roleSection, style: section),
          const SizedBox(height: 6),
          if (user.isAdmin)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(AdminStrings.roleAdmin),
              subtitle: Text(AdminStrings.adminRoleNote),
            )
          else if (user.isPartner) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined),
              title: Text(
                partnerName == null
                    ? AdminStrings.rolePartnerUnknown
                    : AdminStrings.roleCurrentPartner(partnerName),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      assignPartnerFlow(context, ref, uid, partners),
                  child: Text(AdminStrings.choosePartner),
                ),
                TextButton(
                  onPressed: () => removePartnerFlow(context, ref, uid),
                  child: Text(AdminStrings.removePartner),
                ),
              ],
            ),
          ] else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(AdminStrings.roleUser),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: const ValueKey('admin-make-partner'),
                onPressed: () =>
                    assignPartnerFlow(context, ref, uid, partners),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(AdminStrings.makePartner),
              ),
            ),
          ],
          const Divider(height: 32),
          Text(AdminStrings.moderationSection, style: section),
          const SizedBox(height: 6),
          if (user.isSuspended) ...[
            Text(AdminStrings.suspendedSince(user.suspendedReason)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => unsuspendUserFlow(context, ref, uid),
                icon: const Icon(Icons.lock_open),
                label: Text(AdminStrings.unsuspendUser),
              ),
            ),
          ] else if (!user.isAdmin)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                ),
                onPressed: () => suspendUserFlow(context, ref, uid),
                icon: const Icon(Icons.block),
                label: Text(AdminStrings.suspendUser),
              ),
            ),
          const Divider(height: 32),
          Text(AdminStrings.userDogs, style: section),
          const SizedBox(height: 6),
          dogs.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, _) => Text(AdminStrings.loadError),
            data: (items) => items.isEmpty
                ? Text(AdminStrings.noDogs)
                : Column(
                    children: [
                      for (final d in items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: AdminAvatar(
                            url: d.photoUrl,
                            size: 40,
                            icon: Icons.pets,
                          ),
                          title: Text(d.name),
                          subtitle: d.breed.isEmpty ? null : Text(d.breed),
                        ),
                    ],
                  ),
          ),
          const Divider(height: 32),
          Text(AdminStrings.reportsAgainst, style: section),
          const SizedBox(height: 6),
          if (reports.isEmpty)
            Text(AdminStrings.noReportsAgainst)
          else
            for (final r in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminReportCard(report: r, compact: true),
              ),
        ],
      ),
    );
  }
}
