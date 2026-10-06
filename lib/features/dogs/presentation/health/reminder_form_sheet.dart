import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dog_reminder.dart';
import 'add_reminder_sheet.dart';
import 'reminder_controller.dart';
import 'reminder_strings.dart';

Future<void> showReminderFormSheet({
  required BuildContext context,
  required List<ReminderDogOption> dogs,
  ReminderType type = ReminderType.custom,
  DogReminder? existing,
  String? preferredDogId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ReminderFormSheet(
          dogs: dogs,
          type: existing?.type ?? type,
          existing: existing,
          preferredDogId: preferredDogId,
        ),
      );
    },
  );
}

class ReminderFormSheet extends ConsumerStatefulWidget {
  const ReminderFormSheet({
    super.key,
    required this.dogs,
    required this.type,
    this.existing,
    this.preferredDogId,
  });

  final List<ReminderDogOption> dogs;
  final ReminderType type;
  final DogReminder? existing;
  final String? preferredDogId;

  @override
  ConsumerState<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<ReminderFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _customCount;
  late String _dogId;
  late DateTime _date;
  late ReminderRepeat _repeat;
  late ReminderOffset _offset;
  late CustomRepeatUnit _customUnit;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(
      text: existing?.title ?? ReminderStrings.defaultTitle(widget.type),
    );
    _note = TextEditingController(text: existing?.note ?? '');
    _customCount = TextEditingController(
      text:
          '${existing?.customIntervalCount ?? DogReminder.defaultCustomIntervalCount}',
    );
    _customUnit =
        existing?.customIntervalUnit ?? DogReminder.defaultCustomIntervalUnit;
    _date = existing?.date ?? DateTime.now().add(const Duration(days: 30));
    _repeat = existing?.repeatType ?? ReminderRepeat.once;
    _offset = existing?.reminderOffset ?? ReminderOffset.threeDaysBefore;
    _dogId = existing?.dogId ??
        widget.preferredDogId ??
        (widget.dogs.isNotEmpty ? widget.dogs.first.id : '');
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _customCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multiDog = widget.dogs.length > 1;
    final isCustomType = widget.type == ReminderType.custom;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            widget.existing == null
                ? ReminderStrings.typeLabel(widget.type)
                : ReminderStrings.edit,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (multiDog) ...[
            Text(
              ReminderStrings.forWhichDog,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _dogId,
              items: [
                for (final dog in widget.dogs)
                  DropdownMenuItem(value: dog.id, child: Text(dog.name)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _dogId = value);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: ReminderStrings.titleLabel,
              hintText: isCustomType ? ReminderStrings.noteHint : null,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ReminderStrings.dateLabel),
            subtitle: Text(
              '${ReminderStrings.date(_date)}\n${ReminderStrings.dateHint}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          Text(
            ReminderStrings.repeatFieldLabel,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            ReminderStrings.repeatHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<ReminderRepeat>(
            initialValue: _repeat,
            items: [
              for (final item in ReminderRepeat.values)
                DropdownMenuItem(
                  value: item,
                  child: Text(ReminderStrings.labelForRepeat(item)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _repeat = value);
              }
            },
          ),
          if (_repeat == ReminderRepeat.custom) ...[
            const SizedBox(height: 12),
            Text(
              ReminderStrings.customIntervalLabel,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              ReminderStrings.customIntervalHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: TextField(
                    controller: _customCount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Broj',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<CustomRepeatUnit>(
                    initialValue: _customUnit,
                    decoration: const InputDecoration(
                      labelText: 'Jedinica',
                    ),
                    items: [
                      for (final unit in CustomRepeatUnit.values)
                        DropdownMenuItem(
                          value: unit,
                          child: Text(ReminderStrings.labelForCustomUnit(unit)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _customUnit = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            ReminderStrings.remindMeLabel,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            ReminderStrings.remindMeHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<ReminderOffset>(
            initialValue: _offset,
            items: [
              for (final item in ReminderOffset.values)
                DropdownMenuItem(
                  value: item,
                  child: Text(ReminderStrings.offsetLabel(item)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _offset = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: ReminderStrings.noteLabel,
              hintText: ReminderStrings.noteHint,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? '...' : ReminderStrings.save,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _dogId.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final existing = widget.existing;
      final note = _note.text.trim();
      final parsedCount = int.tryParse(_customCount.text.trim());
      final customCount = (parsedCount != null && parsedCount > 0)
          ? parsedCount
          : DogReminder.defaultCustomIntervalCount;
      await ref.read(reminderControllerProvider).save(
            reminder: DogReminder(
              id: existing?.id ?? '',
              dogId: _dogId,
              title: title,
              type: widget.type,
              date: _date,
              repeatType: _repeat,
              reminderOffset: _offset,
              note: note.isEmpty ? null : note,
              isCompleted: existing?.isCompleted ?? false,
              notificationId: existing?.notificationId,
              customIntervalCount: customCount,
              customIntervalUnit: _customUnit,
              createdAt: existing?.createdAt,
            ),
            dogName: widget.dogs
                .firstWhere(
                  (d) => d.id == _dogId,
                  orElse: () => (id: _dogId, name: ''),
                )
                .name,
          );
      if (!mounted) {
        return;
      }
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text(ReminderStrings.saved)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text(ReminderStrings.saveError)),
      );
    }
  }
}
