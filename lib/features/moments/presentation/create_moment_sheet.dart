import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../events/data/seed_events.dart';
import '../../events/presentation/events_controller.dart';
import '../../location/presentation/home_city_provider.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/moment_model.dart';
import 'moments_controller.dart';
import 'moments_strings.dart';

Future<void> showCreateMomentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          // Extra lift so "Objavi" clears the phone gesture / nav bar.
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 40,
        ),
        child: const CreateMomentSheet(),
      );
    },
  );
}

class CreateMomentSheet extends ConsumerStatefulWidget {
  const CreateMomentSheet({super.key});

  @override
  ConsumerState<CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends ConsumerState<CreateMomentSheet> {
  final _caption = TextEditingController();
  final _customLocation = TextEditingController();
  late String _cityId;
  String? _preset;
  String? _dogId;
  XFile? _photo;
  var _isLoading = false;

  String get _selectedVenue {
    final venues = ref.read(eventVenuesProvider(_cityId));
    final preset = _preset;
    return preset != null && venues.contains(preset) ? preset : venues.first;
  }

  bool get _isCustom => EventVenues.isCustom(_selectedVenue);

  @override
  void initState() {
    super.initState();
    _cityId = ref.read(homeCityProvider)?.id ?? SerbiaLocations.noviSadId;
  }

  @override
  void dispose() {
    _caption.dispose();
    _customLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final dogs = profile.dogs;
    final venues = ref.watch(eventVenuesProvider(_cityId));
    _dogId ??= profile.selectedDogId.isNotEmpty
        ? profile.selectedDogId
        : (dogs.isEmpty ? null : dogs.first.id);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            MomentsStrings.share,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 16),
          if (dogs.isEmpty)
            Text(MomentsStrings.noDogs)
          else
            DropdownButtonFormField<String>(
              initialValue: _dogId,
              decoration: InputDecoration(labelText: MomentsStrings.dog),
              items: [
                for (final dog in dogs)
                  DropdownMenuItem(value: dog.id, child: Text(dog.name)),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) => setState(() => _dogId = value),
            ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('moment-city'),
            initialValue: _cityId,
            decoration: InputDecoration(labelText: MomentsStrings.city),
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
            key: ValueKey('moment-venue-$_cityId'),
            initialValue: _selectedVenue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: MomentsStrings.location,
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
            TextField(
              controller: _customLocation,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: MomentsStrings.customLocationHint,
                hintText: MomentsStrings.customLocationHint,
              ),
            ),
          ],
          SizedBox(height: 12),
          TextField(
            controller: _caption,
            enabled: !_isLoading,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: MomentsStrings.caption,
            ),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickPhoto,
            icon: const Icon(Icons.photo_outlined),
            label: Text(
              _photo == null ? MomentsStrings.addPhoto : MomentsStrings.photo,
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(MomentsStrings.uploading),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading || dogs.isEmpty ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(MomentsStrings.publish),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _photo = file);
    }
  }

  String? _resolvedLocation() {
    if (!_isCustom) {
      return _selectedVenue;
    }
    final custom = _customLocation.text.trim();
    return custom.isEmpty ? null : custom;
  }

  Future<void> _save() async {
    final profile = ref.read(profileControllerProvider);
    final caption = _caption.text.trim();
    final dogId = _dogId;
    if (dogId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(MomentsStrings.dogRequired)));
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MomentsStrings.photoRequired)),
      );
      return;
    }
    final location = _resolvedLocation();
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MomentsStrings.customLocationRequired)),
      );
      return;
    }
    final dog = profile.dogs.where((item) => item.id == dogId).toList();
    if (dog.isEmpty) {
      return;
    }
    final selected = dog.first;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(momentsControllerProvider.notifier)
          .create(
            draft: MomentModel(
              id: '',
              authorUserId: '',
              authorName: profile.ownerName,
              dogId: selected.id,
              dogName: selected.name,
              dogBreed: selected.breed,
              dogPhotoUrl: selected.photoUrl,
              momentPhotoUrl: '',
              caption: caption,
              locationName: location,
              likes: const [],
              commentsCount: 0,
              createdAt: DateTime.now(),
            ),
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
              Expanded(child: Text(MomentsStrings.successTitle)),
            ],
          ),
          content: Text(MomentsStrings.successBody),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(MomentsStrings.ok),
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
              Expanded(child: Text(MomentsStrings.errorTitle)),
            ],
          ),
          content: Text(
            MomentsStrings.createErrorBody(
              details.isEmpty ? MomentsStrings.publishError : details,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(MomentsStrings.close),
            ),
          ],
        ),
      );
    }
  }
}
