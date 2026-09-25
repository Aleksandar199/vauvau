import 'package:flutter/material.dart';

class AppDrawerDestination {
  const AppDrawerDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.body,
  });

  final String id;
  final String label;
  final IconData icon;
  final String body;
}

abstract final class AppDrawerCatalog {
  static const String menuTooltip = 'Meni';
  static const String adopt = 'Udomi';
  static const String rules = 'Pravila i saveti';
  static const String support = 'Podrška';
  static const String comingSoon = 'Ova sekcija uskoro stiže.';

  static const List<AppDrawerDestination> items = [
    AppDrawerDestination(
      id: 'adopt',
      label: adopt,
      icon: Icons.volunteer_activism_outlined,
      body:
          'Pronađite pse koji traže novi dom. Uskoro ćete ovde moći da pregledate oglase za udomljavanje.',
    ),
    AppDrawerDestination(
      id: 'rules',
      label: rules,
      icon: Icons.menu_book_outlined,
      body:
          'Saveti za bezbedne šetnje, druženje pasa i lepo ponašanje u čoporu. Pravila zajednice biće ovde.',
    ),
    AppDrawerDestination(
      id: 'support',
      label: support,
      icon: Icons.support_agent_outlined,
      body:
          'Treba vam pomoć? Ovde ćete naći odgovore i način da kontaktirate VauVau podršku.',
    ),
  ];
}
