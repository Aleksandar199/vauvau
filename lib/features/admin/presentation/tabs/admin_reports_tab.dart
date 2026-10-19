import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_cards.dart';
import '../../../map/domain/models/poi_model.dart';
import '../../../map/presentation/user_poi_controller.dart';
import '../../../moderation/domain/content_report.dart';
import '../../../moderation/presentation/report_controller.dart';
import '../../../moments/presentation/moments_controller.dart';
import '../admin_controller.dart';
import '../admin_strings.dart';
import '../screens/admin_user_detail_screen.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_edit_poi_dialog.dart';
import '../widgets/admin_ref_widgets.dart';
import '../widgets/admin_user_actions.dart';

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
      itemBuilder: (context, index) => AdminReportCard(report: reports[index]),
    );
  }
}

void openAdminUser(BuildContext context, String uid) {
  if (uid.trim().isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AdminUserDetailScreen(uid: uid)),
  );
}

class AdminReportCard extends ConsumerWidget {
  const AdminReportCard({super.key, required this.report, this.compact = false});

  final ContentReport report;

  /// In the user detail screen: no "open user" links.
  final bool compact;

  bool get _isPoi => report.targetType == ReportContentType.poi;

  /// Whose account the report is about (for suspension).
  String get _accusedUid {
    if (report.reportedUserId.trim().isNotEmpty) return report.reportedUserId;
    if (report.targetType == ReportContentType.user) return report.targetId;
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final details = report.details;
    final accused = _accusedUid;
    final muted = TextStyle(fontSize: 13, color: Colors.grey.shade700);

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
                    AdminUserLabel(
                      uid: report.reporterId,
                      prefix: AdminStrings.reporterLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      onTap: compact
                          ? null
                          : () => openAdminUser(context, report.reporterId),
                    ),
                    if (accused.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AdminUserLabel(
                        uid: accused,
                        prefix: AdminStrings.reportedUserLabel,
                        style: muted,
                        onTap: compact
                            ? null
                            : () => openAdminUser(context, accused),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(status: report.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AdminStrings.timestamp(report.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(
                label: AdminStrings.targetKind(report.targetType),
                color: theme.colorScheme.primary,
              ),
              _Chip(label: report.reason, color: const Color(0xFF92400E)),
            ],
          ),
          const SizedBox(height: 8),
          _ReportTarget(report: report),
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(details, style: muted),
          ],
          if (report.isActive) ...[
            const SizedBox(height: 12),
            _actions(context, ref, accused),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, WidgetRef ref, String accused) {
    final red = FilledButton.styleFrom(
      backgroundColor: const Color(0xFFB91C1C),
      foregroundColor: Colors.white,
      visualDensity: VisualDensity.compact,
    );
    final deleteLabel = switch (report.targetType) {
      ReportContentType.poi => AdminStrings.rejectPlace,
      ReportContentType.moment => AdminStrings.deleteMomentShort,
      ReportContentType.dog => AdminStrings.deleteDog,
      ReportContentType.message =>
        report.contextId.isEmpty ? null : AdminStrings.deleteMessage,
      ReportContentType.user || ReportContentType.chat => null,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_isPoi)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _editAndResolve(context, ref),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(AdminStrings.editAndResolve),
          ),
        if (deleteLabel != null)
          FilledButton(
            style: red,
            onPressed: () => _deleteContent(context, ref),
            child: Text(deleteLabel),
          ),
        if (accused.isNotEmpty)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () async {
              final done = await suspendUserFlow(context, ref, accused);
              if (done && context.mounted) {
                await ref.read(reportControllerProvider).markActionTaken(
                      report.id,
                      reporterId: report.reporterId,
                    );
              }
            },
            icon: const Icon(Icons.block, size: 18),
            label: Text(AdminStrings.suspendUser),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF15803D),
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => _update(context, ref, reviewed: true),
          child: Text(AdminStrings.reportMarkReviewed),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => _update(context, ref, reviewed: false),
          child: Text(AdminStrings.reportDismiss),
        ),
      ],
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
    final message = switch (report.targetType) {
      ReportContentType.dog => AdminStrings.confirmDeleteDog,
      ReportContentType.message => AdminStrings.confirmDeleteMessage,
      ReportContentType.moment => AdminStrings.confirmDeleteMoment,
      _ => AdminStrings.confirmDeleteReported,
    };
    final confirmed = await confirmAdminDelete(context, message: message);
    if (!confirmed || !context.mounted) {
      return;
    }
    final admin = ref.read(adminRepositoryProvider);
    try {
      switch (report.targetType) {
        case ReportContentType.poi:
          await ref
              .read(userPoiSubmissionsProvider.notifier)
              .reject(report.targetId);
        case ReportContentType.moment:
          await ref
              .read(momentsControllerProvider.notifier)
              .delete(report.targetId);
          ref.invalidate(adminMomentRefProvider(report.targetId));
        case ReportContentType.dog:
          await admin.deleteDog(report.targetId);
          ref.read(adminDogLoaderProvider).invalidate(report.targetId);
          ref.invalidate(adminDogRefProvider(report.targetId));
        case ReportContentType.message:
          await admin.deleteChatMessage(report.contextId, report.targetId);
        case ReportContentType.user:
        case ReportContentType.chat:
          return;
      }
      ref.read(hiddenContentProvider.notifier).hide(report.targetId);
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

/// What was reported: dog / moment / message preview instead of the raw id.
class _ReportTarget extends ConsumerWidget {
  const _ReportTarget({required this.report});

  final ContentReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = report.targetName.trim();
    switch (report.targetType) {
      case ReportContentType.poi:
        return AdminTargetPreview(
          icon: Icons.place_outlined,
          title: snapshot.isNotEmpty ? snapshot : AdminStrings.targetKind(report.targetType),
        );
      case ReportContentType.dog:
        final dog = ref.watch(adminDogRefProvider(report.targetId)).value;
        if (dog == null) return const LinearProgressIndicator(minHeight: 2);
        return AdminTargetPreview(
          icon: Icons.pets,
          title: dog.exists ? dog.name : AdminStrings.missingDog,
          subtitle: dog.breed,
          imageUrl: dog.photoUrl,
          missing: !dog.exists,
        );
      case ReportContentType.moment:
        final moment = ref.watch(adminMomentRefProvider(report.targetId)).value;
        if (moment == null) return const LinearProgressIndicator(minHeight: 2);
        return AdminTargetPreview(
          icon: Icons.photo_outlined,
          title: moment.exists
              ? (moment.dogName.isEmpty
                  ? AdminStrings.targetKind(report.targetType)
                  : moment.dogName)
              : AdminStrings.missingMoment,
          subtitle: moment.caption,
          imageUrl: moment.photoUrl,
          missing: !moment.exists,
        );
      case ReportContentType.message:
        if (report.contextId.isEmpty) {
          return AdminTargetPreview(
            icon: Icons.chat_bubble_outline,
            title: snapshot.isNotEmpty
                ? AdminStrings.reportSnapshot(snapshot)
                : AdminStrings.missingMessage,
            missing: snapshot.isEmpty,
          );
        }
        final message = ref
            .watch(
              adminMessageRefProvider((
                chatId: report.contextId,
                messageId: report.targetId,
              )),
            )
            .value;
        if (message == null) return const LinearProgressIndicator(minHeight: 2);
        final text = message.text.isNotEmpty
            ? message.text
            : (message.imageUrl.isNotEmpty ? AdminStrings.imageMessage : '');
        return AdminTargetPreview(
          icon: Icons.chat_bubble_outline,
          title: message.exists && text.isNotEmpty
              ? '„$text“'
              : (snapshot.isNotEmpty
                  ? AdminStrings.reportSnapshot(snapshot)
                  : AdminStrings.missingMessage),
          imageUrl: message.imageUrl,
          missing: !message.exists && snapshot.isEmpty,
        );
      case ReportContentType.user:
      case ReportContentType.chat:
        return const SizedBox.shrink();
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final pending = status == ReportStatus.pending;
    final color = pending ? const Color(0xFF92400E) : const Color(0xFF15803D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AdminStrings.reportStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
