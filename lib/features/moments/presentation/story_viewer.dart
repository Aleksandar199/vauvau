import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/discover_controller.dart';
import '../../discover/presentation/widgets/dog_photo_gallery.dart';
import '../../discover/presentation/widgets/swipe_dog_card.dart';
import '../../moderation/domain/content_report.dart';
import '../../moderation/presentation/safety_menu.dart';
import '../domain/moment_model.dart';
import 'highlight_sheets.dart';
import 'moments_controller.dart';
import 'moments_strings.dart';
import 'pointer_safe.dart';
import 'stories_controller.dart';
import 'widgets/moment_comments_sheet.dart';

const Duration kStoryDuration = Duration(seconds: 6);

Future<void> openStoryViewer(
  BuildContext context, {
  required List<StoryGroup> groups,
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
        allowSnapshotting: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) =>
            StoryViewerScreen(groups: groups, initialGroup: page),
      ),
    );
  });
}

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.groups,
    this.initialGroup = 0,
  });

  final List<StoryGroup> groups;
  final int initialGroup;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialGroup,
  );
  late int _current = widget.initialGroup;
  final Set<String> _seenBuffer = {};
  late final SeenStories _seenNotifier;

  @override
  void initState() {
    super.initState();
    _seenNotifier = ref.read(seenStoriesProvider.notifier);
  }

  @override
  void dispose() {
    for (final id in _seenBuffer) {
      _seenNotifier.markSeen(id);
    }
    _pages.dispose();
    super.dispose();
  }

  void _flushSeen() {
    for (final id in _seenBuffer) {
      _seenNotifier.markSeen(id);
    }
    _seenBuffer.clear();
  }

  void _close() {
    if (!mounted) {
      return;
    }
    _flushSeen();
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
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _close();
    }
  }

  void _previousGroup() {
    if (_current > 0) {
      _pages.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.groups.length,
        onPageChanged: (value) => setState(() => _current = value),
        itemBuilder: (context, i) {
          final group = widget.groups[i];
          return StoryGroupView(
            key: ValueKey('${group.dogId}-${group.title ?? ''}-$i'),
            group: group,
            active: i == _current,
            onNextGroup: _nextGroup,
            onPreviousGroup: _previousGroup,
            onClose: _close,
            onViewed: _seenBuffer.add,
          );
        },
      ),
    );
  }
}

class StoryGroupView extends ConsumerStatefulWidget {
  const StoryGroupView({
    super.key,
    required this.group,
    required this.active,
    required this.onNextGroup,
    required this.onPreviousGroup,
    required this.onClose,
    required this.onViewed,
  });

  final StoryGroup group;
  final bool active;
  final VoidCallback onNextGroup;
  final VoidCallback onPreviousGroup;
  final VoidCallback onClose;
  final ValueChanged<String> onViewed;

  @override
  ConsumerState<StoryGroupView> createState() => _StoryGroupViewState();
}

