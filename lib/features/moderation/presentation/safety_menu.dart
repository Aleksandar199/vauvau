import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/content_report.dart';
import 'block_controller.dart';
import 'moderation_strings.dart';
import 'report_sheet.dart';

enum SafetyAction { report, block }

/// Overflow menu shared by every surface that shows somebody else's profile.
class SafetyMenuButton extends ConsumerWidget {
  const SafetyMenuButton({
    super.key,
    required this.reportedUserId,
    required this.targetId,
    this.targetType = ReportContentType.user,
    this.onBlocked,
    this.iconColor,
  });

  final String reportedUserId;
  final String targetId;
  final ReportContentType targetType;

  /// Called after a successful block so the host screen or sheet can close.
  final VoidCallback? onBlocked;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<SafetyAction>(
      icon: Icon(Icons.more_vert, color: iconColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SafetyAction.report,
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 10),
              Text(
                ModerationStrings.reportUser,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: SafetyAction.block,
          child: Row(
            children: [
              Icon(Icons.block, size: 18, color: AppColors.ink),
              SizedBox(width: 10),
              Text(
                ModerationStrings.blockUser,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    SafetyAction action,
  ) async {
    switch (action) {
      case SafetyAction.report:
        await showContentReportSheet(
          context: context,
          ref: ref,
          targetType: targetType,
          targetId: targetId,
          reportedUserId: reportedUserId,
        );
      case SafetyAction.block:
        final blocked = await confirmAndBlockUser(
          context: context,
          ref: ref,
          userId: reportedUserId,
        );
        if (blocked) {
          onBlocked?.call();
        }
    }
  }
}

Future<bool> confirmAndBlockUser({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
}) async {
  if (userId.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ModerationStrings.blockUnavailable)),
    );
    return false;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(ModerationStrings.blockTitle),
        content: const Text(ModerationStrings.blockBody),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text(ModerationStrings.blockConfirm),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(ModerationStrings.cancel),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  if (confirmed != true) {
    return false;
  }
  try {
    await ref.read(blockControllerProvider).block(userId.trim());
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ModerationStrings.blockFailed)),
      );
    }
    return false;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ModerationStrings.blockDone)),
    );
  }
  return true;
}
