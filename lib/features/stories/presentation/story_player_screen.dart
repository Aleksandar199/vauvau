import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/images/firebase_web_image.dart';
import '../../../core/media/story_video.dart';
import '../../../core/media/video_limits.dart';
import '../../../core/theme/app_colors.dart';
import '../../follows/presentation/follow_controller.dart';
import '../../follows/presentation/follow_button.dart';
import '../../moments/presentation/highlight_sheets.dart';
import '../../moments/presentation/pointer_safe.dart';
import '../../profile/data/owner_public_profile.dart';
import '../domain/story.dart';
import 'stories_strings.dart';
import 'story_highlight.dart';
import 'story_providers.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

const Duration kStoryItemDuration = Duration(seconds: 6);

Future<void> openStoryPlayer(
  BuildContext context, {
  required List<StoryAuthorGroup> groups,
  int initialGroup = 0,
}) {
  if (groups.isEmpty) {
    return Future.value();
  }
  final navigator = Navigator.of(context, rootNavigator: true);
  final page = initialGroup.clamp(0, groups.length - 1);
  return afterPointerSettles(() async {
    if (!navigator.mounted) {
      return;
    }
    await navigator.push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) =>
            StoryPlayerScreen(groups: groups, initialGroup: page),
      ),
    );
  });
}

/// Opens one story by id (chat reply, notification). Shows a message when
/// it expired, was deleted or is no longer visible to me.
Future<void> openStoryById(
  BuildContext context,
  WidgetRef ref,
  String storyId,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final story = await ref.read(storyActionsProvider).fetch(storyId);
  if (!context.mounted) {
    return;
  }
  if (story == null) {
    messenger?.showSnackBar(SnackBar(content: Text(StoriesStrings.unavailable)));
    return;
  }
  await openStoryPlayer(context, groups: [StoryAuthorGroup.of([story])]);
}

class StoryPlayerScreen extends ConsumerStatefulWidget {
  const StoryPlayerScreen({
    super.key,
    required this.groups,
    this.initialGroup = 0,
  });

  final List<StoryAuthorGroup> groups;
  final int initialGroup;

  @override
  ConsumerState<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends ConsumerState<StoryPlayerScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialGroup,
  );
  late int _current = widget.initialGroup;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _close() {
    if (!mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    afterPointerSettlesIfMounted(context, () {
      if (navigator.mounted) {
        navigator.maybePop();
      }
    });
  }

  void _nextGroup() {
    if (_current < widget.groups.length - 1) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _close();
    }
  }

  void _previousGroup() {
    if (_current > 0) {
      _pages.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.groups.length,
        onPageChanged: (value) => setState(() => _current = value),
        itemBuilder: (context, i) => _StoryGroupPlayer(
          key: ValueKey('story-group-${widget.groups[i].authorUserId}-$i'),
          group: widget.groups[i],
          active: i == _current,
          onNextGroup: _nextGroup,
          onPreviousGroup: _previousGroup,
          onClose: _close,
        ),
      ),
    );
  }
}

class _StoryGroupPlayer extends ConsumerStatefulWidget {
  const _StoryGroupPlayer({
    super.key,
    required this.group,
    required this.active,
    required this.onNextGroup,
    required this.onPreviousGroup,
    required this.onClose,
  });

  final StoryAuthorGroup group;
  final bool active;
  final VoidCallback onNextGroup;
  final VoidCallback onPreviousGroup;
  final VoidCallback onClose;

  @override
  ConsumerState<_StoryGroupPlayer> createState() => _StoryGroupPlayerState();
}

