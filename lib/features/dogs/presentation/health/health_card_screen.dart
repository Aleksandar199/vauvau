import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/health_record.dart';
import 'health_controller.dart';
import 'health_record_sheet.dart';
import 'health_strings.dart';
import 'reminder_strings.dart';

/// Full health card for one dog — only shows categories that have records,
/// plus a clear way to add a new medical entry.
class HealthCardScreen extends ConsumerWidget {
  const HealthCardScreen({
    super.key,
    required this.dogId,
    required this.dogName,
  });

  final String dogId;
  final String dogName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final latest = ref.watch(latestHealthRecordsProvider(dogId));
    final now = DateTime.now();
    final categoriesWithData = [
      for (final category in HealthCategory.values)
        if (latest.containsKey(category)) category,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(ReminderStrings.healthCardScreenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            HealthStrings.sectionIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 16),
          if (categoriesWithData.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Text(
                    ReminderStrings.healthCardEmpty,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _pickCategoryAndAdd(context, latest),
                    child: Text(ReminderStrings.addHealthRecord),
                  ),
                ],
              ),
            )
          else ...[
            for (final category in categoriesWithData)
              _HealthRecordTile(
                category: category,
                record: latest[category]!,
                now: now,
                onTap: () => showHealthRecordSheet(
                  context: context,
                  dogId: dogId,
                  dogName: dogName,
                  category: category,
                  existing: latest[category],
                ),
              ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickCategoryAndAdd(context, latest),
              icon: const Icon(Icons.add),
              label: Text(ReminderStrings.addHealthRecord),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickCategoryAndAdd(
    BuildContext context,
    Map<HealthCategory, HealthRecord> latest,
  ) async {
    final category = await showModalBottomSheet<HealthCategory>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ReminderStrings.addHealthRecord,
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              for (final category in HealthCategory.values)
                ListTile(
                  title: Text(HealthStrings.categoryLabel(category)),
                  subtitle: latest.containsKey(category)
                      ? Text(HealthStrings.addOrUpdate)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(category),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (category == null || !context.mounted) {
      return;
    }
    await showHealthRecordSheet(
      context: context,
      dogId: dogId,
      dogName: dogName,
      category: category,
      existing: latest[category],
    );
  }
}

class _HealthRecordTile extends StatelessWidget {
  const _HealthRecordTile({
    required this.category,
    required this.record,
    required this.now,
    required this.onTap,
  });

  final HealthCategory category;
  final HealthRecord record;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = record.statusAt(now);
    final color = switch (status) {
      HealthStatus.valid => AppColors.success,
      HealthStatus.expiringSoon => AppColors.cafe,
      HealthStatus.expired => const Color(0xFFDC2626),
      HealthStatus.unknown => const Color(0xFF64748B),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        HealthStrings.categoryLabel(category),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      HealthStrings.statusLabel(status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(record.title),
                Text(
                  '${HealthStrings.lastDate}: '
                  '${HealthStrings.date(record.administeredDate)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (record.nextDueDate != null)
                  Text(
                    '${HealthStrings.nextDate}: '
                    '${HealthStrings.date(record.nextDueDate!)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
