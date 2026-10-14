import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../location/presentation/home_city_provider.dart';
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
  late String _cityId;
  String? _preset;
  DateTime _when = DateTime.now().add(const Duration(days: 1));
  XFile? _photo;
  var _isLoading = false;

  List<String> get _venues => ref.read(eventVenuesProvider(_cityId));

  String get _selectedVenue {
    final venues = _venues;
    final preset = _preset;
    return preset != null && venues.contains(preset) ? preset : venues.first;
  }

  bool get _isCustom => EventVenues.isCustom(_selectedVenue);

  @override
  void initState() {
    super.initState();
    _cityId = ref.read(eventsCityFilterProvider) ??
        ref.read(homeCityProvider)?.id ??
        SerbiaLocations.noviSadId;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _customLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venues = ref.watch(eventVenuesProvider(_cityId));
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
            SizedBox(height: 16),
            TextFormField(
              controller: _title,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: EventsStrings.fieldTitle,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? EventsStrings.titleRequired
                  : null,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('event-city'),
              initialValue: _cityId,
              decoration: InputDecoration(
                labelText: EventsStrings.fieldCity,
              ),
              items: [
                for (final city in SerbiaLocations.cities)
                  DropdownMenuItem(value: city.id, child: Text(city.name)),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null && value != _cityId) {
                        setState(() {
                          _cityId = value;
                          _preset = null;
                          _customLocation.clear();
                        });
                      }
                    },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('event-venue-$_cityId'),
              initialValue: _selectedVenue,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: EventsStrings.fieldLocation,
              ),
              items: [
                for (final name in venues)
                  DropdownMenuItem(
                    value: name,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  ),
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
              SizedBox(height: 12),
              TextFormField(
                controller: _customLocation,
                enabled: !_isLoading,
                decoration: InputDecoration(
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
            SizedBox(height: 12),
            Text(
              EventsStrings.fieldWhen,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: !_isLoading,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(EventsStrings.fieldDate),
              subtitle: Text(EventsStrings.dateOnly(_when)),
              trailing: TextButton(
                onPressed: _isLoading ? null : _pickDate,
                child: Text(EventsStrings.pickDate),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: !_isLoading,
              leading: const Icon(Icons.schedule_outlined),
              title: Text(EventsStrings.fieldTime),
              subtitle: Text(EventsStrings.timeOnly(_when)),
              trailing: TextButton(
                onPressed: _isLoading ? null : _pickTime,
                child: Text(EventsStrings.pickTime),
              ),
            ),
            Text(
              EventsStrings.when(_when),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _description,
              enabled: !_isLoading,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: EventsStrings.fieldDescription,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? EventsStrings.descriptionRequired
                  : null,
            ),
            SizedBox(height: 12),
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
                  : Text(EventsStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _showPastError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(EventsStrings.pastDateError)),
    );
  }

  Future<void> _pickDate() async {
    final initial = _when.isBefore(_today) ? _today : _when;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: _today,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    final next = DateTime(
      date.year,
      date.month,
      date.day,
      _when.hour,
      _when.minute,
    );
    if (!next.isAfter(DateTime.now())) {
      final bump = DateTime.now().add(const Duration(hours: 1));
      setState(() {
        _when = DateTime(date.year, date.month, date.day, bump.hour, 0);
      });
      _showPastError();
      return;
    }
    setState(() => _when = next);
  }

  Future<void> _pickTime() async {
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
    final next = DateTime(
      _when.year,
      _when.month,
      _when.day,
      time.hour,
      time.minute,
    );
    if (!next.isAfter(DateTime.now())) {
      _showPastError();
      return;
    }
    setState(() => _when = next);
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
    return _selectedVenue.trim();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final locationName = _resolvedLocation();
    if (locationName.isEmpty) {
      return;
    }
    if (!_when.isAfter(DateTime.now())) {
      _showPastError();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(eventsControllerProvider.notifier).create(
            title: _title.text.trim(),
            locationName: locationName,
            dateTime: _when,
            description: _description.text.trim(),
            cityId: _cityId,
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
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text(EventsStrings.successTitle)),
            ],
          ),
          content: Text(EventsStrings.successBody),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(EventsStrings.ok),
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
          title: Row(
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
              child: Text(EventsStrings.close),
            ),
          ],
        ),
      );
    }
  }
}
