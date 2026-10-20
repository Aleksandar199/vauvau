import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/walk_locations.dart';
import '../domain/chat_time.dart';
import 'chat_strings.dart';
import 'widgets/location_choice_chip.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

Future<void> showScheduleWalkSheet({
  required BuildContext context,
  required void Function(DateTime walkTime, String location) onSend,
}) {
  return showAppBottomSheet<void>(
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
  final _customLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  DateTime get _combined => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

  bool get _isInFuture => _combined.isAfter(DateTime.now());

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _showPastError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ChatStrings.walkTimeInPast)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : media.size.height;
            final sheetHeight = math.min(
              available,
              media.size.height * 0.85,
            );
            return SizedBox(
              height: sheetHeight,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      ChatStrings.walkSheetTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(ChatStrings.walkDate),
                            subtitle: Text(
                              formatWalkStamp(_combined).split(' ').first,
                            ),
                            trailing: TextButton(
                              onPressed: _pickDate,
                              child: Text(ChatStrings.pickDate),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(ChatStrings.walkTime),
                            subtitle: Text(
                              '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                            ),
                            trailing: TextButton(
                              onPressed: _pickTime,
                              child: Text(ChatStrings.pickTime),
                            ),
                          ),
                          SizedBox(height: 8),
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
                                LocationChoiceChip(
                                  label: place,
                                  selected: _location == place &&
                                      _customLocationController.text
                                          .trim()
                                          .isEmpty,
                                  onSelected: (_) => setState(() {
                                    _location = place;
                                    _customLocationController.clear();
                                  }),
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: _customLocationController,
                            decoration: InputDecoration(
                              hintText: ChatStrings.walkCustomLocationHint,
                              filled: true,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              final trimmed = value.trim();
                              if (trimmed.isNotEmpty) {
                                setState(() => _location = trimmed);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(ChatStrings.cancel),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _send,
                            child: Text(ChatStrings.sendInvite),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _send() {
    if (!_isInFuture) {
      _showPastError();
      return;
    }
    widget.onSend(_combined, _location);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(_today) ? _today : _date,
      firstDate: _today,
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked == null || !mounted) {
      return;
    }
    final next = DateTime(
      picked.year,
      picked.month,
      picked.day,
      _time.hour,
      _time.minute,
    );
    if (!next.isAfter(DateTime.now())) {
      _showPastError();
      // Keep the date, but bump time to the next full hour so the form stays valid.
      final bump = DateTime.now().add(const Duration(hours: 1));
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day);
        _time = TimeOfDay(hour: bump.hour, minute: 0);
      });
      return;
    }
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked == null || !mounted) {
      return;
    }
    final next = DateTime(
      _date.year,
      _date.month,
      _date.day,
      picked.hour,
      picked.minute,
    );
    if (!next.isAfter(DateTime.now())) {
      _showPastError();
      return;
    }
    setState(() => _time = picked);
  }
}
