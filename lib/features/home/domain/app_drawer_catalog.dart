import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

class AppDrawerDestination {
  const AppDrawerDestination({
    required this.id,
    required this.label,
    required this.icon,
    this.body = '',
    this.tabIndex,
    this.kind = DrawerItemKind.page,
    this.accent = false,
    this.destructive = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final String body;
  final int? tabIndex;
  final DrawerItemKind kind;
  final bool accent;
  final bool destructive;
}

enum DrawerItemKind {
  tab,
  lostDogs,
  adopt,
  groups,
  events,
  moments,
  rules,
  admin,
  partnerCoupons,
  settings,
  page,
}

abstract final class AppDrawerCatalog {
  static String get menuTooltip => L10n.tr('Meni', 'Menu');
  static String get home => L10n.tr('Početna', 'Home');
  static String get brandHeader => '🐾 VauVau';
  static String get communitySection => L10n.tr('🐕 ZAJEDNICA', '🐕 COMMUNITY');
  static String get helpDogsSection => L10n.tr('❤️ POMOĆ PSIMA', '❤️ HELP DOGS');
  static String get lostDogs => L10n.tr('🚨 Izgubljeni psi', '🚨 Lost dogs');
  static String get adopt => L10n.tr('🏠 Udomi', '🏠 Adopt');
  static String get groups => L10n.tr('👥 Grupe', '👥 Groups');
  static String get events => L10n.tr('📅 Događaji i šetnje', '📅 Events & walks');
  static String get moments => L10n.tr('📸 VauVau Moments', '📸 VauVau Moments');
  static String get rules => L10n.tr('❓ Pravila & Podrška', '❓ Rules & Support');
  static String get admin => L10n.tr('Admin Panel', 'Admin Panel');
  static String get partnerCoupons =>
      L10n.tr('🏷️ Kuponi partnera', '🏷️ Partner coupons');
  static String get profile => L10n.tr('👤 Moj Profil', '👤 My profile');
  static String get settings => L10n.tr('⚙️ Podešavanja', '⚙️ Settings');
  static String get support => L10n.tr('Podrška', 'Support');
  static String get about => L10n.tr('O aplikaciji', 'About the app');
  static String get locationPin => '📍';
  static String get hitnoBadge => L10n.tr('HITNO', 'URGENT');

  static List<AppDrawerDestination> get communityItems => [
        AppDrawerDestination(
          id: 'groups',
          label: groups,
          icon: Icons.groups_outlined,
          kind: DrawerItemKind.groups,
        ),
        AppDrawerDestination(
          id: 'events',
          label: events,
          icon: Icons.event_available_outlined,
          kind: DrawerItemKind.events,
        ),
        AppDrawerDestination(
          id: 'moments',
          label: moments,
          icon: Icons.camera_alt_outlined,
          kind: DrawerItemKind.moments,
        ),
      ];

  static List<AppDrawerDestination> get helpDogsItems => [
        AppDrawerDestination(
          id: 'lostDogs',
          label: lostDogs,
          icon: Icons.emergency_share_outlined,
          kind: DrawerItemKind.lostDogs,
          accent: true,
        ),
        AppDrawerDestination(
          id: 'adopt',
          label: adopt,
          icon: Icons.home_outlined,
          kind: DrawerItemKind.adopt,
        ),
      ];

  static List<AppDrawerDestination> get systemItems => [
        AppDrawerDestination(
          id: 'rules',
          label: rules,
          icon: Icons.help_outline,
          kind: DrawerItemKind.rules,
        ),
        AppDrawerDestination(
          id: 'settings',
          label: settings,
          icon: Icons.settings_outlined,
          kind: DrawerItemKind.settings,
        ),
      ];

  /// Rendered only when [isAdminProvider] is true.
  static AppDrawerDestination get adminItem => AppDrawerDestination(
        id: 'admin',
        label: admin,
        icon: Icons.admin_panel_settings,
        kind: DrawerItemKind.admin,
      );

  /// Rendered only for partner shop accounts ([isPartnerProvider]).
  static AppDrawerDestination get partnerCouponsItem => AppDrawerDestination(
        id: 'partner_coupons',
        label: partnerCoupons,
        icon: Icons.confirmation_number_outlined,
        kind: DrawerItemKind.partnerCoupons,
      );

  /// Legacy flat lists kept for callers that still iterate all destinations.
  static List<AppDrawerDestination> get primaryItems => [
        ...communityItems,
        ...helpDogsItems,
        AppDrawerDestination(
          id: 'rules',
          label: rules,
          icon: Icons.help_outline,
          kind: DrawerItemKind.rules,
        ),
      ];

  static List<AppDrawerDestination> get footerItems => [
        AppDrawerDestination(
          id: 'settings',
          label: settings,
          icon: Icons.settings_outlined,
          kind: DrawerItemKind.settings,
        ),
      ];

  static List<AppDrawerDestination> get items => [
        ...communityItems,
        ...helpDogsItems,
        ...systemItems,
      ];
}
