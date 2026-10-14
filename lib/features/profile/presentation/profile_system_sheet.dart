import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../auth/presentation/auth_providers.dart';
import 'delete_account_action.dart';
import 'profile_strings.dart';
import 'settings_screen.dart';
import 'sign_out_action.dart';

/// Systemic profile actions: settings, admin (if allowed), sign out.
Future<void> showProfileSystemSheet(BuildContext context, WidgetRef ref) {
  final isAdmin = ref.read(isAdminProvider);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(ProfileStrings.settings),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              if (isAdmin)
                ListTile(
                  leading: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Row(
                    children: [
                      Text(ProfileStrings.adminPanel),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          ProfileStrings.adminBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade700),
                title: Text(
                  ProfileStrings.signOut,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  confirmAndSignOut(context, ref);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.red.shade700,
                ),
                title: Text(
                  ProfileStrings.deleteAccount,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  confirmAndDeleteAccount(context, ref);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
