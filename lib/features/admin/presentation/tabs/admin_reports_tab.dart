import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_cards.dart';
import '../../../map/domain/models/poi_model.dart';
import '../../../map/presentation/user_poi_controller.dart';
import '../../../moderation/domain/content_report.dart';
import '../../../moderation/presentation/report_controller.dart';
import '../../../moments/presentation/moments_controller.dart';
import '../admin_strings.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_edit_poi_dialog.dart';

class AdminReportsTab extends ConsumerWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(activeReportsProvider);
    if (reports.isEmpty) {
      return Center(child: Text(AdminStrings.emptyReports));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ReportCard(report: reports[index]),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});

  final ContentReport report;

  bool get _isPoi => report.targetType == ReportContentType.poi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final details = report.details;
    final title = report.targetName.trim().isNotEmpty
        ? report.targetName.trim()
        : report.targetId;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardTokens.softShadow(0.08),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AdminStrings.reportedBy(report.reporterId),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AdminStrings.reportedUser(report.reportedUserId),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(),
            ],
          ),
          SizedBox(height: 8),
          Text(
            AdminStrings.timestamp(report.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report.reason,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPoi ? title : '${report.targetTypeKey} • ${report.targetId}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_isPoi && report.targetName.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'ID: ${report.targetId}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_isPoi) ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _editAndResolve(context, ref),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(AdminStrings.editAndResolve),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => _deleteContent(context, ref),
                    child: Text(AdminStrings.reportDeleteContent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => _update(context, ref, reviewed: true),
                    child: Text(AdminStrings.reportMarkReviewed),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _update(context, ref, reviewed: false),
                    child: Text(AdminStrings.reportDismiss),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editAndResolve(BuildContext context, WidgetRef ref) async {
    final existing =
        ref.read(userPoiSubmissionsProvider.notifier).findById(report.targetId);
    final poi = existing ??
        PoiModel(
          id: report.targetId,
          name: report.targetName.trim().isNotEmpty
              ? report.targetName.trim()
              : report.targetId,
          category: PoiCategory.park,
          address: '',
          latitude: 45.2671,
          longitude: 19.8335,
          lastVerified: DateTime.now(),
          source: 'Admin ispravka',
          verificationStatus: PoiVerificationStatus.unknown,
        );

    final result = await showAdminEditPoiDialog(
      context: context,
      ref: ref,
      poi: poi,
      reportReason: report.reason,
      reportDetails: report.details,
      offerResolve: true,
    );

    if (result == AdminEditPoiResult.cancelled || !context.mounted) {
      return;
    }

    if (result == AdminEditPoiResult.savedAndResolved) {
      await ref.read(reportControllerProvider).markReviewed(
            report.id,
            reporterId: report.reporterId,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AdminStrings.poiUpdatedAndResolved),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF166534),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AdminStrings.saved),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF166534),
        ),
      );
    }
  }

  Future<void> _deleteContent(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAdminDelete(
      context,
      message: AdminStrings.confirmDeleteReported,
    );
    if (!confirmed) {
      return;
    }
    try {
      ref.read(hiddenContentProvider.notifier).hide(report.targetId);
      switch (report.targetType) {
        case ReportContentType.poi:
          await ref
              .read(userPoiSubmissionsProvider.notifier)
              .reject(report.targetId);
        case ReportContentType.moment:
          await ref
              .read(momentsControllerProvider.notifier)
              .delete(report.targetId);
        case ReportContentType.user:
        case ReportContentType.message:
        case ReportContentType.dog:
        case ReportContentType.chat:
          break;
      }
      await ref.read(reportControllerProvider).markActionTaken(
            report.id,
            reporterId: report.reporterId,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdminStrings.blocked)),
        );
      }
    } catch (error) {
      debugPrint('Admin delete/report action failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdminStrings.actionFailed)),
        );
      }
    }
  }

  Future<void> _update(
    BuildContext context,
    WidgetRef ref, {
    required bool reviewed,
  }) async {
    final controller = ref.read(reportControllerProvider);
    try {
      if (reviewed) {
        await controller.markReviewed(
          report.id,
          reporterId: report.reporterId,
        );
      } else {
        await controller.dismiss(
          report.id,
          reporterId: report.reporterId,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewed ? AdminStrings.reportReviewed : AdminStrings.dismissed,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF166534),
          ),
        );
      }
    } catch (error) {
      debugPrint('Admin report status update failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdminStrings.actionFailed)),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AdminStrings.reportStatusPending,
        style: TextStyle(
          color: Color(0xFF92400E),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
