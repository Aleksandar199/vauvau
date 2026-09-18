import 'package:flutter/material.dart';

import '../data/walk_locations.dart';
import '../domain/chat_time.dart';
import 'chat_strings.dart';

Future<void> showScheduleWalkSheet({
  required BuildContext context,
  required void Function(DateTime walkTime, String location) onSend,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return ScheduleWalkBottomSheet(onSend: onSend);
    },
  );
}

class ScheduleWalkBottomSheet extends StatefulWidget {
  const ScheduleWalkBottomSheet({super.key, required this.onSend});

  final void Function(DateTime walkTime, String location) onSend;

  @override
  State<ScheduleWalkBottomSheet> createState() =>
      _ScheduleWalkBottomSheetState();
}

class _ScheduleWalkBottomSheetState extends State<ScheduleWalkBottomSheet> {
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  String _location = scheduledWalkLocations.first;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  DateTime get _combined => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ChatStrings.walkSheetTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(ChatStrings.walkDate),
            subtitle: Text(formatWalkStamp(_combined).split(' ').first),
            trailing: TextButton(
              onPressed: _pickDate,
              child: const Text(ChatStrings.pickDate),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(ChatStrings.walkTime),
            subtitle: Text(
              '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
            ),
            trailing: TextButton(
              onPressed: _pickTime,
              child: const Text(ChatStrings.pickTime),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ChatStrings.walkLocation,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final place in scheduledWalkLocations)
                ChoiceChip(
                  label: Text(place),
                  selected: _location == place,
                  onSelected: (_) => setState(() => _location = place),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(ChatStrings.cancel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  widget.onSend(_combined, _location);
                  Navigator.of(context).pop();
                },
                child: const Text(ChatStrings.sendInvite),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }
}
