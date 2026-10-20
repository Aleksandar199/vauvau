import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../events/data/seed_events.dart';
import '../../events/presentation/events_controller.dart';
import '../../location/presentation/home_city_provider.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/moment_model.dart';
import 'moments_controller.dart';
import 'moments_strings.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

/// "Nova objava" – a permanent Moments post. Completely separate from 24h
/// stories (stories bar on Otkrij): nothing is copied or uploaded twice.
Future<void> showCreateMomentSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: const CreateMomentSheet(),
      );
    },
  );
}

enum _Phase { idle, uploading, publishing }

class CreateMomentSheet extends ConsumerStatefulWidget {
  const CreateMomentSheet({super.key, this.initialPhoto});

  /// Preselected photo (tests); normally picked in the sheet.
  final XFile? initialPhoto;

  @override
  ConsumerState<CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends ConsumerState<CreateMomentSheet> {
  final _caption = TextEditingController();
  final _customLocation = TextEditingController();
  late String _cityId;
  String? _preset;

  /// '' = no dog on the post.
  String? _dogId;
  XFile? _photo;
  Uint8List? _preview;
  var _phase = _Phase.idle;
  String? _error;

  /// Kept across retries: the same draft id and uploaded photo, so a retry
  /// never creates a second post or a second file.
  String? _draftId;
  String? _uploadedUrl;

  bool get _busy => _phase != _Phase.idle;

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
    final initial = widget.initialPhoto;
    if (initial != null) {
      _setPhoto(initial);
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _customLocation.dispose();
    super.dispose();
  }

  Future<void> _setPhoto(XFile file) async {
    setState(() {
      _photo = file;
      _preview = null;
      // A new photo is a new draft.
      _uploadedUrl = null;
      _draftId = null;
      _error = null;
    });
    try {
      final bytes = await file.readAsBytes();
      if (mounted && _photo == file) {
        setState(() => _preview = bytes);
      }
    } catch (_) {
      // Preview only; upload reads the file again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileControllerProvider);
    final dogs = profile.dogs;
    final venues = ref.watch(eventVenuesProvider(_cityId));
    _dogId ??= profile.selectedDogId.isNotEmpty
        ? profile.selectedDogId
        : (dogs.isEmpty ? '' : dogs.first.id);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            MomentsStrings.newPost,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(MomentsStrings.newPostHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          _PhotoPicker(
            preview: _preview,
            hasPhoto: _photo != null,
            enabled: !_busy,
            onGallery: () => _pick(ImageSource.gallery),
            onCamera: () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: 16),
          if (dogs.isNotEmpty) ...[
            Text(MomentsStrings.dogOptional, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text(MomentsStrings.noDogOption),
                  selected: _dogId == '',
                  onSelected: _busy ? null : (_) => setState(() => _dogId = ''),
                ),
                for (final dog in dogs)
                  ChoiceChip(
                    key: ValueKey('moment-dog-${dog.id}'),
                    avatar: const Icon(Icons.pets, size: 16),
                    label: Text(dog.name),
                    selected: _dogId == dog.id,
                    onSelected:
                        _busy ? null : (_) => setState(() => _dogId = dog.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const ValueKey('moment-caption'),
            controller: _caption,
            enabled: !_busy,
            minLines: 2,
            maxLines: 5,
            maxLength: MomentModel.maxCaptionLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: MomentsStrings.caption),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: const ValueKey('moment-city'),
            initialValue: _cityId,
            decoration: InputDecoration(labelText: MomentsStrings.city),
            items: [
              for (final city in SerbiaLocations.cities)
                DropdownMenuItem(value: city.id, child: Text(city.name)),
            ],
            onChanged: _busy
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('moment-venue-$_cityId'),
            initialValue: _selectedVenue,
            isExpanded: true,
            decoration: InputDecoration(labelText: MomentsStrings.location),
            items: [
              for (final name in venues)
                DropdownMenuItem(
                  value: name,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _preset = value);
                    }
                  },
          ),
          if (_isCustom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customLocation,
              enabled: !_busy,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: MomentsStrings.customLocationHint,
                hintText: MomentsStrings.customLocationHint,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              key: const ValueKey('moment-publish-error'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  _phase == _Phase.uploading
                      ? MomentsStrings.uploading
                      : MomentsStrings.publishing,
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
                  child: Text(MomentsStrings.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  key: const ValueKey('moment-publish'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _busy ? null : _save,
                  child: Text(
                    _error == null
                        ? MomentsStrings.publish
                        : MomentsStrings.retryPublish,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        await _setPhoto(file);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = MomentsStrings.loadError);
      }
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
    final photo = _photo;
    if (photo == null) {
      setState(() => _error = MomentsStrings.photoRequired);
      return;
    }
    final location = _resolvedLocation();
    if (location == null) {
      setState(() => _error = MomentsStrings.customLocationRequired);
      return;
    }
    final profile = ref.read(profileControllerProvider);
    final dog = profile.dogs.where((item) => item.id == _dogId).firstOrNull;
    final avatar =
        ref.read(authStateProvider).asData?.value?.ownerAvatarUrl ?? '';
    final actions = ref.read(momentActionsProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);

    setState(() {
      _error = null;
      _phase = _Phase.uploading;
    });
    try {
      final draftId = _draftId ??= actions.newMomentId();
      final url = _uploadedUrl ??= await actions.uploadPhoto(photo, draftId);
      if (!mounted) {
        return;
      }
      setState(() => _phase = _Phase.publishing);
      await actions.publish(
        MomentModel(
          id: draftId,
          authorUserId: '',
          authorName: profile.ownerName,
          authorPhotoUrl: avatar,
          dogId: dog?.id ?? '',
          dogName: dog?.name ?? '',
          dogBreed: dog?.breed ?? '',
          dogPhotoUrl: dog?.photoUrl ?? '',
          momentPhotoUrl: url,
          caption: _caption.text.trim(),
          locationName: location,
          cityId: _cityId,
          likes: const [],
          commentsCount: 0,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) {
        return;
      }
      navigator.maybePop();
      messenger?.showSnackBar(SnackBar(content: Text(MomentsStrings.published)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      final details = error is StateError
          ? error.message
          : error.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _phase = _Phase.idle;
        _error = MomentsStrings.createErrorBody(
          details.isEmpty ? MomentsStrings.publishError : details,
        );
      });
    }
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.preview,
    required this.hasPhoto,
    required this.enabled,
    required this.onGallery,
    required this.onCamera,
  });

  final Uint8List? preview;
  final bool hasPhoto;
  final bool enabled;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final bytes = preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Material(
              color: AppColors.primarySoft,
              child: InkWell(
                onTap: enabled ? onGallery : null,
                child: bytes != null
                    ? Image.memory(
                        bytes,
                        key: const ValueKey('moment-photo-preview'),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const _PickHint(ready: true),
                      )
                    : _PickHint(ready: hasPhoto),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? onGallery : null,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  hasPhoto
                      ? MomentsStrings.changePhoto
                      : MomentsStrings.pickFromGallery,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? onCamera : null,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(MomentsStrings.takePhoto),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickHint extends StatelessWidget {
  const _PickHint({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle_outline : Icons.add_a_photo_outlined,
            size: 44,
            color: AppColors.primaryDeep,
          ),
          const SizedBox(height: 8),
          Text(
            ready ? MomentsStrings.photo : MomentsStrings.addPhoto,
            style: const TextStyle(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
