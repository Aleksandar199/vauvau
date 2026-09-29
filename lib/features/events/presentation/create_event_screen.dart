import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/seed_events.dart';
import 'events_controller.dart';
import 'events_strings.dart';

Future<void> showCreateEventSheet(BuildContext context) {
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
        child: const CreateEventScreen(),
      );
    },
  );
}

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _customLocation = TextEditingController();
  String _preset = EventVenues.names.first;
  DateTime _when = DateTime.now().add(const Duration(days: 1));
  XFile? _photo;
  var _saving = false;

  bool get _isCustom => EventVenues.isCustom(_preset);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _customLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              EventsStrings.createTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: EventsStrings.fieldTitle,
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? EventsStrings.titleRequired
                      : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _preset,
              decoration: const InputDecoration(
                labelText: EventsStrings.fieldLocation,
              ),
              items: [
                for (final name in EventVenues.names)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _preset = value);
                }
              },
            ),
            if (_isCustom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customLocation,
                decoration: const InputDecoration(
                  hintText: EventsStrings.customLocationHint,
                  labelText: EventsStrings.customLocationHint,
                ),
                validator: (value) {
                  if (!_isCustom) {
                    return null;
                  }
                  return (value == null || value.trim().isEmpty)
                      ? EventsStrings.customLocationRequired
                      : null;
                },
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(EventsStrings.fieldWhen),
              subtitle: Text(EventsStrings.when(_when)),
              trailing: const Icon(Icons.event),
              onTap: _pickWhen,
            ),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: EventsStrings.fieldDescription,
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? EventsStrings.descriptionRequired
                      : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickPhoto,
              icon: const Icon(Icons.photo_outlined),
              label: Text(
                _photo == null
                    ? EventsStrings.addPhoto
                    : EventsStrings.fieldPhoto,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving ? '...' : EventsStrings.save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _photo = file);
    }
  }

  String _resolvedLocation() {
    if (_isCustom) {
      return _customLocation.text.trim();
    }
    return _preset.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final locationName = _resolvedLocation();
    if (locationName.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(eventsControllerProvider.notifier).create(
            title: _title.text.trim(),
            locationName: locationName,
            dateTime: _when,
            description: _description.text.trim(),
            photo: _photo,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error, stack) {
      debugPrint('Event publish UI error: $error');
      debugPrint('$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(EventsStrings.publishError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
