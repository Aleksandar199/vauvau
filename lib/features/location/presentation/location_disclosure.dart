import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/location_access.dart';
import 'location_controller.dart';
import 'location_strings.dart';

/// Google Play / App Store prominent disclosure shown **before** the system
/// location permission dialog before walk / nearby-dog location access.
Future<bool> showLocationProminentDisclosure(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final isDark = theme.brightness == Brightness.dark;
      final bodyColor =
          isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocationStrings.disclosureTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocationStrings.disclosureBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyColor,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LocationStrings.disclosureForegroundNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: bodyColor.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocationStrings.disclosureDecline),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(LocationStrings.disclosureContinue),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Shows the in-app disclosure (when needed), then the system permission prompt.
Future<LocationAccess> requestLocationPermissionWithDisclosure({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final client = ref.read(locationClientProvider);
  final current = await client.checkPermission();

  if (current.canTrack) {
    return ref
        .read(userLocationProvider.notifier)
        .refresh(requestPermission: false);
  }

  // System dialog will not appear — skip disclosure.
  if (current == LocationAccess.permanentlyDenied ||
      current == LocationAccess.servicesDisabled ||
      current == LocationAccess.unavailable) {
    return ref.read(userLocationProvider.notifier).requestPermission();
  }

  if (!context.mounted) {
    return current;
  }

  final accepted = await showLocationProminentDisclosure(context);
  if (!accepted) {
    return LocationAccess.denied;
  }
  if (!context.mounted) {
    return LocationAccess.denied;
  }

  return ref.read(userLocationProvider.notifier).requestPermission();
}
