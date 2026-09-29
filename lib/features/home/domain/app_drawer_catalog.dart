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
  });

  final String id;
  final String label;
  final IconData icon;
  final String body;
  final int? tabIndex;
  final DrawerItemKind kind;
  final bool accent;
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
  signOut,
  page,
}

abstract final class AppDrawerCatalog {
  static const String menuTooltip = 'Meni';
  static const String home = 'Početna';
  static const String lostDogs = '🚨 Izgubljeni psi';
  static const String adopt = '🏠 Udomi';
  static const String groups = '👥 Grupe';
  static const String events = '📅 Događaji i šetnje';
  static const String moments = '📸 VauVau Moments';
  static const String rules = 'Pravila & Podrška';
  static const String admin = 'Admin Panel';
  static const String profile = '👤 Moj Profil';
  static const String settings = '⚙️ Podešavanja';
  static const String support = 'Podrška';
  static const String about = 'O aplikaciji';
  static const String locationPin = '📍';

  static const List<AppDrawerDestination> primaryItems = [
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
    AppDrawerDestination(
      id: 'rules',
      label: rules,
      icon: Icons.help_outline,
      kind: DrawerItemKind.rules,
    ),
  ];

  /// Rendered only when [isAdminProvider] is true.
  static const AppDrawerDestination adminItem = AppDrawerDestination(
    id: 'admin',
    label: admin,
    icon: Icons.admin_panel_settings,
    kind: DrawerItemKind.admin,
  );

  static const List<AppDrawerDestination> footerItems = [
    AppDrawerDestination(
      id: 'settings',
      label: settings,
      icon: Icons.settings_outlined,
      kind: DrawerItemKind.settings,
    ),
    AppDrawerDestination(
      id: 'signOut',
      label: 'Odjava',
      icon: Icons.logout,
      kind: DrawerItemKind.signOut,
    ),
  ];

  static const List<AppDrawerDestination> items = [
    ...primaryItems,
    ...footerItems,
  ];
}
