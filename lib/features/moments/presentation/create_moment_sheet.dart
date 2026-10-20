import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/media/picked_video.dart';
import '../../../core/media/tap_to_play_video.dart';
import '../../../core/media/video_limits.dart';
import '../../../core/media/video_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/media_source_row.dart';
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
/// stories (stories bar on Početna): nothing is copied or uploaded twice.
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

/// City dropdown value for "Bez grada" / location value for "Bez lokacije".
const String _none = '';

/// City and location are both optional. Empty values are stored as '' (the
/// post is then not in "U blizini", which filters by `cityId`).
({String cityId, String locationName}) resolveMomentPlace({
  required String cityId,
  required String venue,
  required String customText,
}) {
  if (venue == _none) {
    return (cityId: cityId, locationName: '');
  }
  if (EventVenues.isCustom(venue)) {
    return (cityId: cityId, locationName: customText.trim());
  }
  return (cityId: cityId, locationName: venue);
}

class CreateMomentSheet extends ConsumerStatefulWidget {
  const CreateMomentSheet({
    super.key,
    this.initialPhoto,
    this.initialVideo,
    this.videoProbe,
  });

  /// Preselected photo (tests); normally picked in the sheet.
  final XFile? initialPhoto;

  /// Preselected, already checked video (tests).
  final PickedVideo? initialVideo;

  /// Reads a picked video's length (tests inject one).
  final VideoProbe? videoProbe;

