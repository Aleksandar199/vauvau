import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_update/presentation/app_update_host.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../chat/presentation/chat_strings.dart';
import '../../chat/presentation/incoming_message_sound.dart';
import '../../chat/presentation/matches_screen.dart';
import '../../chat/presentation/widgets/scheduled_walks_banner.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../discover/presentation/discover_strings.dart';
import '../../discover/presentation/widgets/discover_app_bar.dart';
import '../../groups/presentation/group_unread_alerts.dart';
import '../../lost_dogs/presentation/lost_dog_emergency_host.dart';
import '../../map/presentation/map_screen.dart';
import '../../map/presentation/map_strings.dart';
import '../../moments/presentation/home_feed_screen.dart';
import '../../moments/presentation/moments_strings.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../notifications/presentation/notification_strings.dart';
import '../../notifications/presentation/push_bootstrap.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/presentation/profile_strings.dart';
import '../../profile/presentation/profile_system_sheet.dart';
import '../../profile/presentation/share_profile_sheet.dart';
import '../domain/app_drawer_catalog.dart';
import 'home_drawer.dart';
import 'home_tab.dart';

class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(homeTabIndexProvider);
    final scheduledWalks = ref.watch(scheduledWalksProvider);
    final unread = ref.watch(notificationUnreadCountProvider);
    final unreadChats = ref.watch(totalUnreadChatCountProvider);
    // Rebuild tab labels/copy when the user switches language.
    ref.watch(appSettingsProvider.select((s) => s.language));
    final showScheduledWalks =
        tabIndex == HomeTabIndex.map || tabIndex == HomeTabIndex.messages;
    ref.watch(groupUnreadAlertsProvider);
    ref.watch(incomingMessageSoundProvider);

    final titles = [
      MomentsStrings.homeTab,
      '',
      MapStrings.title,
      ChatStrings.title,
      ProfileStrings.title,
    ];

    return AppUpdateHost(
      child: PushBootstrap(
        child: LostDogEmergencyHost(
          child: Scaffold(
            drawer: const HomeDrawer(),
            appBar: tabIndex == HomeTabIndex.home
                ? const HomeFeedAppBar()
                : tabIndex == HomeTabIndex.discover
                ? const DiscoverAppBar()
                : AppBar(
                    title: Text(titles[tabIndex]),
                    leading: Builder(
                      builder: (context) {
                        return IconButton(
                          tooltip: AppDrawerCatalog.menuTooltip,
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        );
                      },
                    ),
                    actions: [
                      if (tabIndex == HomeTabIndex.profile) ...[
                        IconButton(
                          key: const ValueKey('profile-share'),
                          tooltip: ProfileStrings.shareProfile,
                          onPressed: () => showShareTextSheet(
                            context,
                            title: ProfileStrings.shareProfile,
                            text: profileShareText(
                              ref.read(profileControllerProvider),
                            ),
                          ),
                          icon: const Icon(Icons.share_outlined),
                        ),
                        IconButton(
                          key: const ValueKey('profile-invite'),
                          tooltip: ProfileStrings.inviteFriends,
                          onPressed: () => showShareTextSheet(
                            context,
                            title: ProfileStrings.inviteFriends,
                            text: inviteFriendsText(),
                          ),
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                        ),
                      ],
                      if (tabIndex == HomeTabIndex.profile)
                        IconButton(
                          tooltip: ProfileStrings.moreActions,
                          onPressed: () => showProfileSystemSheet(context, ref),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      IconButton(
                        tooltip: NotificationStrings.tooltip,
                        onPressed: () => showNotificationsSheet(context),
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          backgroundColor: const Color(0xFFE11D48),
                          label: Text('$unread'),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                    ],
                  ),
            body: Column(
              children: [
                if (showScheduledWalks)
                  ScheduledWalksBanner(walks: scheduledWalks),
                Expanded(
                  child: IndexedStack(
                    index: tabIndex,
                    children: const [
                      HomeFeedScreen(),
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
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: MomentsStrings.homeTab,
                ),
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
                  icon: Badge(
                    isLabelVisible: unreadChats > 0,
                    label: Text('$unreadChats'),
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: unreadChats > 0,
                    label: Text('$unreadChats'),
                    child: const Icon(Icons.chat_bubble),
                  ),
                  label: ChatStrings.tabLabel,
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: ProfileStrings.tabLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