class _StoryGroupPlayerState extends ConsumerState<_StoryGroupPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: kStoryItemDuration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _next();
          }
        });
  final _reply = TextEditingController();
  final _replyFocus = FocusNode();
  late List<Story> _items = _activeItems();
  var _index = 0;
  var _held = false;
  var _mediaReady = false;

  /// Progress is running (a video item plays exactly while it runs).
  var _playing = false;

  /// New key for a video each time an item is shown (replay from 0).
  var _showCount = 0;
  var _liked = false;
  var _likeBusy = false;
  var _sending = false;
  String? _replyNonce;

  List<Story> _activeItems() {
    final now = DateTime.now();
    return [
      for (final story in widget.group.stories)
        if (story.isActive(now)) story,
    ];
  }

  Story? get _story =>
      _items.isEmpty ? null : _items[_index.clamp(0, _items.length - 1)];

  bool get _isMine =>
      _story != null &&
      _story!.authorUserId == ref.read(socialUserIdProvider);

  @override
  void initState() {
    super.initState();
    _replyFocus.addListener(() {
      if (_replyFocus.hasFocus) {
        _stop();
      } else {
        _resume();
      }
    });
    if (widget.active) {
      _show();
    }
  }

  @override
  void didUpdateWidget(covariant _StoryGroupPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _show();
    } else if (!widget.active && oldWidget.active) {
      _progress.stop();
      _playing = false; // rebuilt with the new widget
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _reply.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  /// Shows the current item; progress starts once its media has loaded.
  void _show() {
    final story = _story;
    if (story == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNextGroup());
      return;
    }
    _progress.reset();
    _progress.duration = kStoryItemDuration;
    _playing = false;
    _showCount++;
    _mediaReady = false;
    _liked = false;
    _replyNonce = null;
    if (!story.isActive(DateTime.now())) {
      // Expired while open: never show it.
      _items = [..._items]..remove(story);
      _index = _index.clamp(0, _items.isEmpty ? 0 : _items.length - 1);
      _show();
      return;
    }
    if (!_isMine) {
      ref.read(storyActionsProvider).isLiked(story).then((liked) {
        if (mounted && _story == story) {
          setState(() => _liked = liked);
        }
      });
    }
  }

  void _onMediaLoaded(Story story) {
    if (!mounted || _story != story || _mediaReady) {
      return;
    }
    _mediaReady = true;
    ref.read(storyActionsProvider).markViewed(story);
    _resume();
  }

  void _resume() {
    if (mounted &&
        widget.active &&
        _mediaReady &&
        !_held &&
        !_replyFocus.hasFocus) {
      _progress.forward();
      _setPlaying(true);
    }
  }

  /// Stops the progress bar and a playing video with it.
  void _stop() {
    _progress.stop();
    _setPlaying(false);
  }

  void _setPlaying(bool value) {
    if (mounted && _playing != value) {
      setState(() => _playing = value);
    }
  }

  /// Video item: the progress bar lasts as long as the video (≤ 15 s).
  void _onVideoReady(Story story, Duration length) {
    if (!mounted || _story != story) {
      return;
    }
    _progress.duration = storyVideoItemDuration(
      length,
      VideoLimits.maxDuration + VideoLimits.tolerance,
    );
    _onMediaLoaded(story);
  }

  void _next() {
    if (_index < _items.length - 1) {
      setState(() => _index++);
      _show();
    } else {
      _stop();
      widget.onNextGroup();
    }
  }

  void _previous() {
    if (_index > 0) {
      setState(() => _index--);
      _show();
    } else {
      _progress.reset();
      _resume();
      widget.onPreviousGroup();
    }
  }

  Future<T?> _paused<T>(Future<T?> Function() action) async {
    _stop();
    try {
      return await action();
    } finally {
      _resume();
    }
  }

  var _archiving = false;

  /// Copies my story into a permanent moment and opens the highlight picker
  /// (existing highlight or a new one) for that dog.
  Future<void> _addToHighlight(Story story) async {
    if (_archiving) {
      return;
    }
    setState(() => _archiving = true);
    await _paused(() async {
      final messenger = ScaffoldMessenger.maybeOf(context);
      try {
        final moment =
            await ref.read(storyHighlightArchiverProvider).archive(story);
        if (mounted) {
          await showAddToHighlightSheet(context, moment);
        }
      } on StateError catch (error) {
        messenger?.showSnackBar(SnackBar(content: Text(error.message)));
      } catch (error) {
        debugPrint('story highlight: $error');
        messenger?.showSnackBar(
          SnackBar(content: Text(StoriesStrings.highlightFailed)),
        );
      }
      return null;
    });
    if (mounted) {
      setState(() => _archiving = false);
    }
  }

  Future<void> _toggleLike(Story story) async {
    if (_likeBusy) {
      return;
    }
    final wanted = !_liked;
    setState(() {
      _liked = wanted;
      _likeBusy = true;
    });
    try {
      await ref.read(storyActionsProvider).setLiked(story, liked: wanted);
    } catch (error) {
      if (mounted) {
        setState(() => _liked = !wanted);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(StoriesStrings.unavailable)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _likeBusy = false);
      }
    }
  }

  Future<void> _sendReply(Story story) async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    final actions = ref.read(storyActionsProvider);
    // Same nonce on retry → the author is notified once.
    final nonce = _replyNonce ??= actions.newReplyNonce();
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _sending = true);
    try {
      await actions.reply(story, text, nonce: nonce);
      _reply.clear();
      _replyNonce = null;
      _replyFocus.unfocus();
      messenger?.showSnackBar(SnackBar(content: Text(StoriesStrings.replySent)));
    } catch (error) {
      debugPrint('Story reply failed: $error');
      messenger?.showSnackBar(
        SnackBar(content: Text(StoriesStrings.replyFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _delete(Story story) async {
    final confirmed = await _paused(
      () => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(StoriesStrings.delete),
          content: Text(StoriesStrings.deleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(StoriesStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(StoriesStrings.confirmDelete),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(storyActionsProvider).delete(story);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = [..._items]..remove(story);
      if (_index >= _items.length) {
        _index = _items.isEmpty ? 0 : _items.length - 1;
      }
    });
    if (_items.isEmpty) {
      widget.onNextGroup();
    } else {
      _show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    if (story == null) {
      return Center(
        child: Text(
          StoriesStrings.unavailable,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    final mine = _isMine;
    final now = DateTime.now();
    // Video: local file (mobile) / URL (web), timing set when it is ready.
    // Photo: web shows an HTML <img> from a URL; mobile decodes the bytes.
    final video =
        story.isVideo ? ref.watch(storyVideoSourceProvider(story)) : null;
    final webUrl = !story.isVideo && kIsWeb
        ? ref.watch(storyMediaUrlProvider(story))
        : null;
    final bytes = !story.isVideo && !kIsWeb
        ? ref.watch(storyMediaProvider(story))
        : null;
    final AsyncValue<Object> media = (video ?? webUrl ?? bytes)!;
    if (media.hasValue && video == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onMediaLoaded(story),
      );
    } else if (media.hasError) {
      // Not allowed / deleted media: no view is recorded, the item still
      // times out so the player moves on.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _story == story && !_mediaReady) {
          _mediaReady = true;
          _resume();
        }
      });
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        if (_replyFocus.hasFocus) {
          _replyFocus.unfocus();
          return;
        }
        final width = MediaQuery.sizeOf(context).width;
        if (details.localPosition.dx < width * 0.3) {
          _previous();
        } else {
          _next();
        }
      },
      onLongPressStart: (_) {
        _held = true;
        _stop();
      },
      onLongPressEnd: (_) {
        _held = false;
        _resume();
      },
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 300) {
          widget.onClose();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video != null)
            video.when(
              data: (source) => StoryVideo(
                key: ValueKey('story-video-${story.id}-$_showCount'),
                source: source,
                playing: _playing,
                onReady: (length) => _onVideoReady(story, length),
                onError: () {
                  // Unplayable: move on like a photo that failed to load.
                  if (mounted && _story == story && !_mediaReady) {
                    _mediaReady = true;
                    _resume();
                  }
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
              error: (_, _) => const _Unavailable(),
            )
          else if (kIsWeb)
            webUrl!.when(
              // HTML <img> (no bucket CORS needed), photo kept whole.
              data: (url) => KeyedSubtree(
                key: ValueKey('story-media-${story.id}'),
                child: buildFirebaseWebImage(
                  url: url,
                  fit: BoxFit.contain,
                  passThroughPointer: true,
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
              error: (_, _) => const _Unavailable(),
            )
          else
            bytes!.when(
              data: (data) => Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred fill + the whole photo on top: portrait fills the
                  // screen, landscape is letterboxed, nothing is stretched.
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Image.memory(data, fit: BoxFit.cover),
                  ),
                  Image.memory(
                    data,
                    key: ValueKey('story-media-${story.id}'),
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
              error: (_, _) => const _Unavailable(),
            ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.2, 0.65, 1],
                  colors: [
                    Color(0x99000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xB3000000),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _ProgressBars(
                  count: _items.length,
                  index: _index,
                  progress: _progress,
                ),
                _Header(
                  story: story,
                  now: now,
                  mine: mine,
                  onViewers: () => _paused(
                    () => showStoryViewersSheet(context, story),
                  ),
                  onDelete: () => _delete(story),
                  onClose: widget.onClose,
                ),
                const Spacer(),
                if (story.caption.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        story.caption.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                        ),
                      ),
                    ),
                  ),
                if (mine)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        TextButton.icon(
                          key: const ValueKey('story-viewers-button'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _paused(
                            () => showStoryViewersSheet(context, story),
                          ),
                          icon: const Icon(Icons.visibility_outlined),
                          label: Text(StoriesStrings.viewers),
                        ),
                        TextButton.icon(
                          key: const ValueKey('story-add-to-highlight'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _archiving
                              ? null
                              : () => _addToHighlight(story),
                          icon: _archiving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.bookmark_add_outlined),
                          label: Text(StoriesStrings.addToHighlight),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            StoriesStrings.audienceBadge(story.audience),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _ReplyBar(
                    controller: _reply,
                    focusNode: _replyFocus,
                    liked: _liked,
                    sending: _sending,
                    onLike: () => _toggleLike(story),
                    onSend: () => _sendReply(story),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.index,
    required this.progress,
  });

  final int count;
  final int index;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) => LinearProgressIndicator(
                    minHeight: 3,
                    value: i < index ? 1 : (i == index ? progress.value : 0),
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.story,
    required this.now,
    required this.mine,
    required this.onViewers,
    required this.onDelete,
    required this.onClose,
  });

  final Story story;
  final DateTime now;
  final bool mine;
  final VoidCallback onViewers;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: story.authorPhotoUrl.isEmpty
                  ? const ColoredBox(
                      color: AppColors.primarySoft,
                      child: Icon(Icons.person, color: AppColors.primaryDeep),
                    )
                  : DogImage(url: story.authorPhotoUrl, seed: story.authorUserId),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  story.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  StoriesStrings.timeAgo(story.createdAt, now),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!mine)
            CompactFollowButton(
              ownerId: story.authorUserId,
              ownerName: story.authorName,
              color: Colors.white,
            ),
          if (mine)
            _ChromeButton(
              icon: Icons.delete_outline,
              tooltip: StoriesStrings.delete,
              onTap: onDelete,
            ),
          _ChromeButton(
            icon: Icons.close_rounded,
            tooltip: StoriesStrings.close,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
    // Tooltips on web re-enter the mouse tracker during story rebuilds.
    return kIsWeb ? button : Tooltip(message: tooltip, child: button);
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.controller,
    required this.focusNode,
    required this.liked,
    required this.sending,
    required this.onLike,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool liked;
  final bool sending;
  final VoidCallback onLike;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('story-reply-field'),
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 3,
              maxLength: 1000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                counterText: '',
                hintText: StoriesStrings.replyHint,
                hintStyle: const TextStyle(color: Colors.white70),
                isDense: true,
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('story-like-button'),
            tooltip: liked ? StoriesStrings.unlike : StoriesStrings.like,
            onPressed: onLike,
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? const Color(0xFFEF4444) : Colors.white,
            ),
          ),
          IconButton(
            key: const ValueKey('story-reply-send'),
            tooltip: StoriesStrings.send,
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hide_image_outlined, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            StoriesStrings.unavailable,
            key: const ValueKey('story-unavailable'),
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// Author only: who viewed my story and who liked it.
Future<void> showStoryViewersSheet(BuildContext context, Story story) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _StoryViewersSheet(story: story),
  );
}

class _StoryViewersSheet extends ConsumerWidget {
  const _StoryViewersSheet({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loader = ref.read(ownerProfileLoaderProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: FutureBuilder<List<StoryViewer>>(
          future: ref.read(storyActionsProvider).viewers(story),
          builder: (context, snapshot) {
            final Widget body;
            if (snapshot.hasError) {
              body = Center(child: Text(StoriesStrings.viewersFailed));
            } else if (!snapshot.hasData) {
              body = const Center(child: CircularProgressIndicator());
            } else if (snapshot.data!.isEmpty) {
              body = Center(child: Text(StoriesStrings.noViewers));
            } else {
              final viewers = snapshot.data!;
              body = ListView.builder(
                itemCount: viewers.length,
                itemBuilder: (context, i) => _ViewerTile(
                  viewer: viewers[i],
                  loader: loader,
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        StoriesStrings.viewers,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (snapshot.hasData)
                        Text(
                          '${snapshot.data!.length}',
                          style: theme.textTheme.titleMedium,
                        ),
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ViewerTile extends StatelessWidget {
  const _ViewerTile({required this.viewer, required this.loader});

  final StoryViewer viewer;
  final OwnerProfileLoader loader;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OwnerPublicProfile?>(
      future: loader(viewer.userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.name.trim().isNotEmpty == true
            ? profile!.name
            : 'Korisnik';
        final photo = profile?.photoUrl ?? '';
        return ListTile(
          leading: ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: photo.isEmpty
                  ? const ColoredBox(
                      color: AppColors.primarySoft,
                      child: Icon(Icons.person, color: AppColors.primaryDeep),
                    )
                  : DogImage(url: photo, seed: viewer.userId),
            ),
          ),
          title: Text(name),
          trailing: viewer.liked
              ? const Icon(Icons.favorite, color: Color(0xFFEF4444))
              : null,
        );
      },
    );
  }
}