  @override
  ConsumerState<CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends ConsumerState<CreateMomentSheet> {
  final _caption = TextEditingController();
  final _customLocation = TextEditingController();
  late String _cityId;
  String _venue = _none;

  /// '' = no dog on the post.
  String? _dogId;
  var _videoMode = false;
  XFile? _photo;
  Uint8List? _preview;
  PickedVideo? _video;
  var _phase = _Phase.idle;
  String? _error;

  /// Kept across retries: the same draft id and uploaded media, so a retry
  /// never creates a second post or a second file.
  String? _draftId;
  String? _uploadedUrl;

  bool get _busy => _phase != _Phase.idle;

  bool get _hasMedia => _photo != null || _video != null;

  List<String> _venuesFor(String cityId) {
    if (cityId == _none) {
      return [_none, EventVenues.customOption];
    }
    return [_none, ...ref.read(eventVenuesProvider(cityId))];
  }

  @override
  void initState() {
    super.initState();
    // Prefilled with my city (removable): that is what "U blizini" shows.
    _cityId = ref.read(homeCityProvider)?.id ?? _none;
    final initial = widget.initialPhoto;
    if (initial != null) {
      _setPhoto(initial);
    }
    final video = widget.initialVideo;
    if (video != null) {
      _video = video;
      _videoMode = true;
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _customLocation.dispose();
    super.dispose();
  }

  void _resetDraft() {
    _uploadedUrl = null;
    _draftId = null;
    _error = null;
  }

  Future<void> _setPhoto(XFile file) async {
    setState(() {
      _photo = file;
      _video = null;
      _preview = null;
      // New media is a new draft.
      _resetDraft();
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
    if (_cityId != _none) {
      ref.watch(eventVenuesProvider(_cityId));
    }
    final venues = _venuesFor(_cityId);
    if (!venues.contains(_venue)) {
      _venue = _none;
    }
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
          _MediaPreview(
            preview: _preview,
            photo: _photo,
            video: _video,
            enabled: !_busy,
            onTap: () => _pick(ImageSource.gallery),
          ),
          const SizedBox(height: 10),
          MediaSourceRow(
            keyPrefix: 'moment',
            video: _videoMode,
            enabled: !_busy,
            onVideoChanged: (value) => setState(() => _videoMode = value),
            onGallery: () => _pick(ImageSource.gallery),
            onCamera: () => _pick(ImageSource.camera),
            hint: _videoMode
                ? VideoStrings.limitHint(VideoLimits.postMaxDuration)
                : null,
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
            decoration: InputDecoration(
              labelText: MomentsStrings.cityOptional,
              helperText: _cityId == _none ? MomentsStrings.noCityHint : null,
              helperMaxLines: 2,
            ),
            items: [
              DropdownMenuItem(
                value: _none,
                child: Text(MomentsStrings.noCity),
              ),
              for (final city in SerbiaLocations.cities)
                DropdownMenuItem(value: city.id, child: Text(city.name)),
            ],
            onChanged: _busy
                ? null
                : (value) {
                    if (value != null && value != _cityId) {
                      setState(() {
                        _cityId = value;
                        _venue = _none;
                        _customLocation.clear();
                      });
                    }
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('moment-venue-$_cityId'),
            initialValue: _venue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: MomentsStrings.locationOptional,
            ),
            items: [
              for (final name in venues)
                DropdownMenuItem(
                  value: name,
                  child: Text(
                    name == _none ? MomentsStrings.noLocation : name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _busy
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _venue = value);
                    }
                  },
          ),
          if (EventVenues.isCustom(_venue)) ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('moment-custom-location'),
              controller: _customLocation,
              enabled: !_busy,
              maxLength: 200,
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
                      ? (_video != null
                          ? MomentsStrings.uploadingVideo
                          : MomentsStrings.uploading)
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
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
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
                    minimumSize: const Size(0, 48),
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
    if (_videoMode) {
      await _pickVideo(source);
      return;
    }
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

  Future<void> _pickVideo(ImageSource source) async {
    const max = VideoLimits.postMaxDuration;
    try {
      final file = await pickVideoFile(source, max);
      if (file == null || !mounted) {
        return;
      }
      final result = await inspectPickedVideo(
        file,
        maxDuration: max,
        probe: widget.videoProbe,
      );
      if (!mounted) {
        return;
      }
      final problem = result.problem;
      if (problem != null) {
        setState(() => _error = VideoStrings.problem(problem, max));
        return;
      }
      setState(() {
        _video = result.video;
        _photo = null;
        _preview = null;
        _resetDraft();
      });
    } catch (error) {
      debugPrint('moment video pick failed: $error');
      if (mounted) {
        setState(() => _error = MomentsStrings.loadError);
      }
    }
  }

  Future<void> _save() async {
    final photo = _photo;
    final video = _video;
    if (!_hasMedia) {
      setState(() => _error = MomentsStrings.photoRequired);
      return;
    }
    final place = resolveMomentPlace(
      cityId: _cityId,
      venue: _venue,
      customText: _customLocation.text,
    );
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
      final url = _uploadedUrl ??= video != null
          ? await actions.uploadVideo(video, draftId)
          : await actions.uploadPhoto(photo!, draftId);
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
          mediaType: video != null
              ? MomentMediaType.video
              : MomentMediaType.image,
          caption: _caption.text.trim(),
          locationName: place.locationName,
          cityId: place.cityId,
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

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.preview,
    required this.photo,
    required this.video,
    required this.enabled,
    required this.onTap,
  });

  final Uint8List? preview;
  final XFile? photo;
  final PickedVideo? video;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bytes = preview;
    final picked = video;
    Widget child;
    if (picked != null) {
      child = TapToPlayVideo(
        key: const ValueKey('moment-video-preview'),
        source: picked.file.path,
        // A local file (or web blob): showing the first frame is free.
        initializeEagerly: true,
        durationLabel: formatVideoDuration(picked.duration),
      );
    } else {
      child = Material(
        color: AppColors.primarySoft,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: bytes != null
              ? Image.memory(
                  bytes,
                  key: const ValueKey('moment-photo-preview'),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const _PickHint(ready: true),
                )
              : _PickHint(ready: photo != null),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(aspectRatio: 4 / 5, child: child),
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
            ready ? MomentsStrings.photo : MomentsStrings.addMedia,
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
