import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/content_validation_service.dart';
import '../domain/story.dart';
import 'stories_strings.dart';
import 'story_providers.dart';

Future<Story?> showCreateStorySheet(BuildContext context) {
  return showModalBottomSheet<Story>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateStorySheet(),
  );
}

/// Pick → preview → caption + audience → publish (with progress / retry).
class CreateStorySheet extends ConsumerStatefulWidget {
  const CreateStorySheet({super.key, this.picker});

  /// Injected in tests.
  final Future<XFile?> Function(ImageSource source)? picker;

  @override
  ConsumerState<CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends ConsumerState<CreateStorySheet> {
  final _caption = TextEditingController();
  XFile? _file;
  Uint8List? _bytes;

  /// No default: the author picks the audience explicitly.
  StoryAudience? _audience;
  double? _progress;
  String? _error;

  bool get _publishing => _progress != null && _error == null;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
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
        _error = null;
        _progress = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = StoriesStrings.publishFailed);
      }
    }
  }

  Future<void> _publish() async {
    final bytes = _bytes;
    final audience = _audience;
    if (bytes == null || audience == null || _publishing) {
      return;
    }
    setState(() {
      _progress = 0;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final story = await ref.read(storyActionsProvider).publish(
            draft: StoryDraft(audience: audience, caption: _caption.text),
            bytes: bytes,
            mimeType: _file?.mimeType,
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
        // Bytes, caption and audience stay: "Pokušaj ponovo" resends them.
        setState(() => _error = StoriesStrings.publishFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = _bytes;
    final canPublish = bytes != null && _audience != null && !_publishing;
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
                  child: bytes == null
                      ? _PickPrompt(onPick: _pick)
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
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filledTonal(
                                tooltip: StoriesStrings.pickGallery,
                                onPressed: _publishing
                                    ? null
                                    : () => _pick(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${StoriesStrings.expiresHint} ${StoriesStrings.videoNotSupported}',
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
                _error != null && bytes != null
                    ? Icons.refresh_rounded
                    : Icons.send_rounded,
              ),
              label: Text(
                _publishing
                    ? StoriesStrings.publishing
                    : (_error != null && bytes != null
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
  const _PickPrompt({required this.onPick});

  final Future<void> Function(ImageSource source) onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_a_photo_outlined, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            StoriesStrings.pickPhoto,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              FilledButton.icon(
                key: const ValueKey('story-pick-gallery'),
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(StoriesStrings.pickGallery),
              ),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: () => onPick(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(StoriesStrings.pickCamera),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
