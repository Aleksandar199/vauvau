import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content_report.dart';
import 'moderation_strings.dart';
import 'report_controller.dart';

Future<bool> showContentReportSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ReportContentType targetType,
  required String targetId,
  String reportedUserId = '',
  List<String>? reasons,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _ReportSheet(
          targetType: targetType,
          targetId: targetId,
          reportedUserId: reportedUserId,
          reasons: reasons ??
              (targetType == ReportContentType.dog
                  ? ModerationStrings.dogReasons
                  : ModerationStrings.reasons),
        ),
      );
    },
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ModerationStrings.reportThanks)),
    );
  }
  return sent ?? false;
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.targetType,
    required this.targetId,
    required this.reportedUserId,
    required this.reasons,
  });

  final ReportContentType targetType;
  final String targetId;
  final String reportedUserId;
  final List<String> reasons;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  late String _reason = widget.reasons.first;
  var _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ModerationStrings.reportTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            ModerationStrings.reportIntro,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: _sending
                ? (_) {}
                : (value) {
                    if (value != null) {
                      setState(() => _reason = value);
                    }
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final reason in widget.reasons)
                  RadioListTile<String>(
                    value: reason,
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _details,
            enabled: !_sending,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: ModerationStrings.reportDetails,
              hintText: ModerationStrings.reportDetailsHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(shape: buttonShape),
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(ModerationStrings.reportConfirm),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(shape: buttonShape),
              onPressed:
                  _sending ? null : () => Navigator.of(context).pop(false),
              child: const Text(ModerationStrings.cancel),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await ref.read(reportControllerProvider).submit(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: _reason,
            reportedUserId: widget.reportedUserId,
            details: _details.text,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ModerationStrings.reportFailed)),
      );
    }
  }
}
