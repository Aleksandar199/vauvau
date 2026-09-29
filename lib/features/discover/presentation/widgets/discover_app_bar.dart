import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../home/domain/app_drawer_catalog.dart';
import '../../../notifications/presentation/notification_controller.dart';
import '../../../notifications/presentation/notification_screen.dart';
import '../../../notifications/presentation/notification_strings.dart';
import '../discover_strings.dart';
import 'discover_filters_bottom_sheet.dart';
import 'discover_search_sheet.dart';

class DiscoverAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DiscoverAppBar({super.key, this.showNotifications = true});

  final bool showNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = showNotifications
        ? ref.watch(notificationUnreadCountProvider)
        : 0;

    return AppBar(
      centerTitle: true,
      leading: Builder(
        builder: (context) {
          return IconButton(
            tooltip: AppDrawerCatalog.menuTooltip,
            icon: const Icon(Icons.menu),
            onPressed: () {
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold != null && scaffold.hasDrawer) {
                scaffold.openDrawer();
              }
            },
          );
        },
      ),
      title: Text(
        AppStrings.appName,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
      ),
      actions: [
        IconButton(
          tooltip: DiscoverStrings.search,
          icon: const Icon(Icons.search),
          onPressed: () => showDiscoverSearchSheet(context),
        ),
        IconButton(
          tooltip: DiscoverStrings.filters,
          icon: const Icon(Icons.tune),
          onPressed: () => showDiscoverFiltersSheet(context),
        ),
        if (showNotifications)
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
    );
  }
}
