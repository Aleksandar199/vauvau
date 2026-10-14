import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/presentation/admin_controller.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../adoption/presentation/screens/adoption_screen.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../events/presentation/events_screen.dart';
import '../../groups/presentation/groups_list_screen.dart';
import '../../moments/presentation/moments_screen.dart';
import '../../lost_dogs/presentation/lost_dogs_screen.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../profile/presentation/settings_screen.dart';
import '../../support/presentation/about_app_dialog.dart';
import '../../support/presentation/rules_and_support_screen.dart';
import '../../support/presentation/widgets/official_contact_links.dart';
import '../domain/app_drawer_catalog.dart';
import 'home_tab.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final user = ref.watch(authStateProvider).asData?.value;
    final tabIndex = ref.watch(homeTabIndexProvider);
    final photoUrl = user?.ownerAvatarUrl ?? '';
    final firstName = _firstName(profile.ownerName);
    final isAdmin = ref.watch(isAdminProvider);

    return Drawer(
      backgroundColor: const Color(0xFF111827),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              photoUrl: photoUrl,
              firstName: firstName,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                children: [
                  _SectionHeader(AppDrawerCatalog.communitySection),
                  for (final item in AppDrawerCatalog.communityItems)
                    _DrawerTile(
                      item: item,
                      selected:
                          item.tabIndex != null && item.tabIndex == tabIndex,
                      onTap: () => _onItemTap(context, ref, item),
                    ),
                  SizedBox(height: 10),
                  _SectionHeader(AppDrawerCatalog.helpDogsSection),
                  for (final item in AppDrawerCatalog.helpDogsItems)
                    _DrawerTile(
                      item: item,
                      selected:
                          item.tabIndex != null && item.tabIndex == tabIndex,
                      onTap: () => _onItemTap(context, ref, item),
                    ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Divider(color: Color(0x33FFFFFF), height: 20),
                  ),
                  for (final item in AppDrawerCatalog.systemItems)
                    _DrawerTile(
                      item: item,
                      selected: false,
                      onTap: () => _onItemTap(context, ref, item),
                    ),
                  if (isAdmin)
                    _DrawerTile(
                      item: AppDrawerCatalog.adminItem,
                      selected: false,
                      badgeCount: ref.watch(newFeedbackCountProvider),
                      onTap: () => _onItemTap(
                        context,
                        ref,
                        AppDrawerCatalog.adminItem,
                      ),
                    ),
                  SizedBox(height: 8),
                  OfficialContactLinks(compact: true, dark: true),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.white70,
                    ),
                    onPressed: () => showAboutAppDialog(context),
                    child: Text(AppDrawerCatalog.about),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onItemTap(
    BuildContext context,
    WidgetRef ref,
    AppDrawerDestination item,
  ) async {
    Navigator.of(context).pop(); // close drawer
    if (item.kind == DrawerItemKind.tab) {
      if (item.tabIndex != null) {
        ref.read(homeTabIndexProvider.notifier).setIndex(item.tabIndex!);
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    // Drop any prior feature route (Events/Adoption/…) so its FAB cannot sit
    // under Moments/Stories and blow up Flutter web hit-testing.
    final nav = Navigator.of(context);
    nav.popUntil((route) => route.isFirst);
    if (!context.mounted) {
      return;
    }
    final page = switch (item.kind) {
      DrawerItemKind.lostDogs => const LostDogsScreen(),
      DrawerItemKind.adopt => const AdoptionScreen(),
      DrawerItemKind.groups => const GroupsListScreen(),
      DrawerItemKind.events => const EventsScreen(),
      DrawerItemKind.moments => const MomentsScreen(),
      DrawerItemKind.rules => const RulesAndSupportScreen(),
      DrawerItemKind.admin => const AdminDashboardScreen(),
      DrawerItemKind.settings => const SettingsScreen(),
      DrawerItemKind.page => DrawerSectionScreen(destination: item),
      DrawerItemKind.tab => null,
    };
    if (page == null) {
      return;
    }
    await nav.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  String _firstName(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return 'VauVau';
    }
    if (value.contains('@')) {
      return value.split('@').first;
    }
    return value.split(RegExp(r'\s+')).first;
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.photoUrl,
    required this.firstName,
  });

  final String photoUrl;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C1410),
            Color(0xFFC2410C),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppDrawerCatalog.brandHeader,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  child: photoUrl.startsWith('http')
                      ? ClipOval(
                          child: buildDogImage(
                            photoUrl,
                            seed: photoUrl,
                            width: 44,
                            height: 44,
                          ),
                        )
                      : Text(
                          firstName.isEmpty ? 'V' : firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final AppDrawerDestination item;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final destructive = item.destructive;
    final accent = item.accent;
    final color = destructive
        ? const Color(0xFFFCA5A5)
        : accent
            ? const Color(0xFFFBBF24)
            : selected
                ? AppColors.primary
                : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: accent
            ? const Color(0x33DC2626)
            : selected
                ? AppColors.primary.withValues(alpha: 0.22)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 6,
              title: Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected || accent || destructive
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              trailing: accent
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        AppDrawerCatalog.hitnoBadge,
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : badgeCount > 0
                      ? Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}

class DrawerSectionScreen extends StatelessWidget {
  const DrawerSectionScreen({super.key, required this.destination});

  final AppDrawerDestination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(destination.label)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destination.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
