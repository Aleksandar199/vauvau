import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_controller.dart';
import 'video_strings.dart';

/// A video that plays only after a tap (feed cards, previews).
///
/// Nothing is downloaded until the first tap unless [initializeEagerly]
/// (local previews show their first frame). Muted by default; at most one
/// [TapToPlayVideo] plays at a time across the app. Tap = play / pause.
class TapToPlayVideo extends StatefulWidget {
  const TapToPlayVideo({
    super.key,
    required this.source,
    this.fit = BoxFit.contain,
    this.initializeEagerly = false,
    this.loop = true,
    this.durationLabel,
  });

  /// Local file path, blob: URL (web) or https URL.
  final String source;
  final BoxFit fit;
  final bool initializeEagerly;
  final bool loop;

  /// Shown on the poster before the video is loaded (e.g. "0:12").
  final String? durationLabel;

  /// The one playing right now (others pause when it changes).
  @visibleForTesting
  static final ValueNotifier<Object?> active = ValueNotifier(null);

  @override
  State<TapToPlayVideo> createState() => _TapToPlayVideoState();
}

class _TapToPlayVideoState extends State<TapToPlayVideo> {
  VideoPlayerController? _controller;
  Future<void>? _init;
  var _failed = false;
  var _muted = true;

  @override
  void initState() {
    super.initState();
    TapToPlayVideo.active.addListener(_onActiveChanged);
    if (widget.initializeEagerly) {
      _ensureInitialized();
    }
  }

  @override
  void didUpdateWidget(covariant TapToPlayVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _disposeController();
      _failed = false;
      if (widget.initializeEagerly) {
        _ensureInitialized();
      }
    }
  }

  @override
  void dispose() {
    TapToPlayVideo.active.removeListener(_onActiveChanged);
    if (TapToPlayVideo.active.value == this) {
      TapToPlayVideo.active.value = null;
    }
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    _init = null;
    controller?.removeListener(_onTick);
    if (controller != null) {
      unawaited(controller.dispose());
    }
  }

  void _onActiveChanged() {
    final controller = _controller;
    if (TapToPlayVideo.active.value != this &&
        controller != null &&
        controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _ensureInitialized() {
    final existing = _init;
    if (existing != null) {
      return existing;
    }
    final controller = videoControllerFor(widget.source);
    _controller = controller;
    final init = () async {
      try {
        await controller.initialize();
        await controller.setLooping(widget.loop);
        await controller.setVolume(_muted ? 0 : 1);
        controller.addListener(_onTick);
      } catch (error) {
        debugPrint('video init failed: $error');
        if (mounted && _controller == controller) {
          setState(() => _failed = true);
        }
      }
      if (mounted) {
        setState(() {});
      }
    }();
    _init = init;
    return init;
  }

  Future<void> _toggle() async {
    if (_failed) {
      return;
    }
    final pending = _ensureInitialized();
    setState(() {}); // spinner while loading
    await pending;
    final controller = _controller;
    if (!mounted || controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      TapToPlayVideo.active.value = this;
      await controller.play();
    }
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    setState(() => _muted = !_muted);
    await controller?.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final playing = ready && controller.value.isPlaying;
    final loading = controller != null && !ready && !_failed;
    return Semantics(
      button: true,
      label: playing ? VideoStrings.pause : VideoStrings.play,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ready)
                FittedBox(
                  fit: widget.fit,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              if (_failed)
                _Overlay(
                  icon: Icons.videocam_off_outlined,
                  text: VideoStrings.unavailable,
                )
              else if (loading)
                const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (!playing)
                Center(
                  child: Container(
                    key: const ValueKey('video-play-button'),
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0x8C000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              if (!ready && !_failed && widget.durationLabel != null)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _Chip(
                    icon: Icons.videocam_rounded,
                    text: widget.durationLabel!,
                  ),
                ),
              if (ready)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: IconButton(
                    key: const ValueKey('video-mute'),
                    tooltip: _muted ? VideoStrings.unmute : VideoStrings.mute,
                    onPressed: _toggleMute,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x8C000000),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(36, 36),
                    ),
                    icon: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      size: 20,
                    ),
                  ),
                ),
              if (ready)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: false,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 40),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x8C000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "video" badge for thumbnails (grids, highlights, admin).
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({super.key, this.iconSize = 28});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2B2B), Color(0xFF111111)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: Colors.white,
          size: iconSize,
          semanticLabel: VideoStrings.video,
        ),
      ),
    );
  }
}
