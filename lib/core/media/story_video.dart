import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_controller.dart';

/// Full-screen video inside a story player. The parent owns the timing:
/// [onReady] reports the length (the parent sets the progress bar to it),
/// and [playing] follows the progress (paused while held, while typing a
/// reply, or while a sheet is open). Give each shown item its own key so a
/// replay starts from the beginning.
class StoryVideo extends StatefulWidget {
  const StoryVideo({
    super.key,
    required this.source,
    required this.playing,
    required this.onReady,
    required this.onError,
    this.muted = false,
  });

  /// Local file path, or a URL on web.
  final String source;
  final bool playing;
  final ValueChanged<Duration> onReady;
  final VoidCallback onError;
  final bool muted;

  @override
  State<StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends State<StoryVideo> {
  late final VideoPlayerController _controller =
      videoControllerFor(widget.source);
  var _ready = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.setVolume(widget.muted ? 0 : 1);
      if (!mounted) {
        return;
      }
      setState(() => _ready = true);
      widget.onReady(_controller.value.duration);
      _sync();
    } catch (error) {
      debugPrint('story video failed: $error');
      if (mounted) {
        setState(() => _failed = true);
        widget.onError();
      }
    }
  }

  @override
  void didUpdateWidget(covariant StoryVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) {
      _sync();
    }
    if (oldWidget.muted != widget.muted && _ready) {
      _controller.setVolume(widget.muted ? 0 : 1);
    }
  }

  void _sync() {
    if (!_ready) {
      return;
    }
    if (widget.playing && !_controller.value.isPlaying) {
      _controller.play();
    } else if (!widget.playing && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 48),
      );
    }
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }
    final size = _controller.value.size;
    return Center(
      child: AspectRatio(
        aspectRatio: size.height == 0 ? 9 / 16 : size.width / size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

/// Progress bar length for a video item: its own length, capped so a long
/// file (older client, bad metadata) cannot stall the player.
Duration storyVideoItemDuration(Duration videoLength, Duration max) {
  if (videoLength <= Duration.zero) {
    return const Duration(seconds: 6);
  }
  final capped = videoLength > max ? max : videoLength;
  return capped < const Duration(seconds: 1)
      ? const Duration(seconds: 1)
      : capped;
}
