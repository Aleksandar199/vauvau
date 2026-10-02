import 'package:flutter/material.dart';

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
  settings,
  page,
}

abstract final class AppDrawerCatalog {
  static const String menuTooltip = 'Meni';
  static const String home = 'Početna';
  static const String brandHeader = '🐾 VauVau';
  static const String communitySection = '🐕 ZAJEDNICA';
  static const String helpDogsSection = '❤️ POMOĆ PSIMA';
  static const String lostDogs = '🚨 Izgubljeni psi';
  static const String adopt = '🏠 Udomi';
  static const String groups = '👥 Grupe';
  static const String events = '📅 Događaji i šetnje';
  static const String moments = '📸 VauVau Moments';
  static const String rules = '❓ Pravila & Podrška';
  static const String admin = 'Admin Panel';
  static const String profile = '👤 Moj Profil';
  static const String settings = '⚙️ Podešavanja';
  static const String support = 'Podrška';
  static const String about = 'O aplikaciji';
  static const String locationPin = '📍';
  static const String hitnoBadge = 'HITNO';

  static const List<AppDrawerDestination> communityItems = [
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

  static const List<AppDrawerDestination> helpDogsItems = [
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

  static const List<AppDrawerDestination> systemItems = [
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
  static const AppDrawerDestination adminItem = AppDrawerDestination(
    id: 'admin',
    label: admin,
    icon: Icons.admin_panel_settings,
    kind: DrawerItemKind.admin,
  );

  /// Legacy flat lists kept for callers that still iterate all destinations.
  static const List<AppDrawerDestination> primaryItems = [
    ...communityItems,
    ...helpDogsItems,
    AppDrawerDestination(
      id: 'rules',
      label: rules,
      icon: Icons.help_outline,
      kind: DrawerItemKind.rules,
    ),
  ];

  static const List<AppDrawerDestination> footerItems = [
    AppDrawerDestination(
      id: 'settings',
      label: settings,
      icon: Icons.settings_outlined,
      kind: DrawerItemKind.settings,
    ),
  ];

  static const List<AppDrawerDestination> items = [
    ...communityItems,
    ...helpDogsItems,
    ...systemItems,
  ];
}
