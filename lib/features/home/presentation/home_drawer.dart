import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/serbia_locations.dart';
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
import '../../profile/presentation/sign_out_action.dart';
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
    final location = SerbiaLocations.sanitizeLocationLabel(
      profile.ownerLocation.isNotEmpty
          ? profile.ownerLocation
          : user?.locationLabel ?? '',
    );

    return Drawer(
      backgroundColor: const Color(0xFF111827),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerHeader(
            photoUrl: photoUrl,
            firstName: firstName,
            location: location,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              children: [
                for (final item in AppDrawerCatalog.primaryItems)
                  _DrawerTile(
                    item: item,
                    selected: item.tabIndex != null && item.tabIndex == tabIndex,
                    onTap: () => _onItemTap(context, ref, item),
                  ),
                if (ref.watch(isAdminProvider))
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
                const SizedBox(height: 8),
                const OfficialContactLinks(compact: true, dark: true),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.white70,
                  ),
                  onPressed: () => showAboutAppDialog(context),
                  child: const Text(AppDrawerCatalog.about),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Color(0x33FFFFFF), height: 1),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  for (final item in AppDrawerCatalog.footerItems)
                    _DrawerTile(
                      item: item,
                      selected: false,
                      onTap: () => _onItemTap(context, ref, item),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onItemTap(
    BuildContext context,
    WidgetRef ref,
    AppDrawerDestination item,
  ) async {
    Navigator.of(context).pop();
    switch (item.kind) {
      case DrawerItemKind.tab:
        if (item.tabIndex != null) {
          ref.read(homeTabIndexProvider.notifier).setIndex(item.tabIndex!);
        }
      case DrawerItemKind.lostDogs:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LostDogsScreen()),
        );
      case DrawerItemKind.adopt:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AdoptionScreen()),
        );
      case DrawerItemKind.groups:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GroupsListScreen()),
        );
      case DrawerItemKind.events:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EventsScreen()),
        );
      case DrawerItemKind.moments:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MomentsScreen()),
        );
      case DrawerItemKind.rules:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const RulesAndSupportScreen(),
          ),
        );
      case DrawerItemKind.admin:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AdminDashboardScreen(),
          ),
        );
      case DrawerItemKind.settings:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        );
      case DrawerItemKind.signOut:
        if (context.mounted) {
          await confirmAndSignOut(context, ref);
        }
      case DrawerItemKind.page:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DrawerSectionScreen(destination: item),
          ),
        );
    }
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
    required this.location,
  });

  final String photoUrl;
  final String firstName;
  final String location;

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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pets, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white24,
                backgroundImage:
                    photoUrl.isEmpty ? null : NetworkImage(photoUrl),
                child: photoUrl.isEmpty
                    ? Text(
                        firstName.isEmpty ? 'V' : firstName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                firstName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${AppDrawerCatalog.locationPin} $location',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
    final accent = item.accent;
    final color = accent
        ? const Color(0xFFFBBF24)
        : selected
            ? AppColors.primary
            : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: accent
            ? const Color(0x33DC2626)
            : selected
                ? AppColors.primary.withValues(alpha: 0.22)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: color,
                            fontWeight:
                                selected || accent ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (accent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'HITNO',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (badgeCount > 0)
                        Container(
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
                        ),
                    ],
                  ),
                ),
              ],
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
