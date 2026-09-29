import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/health_record.dart';
import 'health_controller.dart';
import 'health_record_sheet.dart';
import 'health_strings.dart';

/// "Karton zdravlja & Podsetnici" section shown inside the dog profile.
class DogHealthTab extends ConsumerWidget {
  const DogHealthTab({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              HealthStrings.sectionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(HealthStrings.sectionIntro, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final category in HealthCategory.values)
              _HealthStatusCard(
                category: category,
                record: latest[category],
                now: now,
                onTap: () => showHealthRecordSheet(
                  context: context,
                  dogId: dogId,
                  dogName: dogName,
                  category: category,
                  existing: latest[category],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HealthStatusCard extends StatelessWidget {
  const _HealthStatusCard({
    required this.category,
    required this.record,
    required this.now,
    required this.onTap,
  });

  final HealthCategory category;
  final HealthRecord? record;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = record;
    final status = entry?.statusAt(now) ?? HealthStatus.unknown;
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 6),
                if (entry == null)
                  Text(
                    HealthStrings.noRecord,
                    style: theme.textTheme.bodySmall,
                  )
                else ...[
                  Text(entry.title),
                  Text(
                    '${HealthStrings.lastDate}: '
                    '${HealthStrings.date(entry.administeredDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (entry.nextDueDate != null)
                    Text(
                      '${HealthStrings.nextDate}: '
                      '${HealthStrings.date(entry.nextDueDate!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (entry.notificationId != null)
                    Text(
                      HealthStrings.reminderBadge,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    HealthStrings.addOrUpdate,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(HealthStatus status) {
    return switch (status) {
      HealthStatus.valid => const Color(0xFF16A34A),
      HealthStatus.expiringSoon => const Color(0xFFF59E0B),
      HealthStatus.expired => const Color(0xFFDC2626),
      HealthStatus.unknown => const Color(0xFF64748B),
    };
  }
}
