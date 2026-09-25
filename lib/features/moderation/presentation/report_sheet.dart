import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content_report.dart';
import 'moderation_strings.dart';
import 'report_controller.dart';

Future<void> showContentReportSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ReportContentType contentType,
  required String targetId,
}) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ModerationStrings.reportTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text(ModerationStrings.reasonInappropriate),
                onTap: () => Navigator.of(sheetContext)
                    .pop(ModerationStrings.reasonInappropriate),
              ),
              ListTile(
                title: const Text(ModerationStrings.reasonSpam),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ModerationStrings.reasonSpam),
              ),
              ListTile(
                title: const Text(ModerationStrings.reasonFake),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ModerationStrings.reasonFake),
              ),
              ListTile(
                title: const Text(ModerationStrings.reasonOther),
                onTap: () => Navigator.of(sheetContext)
                    .pop(ModerationStrings.reasonOther),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (reason == null || !context.mounted) {
    return;
  }
  await ref.read(reportControllerProvider).submit(
        contentType: contentType,
        targetId: targetId,
        reason: reason,
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ModerationStrings.reportThanks)),
    );
  }
}
