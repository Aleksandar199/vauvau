import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../adoption/presentation/screens/adoption_screen.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/app_drawer_catalog.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pets, size: 36, color: AppColors.primaryDeep),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.ownerName,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    profile.ownerLocation,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final item in AppDrawerCatalog.items)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => item.id == 'adopt'
                          ? const AdoptionScreen()
                          : DrawerSectionScreen(destination: item),
                    ),
                  );
                },
              ),
          ],
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
            const SizedBox(height: 16),
            Text(
              AppDrawerCatalog.comingSoon,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightOnBackground.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