class _StoryGroupViewState extends ConsumerState<StoryGroupView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: kStoryDuration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _next();
          }
        });
  late List<MomentModel> _items = [...widget.group.moments];
  int _index = 0;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant StoryGroupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _start();
    } else if (!widget.active && oldWidget.active) {
      _progress.stop();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  MomentModel get _moment => _items[_index.clamp(0, _items.length - 1)];

  void _start() {
    widget.onViewed(_moment.id);
    _progress.forward(from: 0);
  }

  void _next() {
    if (_index < _items.length - 1) {
      setState(() => _index++);
      _start();
    } else {
      _progress.stop();
      widget.onNextGroup();
    }
  }

  void _previous() {
    if (_index > 0) {
      setState(() => _index--);
      _start();
    } else {
      _start();
      widget.onPreviousGroup();
    }
  }

  void _pause() => _progress.stop();

  void _resume() {
    if (mounted && widget.active && !_held) {
      _progress.forward();
    }
  }

  Future<T?> _whilePaused<T>(Future<T?> Function() action) async {
    _pause();
    try {
      return await action();
    } finally {
      _resume();
    }
  }

  Future<void> _deleteCurrent() async {
    final moment = _moment;
    final confirmed = await _whilePaused(
      () => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(MomentsStrings.deleteStory),
          content: const Text(MomentsStrings.deleteStoryBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(MomentsStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(MomentsStrings.delete),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(momentsControllerProvider.notifier).delete(moment.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = [..._items]..removeWhere((item) => item.id == moment.id);
      if (_index >= _items.length) {
        _index = _items.length - 1;
      }
    });
    if (_items.isEmpty) {
      widget.onNextGroup();
    } else {
      _start();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }
    final all = ref.watch(momentsControllerProvider).asData?.value ?? const [];
    final snapshot = _moment;
    final moment = all.firstWhere(
      (item) => item.id == snapshot.id,
      orElse: () => snapshot,
    );
    final me = ref.watch(momentsMemberIdProvider);
    final isMine = me.isNotEmpty && moment.authorUserId == me;
    final liked = moment.isLikedBy(me);
    final now = DateTime.now();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final box = context.findRenderObject() as RenderBox?;
        final width = box?.size.width ?? MediaQuery.sizeOf(context).width;
        if (details.localPosition.dx < width * 0.3) {
          _previous();
        } else {
          _next();
        }
      },
      onLongPressStart: (_) {
        _held = true;
        _pause();
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
          BlurBackdropPhoto(url: moment.momentPhotoUrl, seed: moment.id),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.22, 0.62, 1],
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < _items.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: AnimatedBuilder(
                              animation: _progress,
                              builder: (context, _) => LinearProgressIndicator(
                                minHeight: 3,
                                value: i < _index
                                    ? 1
                                    : i == _index
                                    ? _progress.value
                                    : 0,
                                backgroundColor: Colors.white30,
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _whilePaused(
                          () => openMomentDog(context, ref, moment),
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: DogImage(
                                  url: moment.dogPhotoUrl,
                                  seed: moment.dogId,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.group.title ?? moment.dogName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              widget.group.title == null
                                  ? MomentsStrings.timeAgo(
                                      moment.createdAt,
                                      now,
                                    )
                                  : '${moment.dogName} · ${MomentsStrings.timeAgo(moment.createdAt, now)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMine) ...[
                        _ChromeIconButton(
                          icon: Icons.bookmark_add_outlined,
                          tooltip: MomentsStrings.addToHighlight,
                          onPressed: () => _whilePaused(
                            () => showAddToHighlightSheet(context, moment),
                          ),
                        ),
                        _ChromeIconButton(
                          icon: Icons.delete_outline,
                          tooltip: MomentsStrings.deleteStory,
                          onPressed: () => _whilePaused(_deleteCurrent),
                        ),
                      ] else if (moment.authorUserId.isNotEmpty && !kIsWeb)
                        SafetyMenuButton(
                          reportedUserId: moment.authorUserId,
                          targetId: moment.id,
                          targetType: ReportContentType.moment,
                          iconColor: Colors.white,
                          onBlocked: widget.onClose,
                        ),
                      _ChromeIconButton(
                        icon: Icons.close_rounded,
                        tooltip: MomentsStrings.close,
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (moment.caption.trim().isNotEmpty)
                        Text(
                          moment.caption.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                      if (moment.locationName.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                moment.locationName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      _StoryAction(
                        icon: liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? const Color(0xFFEF4444) : Colors.white,
                        label: '${moment.likeCount}',
                        tooltip: MomentsStrings.like,
                        onTap: () => ref
                            .read(momentsControllerProvider.notifier)
                            .toggleLike(moment.id),
                      ),
                      _StoryAction(
                        icon: Icons.chat_bubble_outline,
                        label: '${moment.commentsCount}',
                        tooltip: MomentsStrings.comment,
                        onTap: () => _whilePaused(
                          () => showMomentCommentsSheet(context, moment.id),
                        ),
                      ),
                      const Spacer(),
                      if (isMine)
                        _StoryAction(
                          icon: Icons.bookmark_add_outlined,
                          label: '',
                          tooltip: MomentsStrings.addToHighlight,
                          onTap: () => _whilePaused(
                            () => showAddToHighlightSheet(context, moment),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white),
      ),
    );
    if (kIsWeb || tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

class _StoryAction extends StatelessWidget {
  const _StoryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tooltip,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    // Tooltips register mouse regions; on web that re-enters the mouse
    // tracker during story rebuilds and trips !_debugDuringDeviceUpdate.
    if (kIsWeb) {
      return button;
    }
    return Tooltip(message: tooltip ?? label, child: button);
  }
}

Future<void> openMomentDog(
  BuildContext context,
  WidgetRef ref,
  MomentModel moment,
) {
  final discover = ref.read(discoverControllerProvider);
  DiscoverProfile? profile;
  for (final dog in [
    discover.myDog,
    ...ref.read(discoverFeedProvider),
    ...discover.catalog,
  ]) {
    if (dog.id == moment.dogId) {
      profile = dog;
      break;
    }
  }
  profile ??= DiscoverProfile(
    id: moment.dogId,
    name: moment.dogName,
    ownerName: moment.authorName,
    ownerId: moment.authorUserId,
    breed: moment.dogBreed,
    ageYears: 1,
    gender: '',
    size: '',
    location: moment.locationName,
    bio: '',
    photoUrls: [moment.dogPhotoUrl],
  );
  return afterPointerSettles(() async {
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DogDetailSheet(profile: profile!),
    );
  });
}
