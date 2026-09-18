import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import 'matching_filters_sheet.dart';
import 'profile_controller.dart';
import 'profile_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isSigningOut = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(ProfileStrings.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            ProfileStrings.notifications,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile(
            title: const Text(ProfileStrings.notifyWalks),
            value: settings.notifyWalkRequests,
            onChanged: (value) => ref.read(appSettingsProvider.notifier).update(
                  settings.copyWith(notifyWalkRequests: value),
                ),
          ),
          SwitchListTile(
            title: const Text(ProfileStrings.notifyMessages),
            value: settings.notifyMessages,
            onChanged: (value) => ref.read(appSettingsProvider.notifier).update(
                  settings.copyWith(notifyMessages: value),
                ),
          ),
          SwitchListTile(
            title: const Text(ProfileStrings.notifyMatches),
            value: settings.notifyNewMatches,
            onChanged: (value) => ref.read(appSettingsProvider.notifier).update(
                  settings.copyWith(notifyNewMatches: value),
                ),
          ),
          const Divider(),
          Text(
            ProfileStrings.radiusFilter,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            min: 1,
            max: 20,
            divisions: 19,
            label: ProfileStrings.radiusValue(settings.radiusKm),
            value: settings.radiusKm.clamp(1, 20),
            onChanged: (value) => ref.read(appSettingsProvider.notifier).update(
                  settings.copyWith(radiusKm: value),
                ),
          ),
          Text(ProfileStrings.radiusValue(settings.radiusKm)),
          SwitchListTile(
            title: const Text(ProfileStrings.showLocation),
            value: settings.showLocationOnMap,
            onChanged: (value) => ref.read(appSettingsProvider.notifier).update(
                  settings.copyWith(showLocationOnMap: value),
                ),
          ),
          ListTile(
            title: const Text(ProfileStrings.searchFilters),
            trailing: const Icon(Icons.tune),
            onTap: () => showMatchingFiltersSheet(context),
          ),
          const Divider(),
          Text(
            ProfileStrings.account,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListTile(
            title: const Text(ProfileStrings.signOut),
            onTap: isSigningOut
                ? null
                : () => _confirmSignOut(context, ref),
          ),
          ListTile(
            title: const Text(
              ProfileStrings.deleteAccount,
              style: TextStyle(color: Color(0xFFB91C1C)),
            ),
            onTap: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              ProfileStrings.appVersion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightOnBackground.withValues(alpha: 0.6),
                  ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(ProfileStrings.signOutTitle),
          content: const Text(ProfileStrings.signOutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(ProfileStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(ProfileStrings.signOut),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(ProfileStrings.deleteAccountTitle),
          content: const Text(ProfileStrings.deleteAccountBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(ProfileStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(ProfileStrings.deleteConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}
