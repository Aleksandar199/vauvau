import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/dog_reminder.dart';
import 'add_reminder_sheet.dart';
import 'reminder_controller.dart';
import 'reminder_form_sheet.dart';
import 'reminder_strings.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({
    super.key,
    required this.dogs,
    this.initialDogId,
  });

  final List<ReminderDogOption> dogs;
  final String? initialDogId;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  String? _filterDogId;

  @override
  void initState() {
    super.initState();
    _filterDogId = widget.dogs.length > 1 ? null : widget.initialDogId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final entries = _collectEntries();
    final overdue = [
      for (final e in entries)
        if (e.reminder.urgencyAt(now) == ReminderUrgency.overdue) e,
    ];
    final soon = [
      for (final e in entries)
        if (e.reminder.urgencyAt(now) != ReminderUrgency.overdue &&
            e.reminder.urgencyAt(now) != ReminderUrgency.upcoming)
          e,
    ];
    final later = [
      for (final e in entries)
        if (e.reminder.urgencyAt(now) == ReminderUrgency.upcoming) e,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderStrings.remindersTitle),
        actions: [
          TextButton(
            onPressed: () => showAddReminderTypeSheet(
              context: context,
              dogs: widget.dogs,
              preferredDogId: _filterDogId ?? widget.initialDogId,
            ),
            child: const Text(ReminderStrings.addReminder),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.dogs.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Svi'),
                      selected: _filterDogId == null,
                      onSelected: (_) => setState(() => _filterDogId = null),
                    ),
                  ),
                  for (final dog in widget.dogs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(dog.name),
                        selected: _filterDogId == dog.id,
                        onSelected: (_) =>
                            setState(() => _filterDogId = dog.id),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ReminderStrings.emptyTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ReminderStrings.emptyBody,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => showAddReminderTypeSheet(
                              context: context,
                              dogs: widget.dogs,
                              preferredDogId:
                                  _filterDogId ?? widget.initialDogId,
                            ),
                            child: const Text(ReminderStrings.addFirst),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (overdue.isNotEmpty) ...[
                        _GroupHeader(ReminderStrings.groupOverdue),
                        for (final e in overdue)
                          _ReminderTile(
                            reminder: e.reminder,
                            dogName: e.dogName,
                            now: now,
                            showDogName: widget.dogs.length > 1,
                            dogs: widget.dogs,
                          ),
                        const SizedBox(height: 8),
                      ],
                      if (soon.isNotEmpty) ...[
                        _GroupHeader(ReminderStrings.groupSoon),
                        for (final e in soon)
                          _ReminderTile(
                            reminder: e.reminder,
                            dogName: e.dogName,
                            now: now,
                            showDogName: widget.dogs.length > 1,
                            dogs: widget.dogs,
                          ),
                        const SizedBox(height: 8),
                      ],
                      if (later.isNotEmpty) ...[
                        _GroupHeader(ReminderStrings.groupLater),
                        for (final e in later)
                          _ReminderTile(
                            reminder: e.reminder,
                            dogName: e.dogName,
                            now: now,
                            showDogName: widget.dogs.length > 1,
                            dogs: widget.dogs,
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<({DogReminder reminder, String dogName})> _collectEntries() {
    final dogs = _filterDogId == null
        ? widget.dogs
        : [
            for (final dog in widget.dogs)
              if (dog.id == _filterDogId) dog,
          ];
    final merged = <({DogReminder reminder, String dogName})>[];
    for (final dog in dogs) {
      final items = ref.watch(activeDogRemindersProvider(dog.id));
      for (final item in items) {
        merged.add((reminder: item, dogName: dog.name));
      }
    }
    merged.sort((a, b) => a.reminder.date.compareTo(b.reminder.date));
    return merged;
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({
    required this.reminder,
    required this.dogName,
    required this.now,
    required this.showDogName,
    required this.dogs,
  });

  final DogReminder reminder;
  final String dogName;
  final DateTime now;
  final bool showDogName;
  final List<ReminderDogOption> dogs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final urgency = reminder.urgencyAt(now);
    final warn = urgency == ReminderUrgency.overdue ||
        urgency == ReminderUrgency.today;
    final accent = warn ? AppColors.primary : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetails(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showDogName) ...[
                        const SizedBox(height: 2),
                        Text(
                          dogName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        ReminderStrings.date(reminder.date),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ReminderStrings.urgencyLabel(urgency),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ReminderStrings.daysUntil(reminder.date, now),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ReminderStrings.details,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                ReminderStrings.typeLabel(reminder.type),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(reminder.title),
              Text(dogName),
              Text(ReminderStrings.date(reminder.date)),
              Text(ReminderStrings.labelForRepeat(reminder.repeatType)),
              Text(ReminderStrings.offsetLabel(reminder.reminderOffset)),
              if (reminder.note != null && reminder.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(reminder.note!),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await showReminderFormSheet(
                    context: context,
                    dogs: dogs,
                    existing: reminder,
                    preferredDogId: reminder.dogId,
                  );
                },
                child: const Text(ReminderStrings.edit),
              ),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: sheetContext,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text(ReminderStrings.delete),
                      content: const Text(ReminderStrings.deleteConfirm),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text(ReminderStrings.cancel),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text(ReminderStrings.delete),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) {
                    return;
                  }
                  await ref.read(reminderControllerProvider).delete(reminder);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
                child: const Text(ReminderStrings.delete),
              ),
            ],
          ),
        );
      },
    );
  }
}
