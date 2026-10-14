import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/dog_reminder.dart';
import '../../domain/health_record.dart';
import 'add_reminder_sheet.dart';
import 'health_card_screen.dart';
import 'health_controller.dart';
import 'health_record_sheet.dart';
import 'reminder_controller.dart';
import 'reminder_strings.dart';
import 'reminders_screen.dart';

/// Compact "Zdravlje i podsetnici" summary shown on the Profile screen.
class DogHealthTab extends ConsumerWidget {
  const DogHealthTab({
    super.key,
    required this.dogId,
    required this.dogName,
    this.dogs = const [],
  });

  final String dogId;
  final String dogName;

  /// All owner dogs — used for multi-dog reminder flows.
  final List<ReminderDogOption> dogs;

  List<ReminderDogOption> get _dogOptions {
    if (dogs.isNotEmpty) {
      return dogs;
    }
    return [(id: dogId, name: dogName)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reminders = ref.watch(activeDogRemindersProvider(dogId));
    final healthAsync = ref.watch(healthRecordsProvider(dogId));
    final healthRecords =
        healthAsync.asData?.value ?? const <HealthRecord>[];
    final now = DateTime.now();
    final upcoming = reminders.take(2).toList();

    final vaccineCount = healthRecords
        .where(
          (r) =>
              r.category == HealthCategory.vaccineRabies ||
              r.category == HealthCategory.vaccineCore,
        )
        .length;
    final protectionCount = healthRecords
        .where(
          (r) =>
              r.category == HealthCategory.deworming ||
              r.category == HealthCategory.tickProtection,
        )
        .length;
    // Reserved bucket for future checkup categories; currently unused.
    const checkupCount = 0;
    final hasHealth = healthRecords.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ReminderStrings.sectionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _HealthSummaryBlock(
              hasHealth: hasHealth,
              vaccineCount: vaccineCount,
              protectionCount: protectionCount,
              checkupCount: checkupCount,
              onOpen: () => _openHealthCard(context),
              onAdd: () => _addHealthRecord(context, ref),
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),
            if (reminders.isEmpty)
              _EmptyRemindersBlock(
                onAdd: () => showAddReminderTypeSheet(
                  context: context,
                  dogs: _dogOptions,
                  preferredDogId: dogId,
                ),
              )
            else ...[
              Text(
                ReminderStrings.nextReminder,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              for (final item in upcoming)
                _CompactReminderRow(reminder: item, now: now),
              SizedBox(height: 6),
              Text(
                ReminderStrings.activeCount(reminders.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => showAddReminderTypeSheet(
                        context: context,
                        dogs: _dogOptions,
                        preferredDogId: dogId,
                      ),
                      child: Text(ReminderStrings.addReminder),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _openReminders(context),
                      child: Text(ReminderStrings.showAll),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openHealthCard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HealthCardScreen(dogId: dogId, dogName: dogName),
      ),
    );
  }

  void _openReminders(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RemindersScreen(
          dogs: _dogOptions,
          initialDogId: dogId,
        ),
      ),
    );
  }

  Future<void> _addHealthRecord(BuildContext context, WidgetRef ref) async {
    final latest = ref.read(latestHealthRecordsProvider(dogId));
    final category = await showModalBottomSheet<HealthCategory>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final category in HealthCategory.values)
                ListTile(
                  title: Text(
                    switch (category) {
                      HealthCategory.vaccineRabies => '💉 Besnilo',
                      HealthCategory.vaccineCore => '🛡️ Zarazne bolesti',
                      HealthCategory.deworming => '🪱 Unutrašnji paraziti',
                      HealthCategory.tickProtection => '🦠 Krpelji i buve',
                    },
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(category),
                ),
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

class _HealthSummaryBlock extends StatelessWidget {
  const _HealthSummaryBlock({
    required this.hasHealth,
    required this.vaccineCount,
    required this.protectionCount,
    required this.checkupCount,
    required this.onOpen,
    required this.onAdd,
  });

  final bool hasHealth;
  final int vaccineCount;
  final int protectionCount;
  final int checkupCount;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ReminderStrings.healthCardTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        if (!hasHealth) ...[
          Text(
            ReminderStrings.healthCardEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onAdd,
              child: Text(ReminderStrings.addHealthRecord),
            ),
          ),
        ] else ...[
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _CountChip(
                label: ReminderStrings.vaccines,
                count: vaccineCount,
              ),
              _CountChip(
                label: ReminderStrings.protection,
                count: protectionCount,
              ),
              if (checkupCount > 0)
                _CountChip(
                  label: ReminderStrings.checkups,
                  count: checkupCount,
                ),
            ],
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpen,
              child: Text(ReminderStrings.openHealthCard),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          TextSpan(
            text: ReminderStrings.recordCount(count),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRemindersBlock extends StatelessWidget {
  const _EmptyRemindersBlock({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          ReminderStrings.emptyTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Text(
          ReminderStrings.emptyBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 14),
        FilledButton(
          onPressed: onAdd,
          child: Text(ReminderStrings.addFirst),
        ),
      ],
    );
  }
}

class _CompactReminderRow extends StatelessWidget {
  const _CompactReminderRow({
    required this.reminder,
    required this.now,
  });

  final DogReminder reminder;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgency = reminder.urgencyAt(now);
    final warn = urgency == ReminderUrgency.overdue ||
        urgency == ReminderUrgency.today;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.type == ReminderType.custom
                      ? '✏️ ${reminder.title}'
                      : ReminderStrings.typeShortLabel(reminder.type),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  ReminderStrings.date(reminder.date),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (warn)
            Text(
              ReminderStrings.urgencyLabel(urgency),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
