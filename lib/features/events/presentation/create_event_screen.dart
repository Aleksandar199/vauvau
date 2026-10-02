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
  var _isLoading = false;

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
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: EventsStrings.fieldTitle,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
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
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _preset = value);
                      }
                    },
            ),
            if (_isCustom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customLocation,
                enabled: !_isLoading,
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
              enabled: !_isLoading,
              title: const Text(EventsStrings.fieldWhen),
              subtitle: Text(EventsStrings.when(_when)),
              trailing: const Icon(Icons.event),
              onTap: _isLoading ? null : _pickWhen,
            ),
            TextFormField(
              controller: _description,
              enabled: !_isLoading,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: EventsStrings.fieldDescription,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? EventsStrings.descriptionRequired
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickPhoto,
              icon: const Icon(Icons.photo_outlined),
              label: Text(
                _photo == null
                    ? EventsStrings.addPhoto
                    : EventsStrings.fieldPhoto,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(EventsStrings.save),
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final locationName = _resolvedLocation();
    if (locationName.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(eventsControllerProvider.notifier).create(
            title: _title.text.trim(),
            locationName: locationName,
            dateTime: _when,
            description: _description.text.trim(),
            photo: _photo,
          );

      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text(EventsStrings.successTitle)),
            ],
          ),
          content: const Text(EventsStrings.successBody),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text(EventsStrings.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      final details = e.toString().replaceFirst('Exception: ', '').trim();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text(EventsStrings.errorTitle)),
            ],
          ),
          content: Text(
            EventsStrings.createErrorBody(
              details.isEmpty ? EventsStrings.publishError : details,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(EventsStrings.close),
            ),
          ],
        ),
      );
    }
  }
}
