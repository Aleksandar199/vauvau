import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../chat/presentation/chat_strings.dart';
import '../../chat/presentation/matches_screen.dart';
import '../../chat/presentation/widgets/scheduled_walks_banner.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../discover/presentation/discover_strings.dart';
import '../../map/presentation/map_screen.dart';
import '../../map/presentation/map_strings.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../notifications/presentation/notification_strings.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/presentation/profile_strings.dart';
import 'home_tab.dart';

class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSigningOut = ref.watch(authControllerProvider).isLoading;
    final tabIndex = ref.watch(homeTabIndexProvider);
    final scheduledWalks = ref.watch(scheduledWalksProvider);
    final unread = ref.watch(notificationUnreadCountProvider);

    final titles = [
      DiscoverStrings.title,
      MapStrings.title,
      ChatStrings.title,
      ProfileStrings.title,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tabIndex]),
        actions: [
          IconButton(
            tooltip: NotificationStrings.tooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          if (tabIndex != 3)
            TextButton(
              onPressed: isSigningOut
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              child: const Text(DiscoverStrings.signOut),
            ),
        ],
      ),
      body: Column(
        children: [
          ScheduledWalksBanner(walks: scheduledWalks),
          Expanded(
            child: IndexedStack(
              index: tabIndex,
              children: const [
                DiscoverScreen(),
                MapScreen(),
                MatchesScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) {
          ref.read(homeTabIndexProvider.notifier).setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: DiscoverStrings.title,
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: MapStrings.tabLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: ChatStrings.tabLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: ProfileStrings.tabLabel,
          ),
        ],
      ),
    );
  }
}
