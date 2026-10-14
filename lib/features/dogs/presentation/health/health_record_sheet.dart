import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/health_record.dart';
import 'health_controller.dart';
import 'health_strings.dart';

Future<void> showHealthRecordSheet({
  required BuildContext context,
  required String dogId,
  required String dogName,
  required HealthCategory category,
  HealthRecord? existing,
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
        child: HealthRecordSheet(
          dogId: dogId,
          dogName: dogName,
          category: category,
          existing: existing,
        ),
      );
    },
  );
}

class HealthRecordSheet extends ConsumerStatefulWidget {
  const HealthRecordSheet({
    super.key,
    required this.dogId,
    required this.dogName,
    required this.category,
    this.existing,
  });

  final String dogId;
  final String dogName;
  final HealthCategory category;
  final HealthRecord? existing;

  @override
  ConsumerState<HealthRecordSheet> createState() => _HealthRecordSheetState();
}

class _HealthRecordSheetState extends ConsumerState<HealthRecordSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late DateTime _administered;
  DateTime? _nextDue;
  late bool _reminder;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(
      text: existing?.title ?? HealthStrings.categoryHint(widget.category),
    );
    _notes = TextEditingController(text: existing?.notes ?? '');
    _administered = existing?.administeredDate ?? DateTime.now();
    _nextDue = existing?.nextDueDate;
    _reminder = _nextDue != null;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = _nextDue;
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            HealthStrings.categoryLabel(widget.category),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _title,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: HealthStrings.titleLabel,
            ),
          ),
          SizedBox(height: 8),
          _DateField(
            label: HealthStrings.administeredDate,
            value: _administered,
            enabled: !_saving,
            onPick: (value) => setState(() => _administered = value),
          ),
          _DateField(
            label: HealthStrings.nextDueDate,
            value: due,
            enabled: !_saving,
            onPick: (value) => setState(() {
              _nextDue = value;
              _reminder = true;
            }),
            onClear: due == null
                ? null
                : () => setState(() {
                      _nextDue = null;
                      _reminder = false;
                    }),
          ),
          SwitchListTile(
            value: _reminder && due != null,
            onChanged: _saving || due == null
                ? null
                : (value) => setState(() => _reminder = value),
            title: Text(HealthStrings.reminderToggle),
            subtitle: Text(HealthStrings.reminderHint),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: 8),
          TextField(
            controller: _notes,
            enabled: !_saving,
            maxLines: 3,
            decoration: InputDecoration(labelText: HealthStrings.notes),
          ),
          SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '...' : HealthStrings.save),
          ),
          if (widget.existing != null) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : _delete,
              child: Text(HealthStrings.delete),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final existing = widget.existing;
    final notes = _notes.text.trim();
    final title = _title.text.trim().isEmpty
        ? HealthStrings.categoryHint(widget.category)
        : _title.text.trim();
    setState(() => _saving = true);
    try {
      final result = await ref.read(healthControllerProvider).save(
            record: HealthRecord(
              id: existing?.id ?? '',
              dogId: widget.dogId,
              category: widget.category,
              title: title,
              administeredDate: _administered,
              nextDueDate: _nextDue,
              notes: notes.isEmpty ? null : notes,
              notificationId: existing?.notificationId,
            ),
            dogName: widget.dogName,
            withReminder: _reminder,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      final message = result.reminderSet
          ? '${HealthStrings.saved} ${HealthStrings.reminderSet}'
          : HealthStrings.saved;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(HealthStrings.saveError)),
        );
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    setState(() => _saving = true);
    await ref.read(healthControllerProvider).delete(existing);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final current = value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        current == null ? HealthStrings.noDate : HealthStrings.date(current),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              tooltip: HealthStrings.clearDate,
              onPressed: enabled ? onClear : null,
              icon: const Icon(Icons.clear),
            ),
          IconButton(
            tooltip: label,
            onPressed: enabled ? () => _pick(context) : null,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      onPick(picked);
    }
  }
}
