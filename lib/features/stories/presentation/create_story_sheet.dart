import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/media/picked_video.dart';
import '../../../core/media/tap_to_play_video.dart';
import '../../../core/media/video_limits.dart';
import '../../../core/media/video_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../../core/widgets/media_source_row.dart';
import '../domain/story.dart';
import 'stories_strings.dart';
import 'story_providers.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

Future<Story?> showCreateStorySheet(BuildContext context) {
  return showAppBottomSheet<Story>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateStorySheet(),
  );
}

/// Pick → preview → caption + audience → publish (with progress / retry).
/// Photo or a short video (≤ [VideoLimits.storyMaxDuration]).
class CreateStorySheet extends ConsumerStatefulWidget {
  const CreateStorySheet({
    super.key,
    this.picker,
    this.videoPicker,
    this.videoProbe,
  });

  /// Injected in tests.
  final Future<XFile?> Function(ImageSource source)? picker;
  final Future<XFile?> Function(ImageSource source)? videoPicker;
  final VideoProbe? videoProbe;

  @override
  ConsumerState<CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends ConsumerState<CreateStorySheet> {
  final _caption = TextEditingController();
  XFile? _file;
  Uint8List? _bytes;
  var _videoMode = false;

  /// Checked video; its bytes are read only when publishing.
  PickedVideo? _video;

  /// No default: the author picks the audience explicitly.
  StoryAudience? _audience;
  double? _progress;
  String? _error;

  bool get _publishing => _progress != null && _error == null;

  bool get _hasMedia => _bytes != null || _video != null;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_videoMode) {
      await _pickVideo(source);
      return;
    }
    final pick = widget.picker ??
        (ImageSource s) => ImagePicker().pickImage(
              source: s,
              imageQuality: 80,
              maxWidth: 1440,
            );
    try {
      final file = await pick(source);
      if (file == null || !mounted) {
        return;
      }
      final invalid = await ContentValidationService.validateImage(file);
      if (!mounted) {
        return;
      }
      if (invalid != null) {
        setState(() => _error = invalid);
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _file = file;
        _bytes = bytes;
        _video = null;
        _error = null;
        _progress = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = StoriesStrings.publishFailed);
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    const max = VideoLimits.storyMaxDuration;
    final pick =
        widget.videoPicker ?? (ImageSource s) => pickVideoFile(s, max);
    try {
      final file = await pick(source);
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
        _file = null;
        _bytes = null;
        _error = null;
        _progress = null;
      });
    } catch (error) {
      debugPrint('Story video pick failed: $error');
      if (mounted) {
        setState(() => _error = StoriesStrings.publishFailed);
      }
    }
  }

  Future<void> _publish() async {
    final video = _video;
    final audience = _audience;
    if (!_hasMedia || audience == null || _publishing) {
      return;
    }
    setState(() {
      _progress = 0;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final bytes = video != null ? await video.file.readAsBytes() : _bytes!;
      final story = await ref.read(storyActionsProvider).publish(
            draft: StoryDraft(
              audience: audience,
              caption: _caption.text,
              mediaType:
                  video != null ? StoryMediaType.video : StoryMediaType.image,
            ),
            bytes: bytes,
            mimeType: video?.contentType ?? _file?.mimeType,
            onProgress: (value) {
              if (mounted) {
                setState(() => _progress = value);
              }
            },
          );
      messenger?.showSnackBar(
        SnackBar(content: Text(StoriesStrings.published)),
      );
      navigator.pop(story);
    } catch (error) {
      debugPrint('Story publish failed: $error');
      if (mounted) {
        // Media, caption and audience stay: "Pokušaj ponovo" resends them.
        setState(() => _error = StoriesStrings.publishFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = _bytes;
    final video = _video;
    final canPublish = _hasMedia && _audience != null && !_publishing;
    final retrying = _error != null && _hasMedia;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      minChildSize: 0.5,
      builder: (context, controller) => Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    StoriesStrings.createTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: StoriesStrings.close,
                  onPressed: _publishing ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 9 / 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColoredBox(
                  color: Colors.black,
                  child: video != null
                      ? TapToPlayVideo(
                          key: const ValueKey('story-video-preview'),
                          source: video.file.path,
                          initializeEagerly: true,
                          durationLabel: formatVideoDuration(video.duration),
                        )
                      : bytes == null
                          ? _PickPrompt(video: _videoMode)
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(bytes, fit: BoxFit.cover),
                                if (_caption.text.trim().isNotEmpty)
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                    child: Text(
                                      _caption.text.trim(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            MediaSourceRow(
              keyPrefix: 'story-pick',
              video: _videoMode,
              enabled: !_publishing,
              showCamera: !kIsWeb,
              onVideoChanged: (value) => setState(() => _videoMode = value),
              onGallery: () => _pick(ImageSource.gallery),
              onCamera: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 8),
            Text(
              _videoMode
                  ? '${StoriesStrings.expiresHint} '
                      '${VideoStrings.limitHint(VideoLimits.storyMaxDuration)}'
                  : StoriesStrings.expiresHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('story-caption'),
              controller: _caption,
              enabled: !_publishing,
              maxLength: Story.maxCaptionLength,
              maxLines: 3,
              minLines: 1,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: StoriesStrings.captionHint),
            ),
            const SizedBox(height: 8),
            Text(
              StoriesStrings.audienceTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            RadioGroup<StoryAudience>(
              groupValue: _audience,
              onChanged: (value) {
                if (!_publishing && value != null) {
                  setState(() => _audience = value);
                }
              },
              child: Column(
                children: [
                  for (final audience in StoryAudience.values)
                    RadioListTile<StoryAudience>(
                      key: ValueKey('story-audience-${audience.key}'),
                      value: audience,
                      contentPadding: EdgeInsets.zero,
                      title: Text(StoriesStrings.audienceLabel(audience)),
                      subtitle: Text(StoriesStrings.audienceHint(audience)),
                    ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                key: const ValueKey('story-publish-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (_publishing) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                color: AppColors.primary,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('story-publish'),
              onPressed: canPublish ? _publish : null,
              icon: Icon(
                retrying ? Icons.refresh_rounded : Icons.send_rounded,
              ),
              label: Text(
                _publishing
                    ? StoriesStrings.publishing
                    : (retrying
                        ? StoriesStrings.retry
                        : StoriesStrings.publish),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickPrompt extends StatelessWidget {
  const _PickPrompt({required this.video});

  final bool video;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              video ? Icons.videocam_outlined : Icons.add_a_photo_outlined,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              video ? StoriesStrings.pickVideo : StoriesStrings.pickPhoto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
