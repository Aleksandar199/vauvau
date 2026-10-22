import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'video_controller.dart';
import 'video_limits.dart';
import 'video_transcoder.dart';

/// Reads a video's length (null when the player cannot open it).
typedef VideoProbe = Future<Duration?> Function(XFile file);

/// A video ready for upload: at most [VideoLimits.maxDuration] long, under
/// [VideoLimits.maxBytes], re-encoded to ≤ 720p on Android / iOS.
class PickedVideo {
  const PickedVideo({
    required this.file,
    required this.duration,
    required this.sizeBytes,
    required this.contentType,
    this.wasTrimmed = false,
  });

  final XFile file;
  final Duration duration;
  final int sizeBytes;
  final String contentType;

  /// The original was longer; only its first 15 s are kept.
  final bool wasTrimmed;
}

typedef VideoCheckResult = ({PickedVideo? video, VideoProblem? problem});

Future<Duration?> probeVideoDuration(XFile file) async {
  final controller = videoControllerFor(file.path);
  try {
    await controller.initialize().timeout(const Duration(seconds: 12));
    final duration = controller.value.duration;
    return duration > Duration.zero ? duration : null;
  } catch (_) {
    return null;
  } finally {
    unawaited(controller.dispose());
  }
}

/// `startTime` / `duration` for the plugin to keep the first [max] of a
/// [total] long video; both null when no trim is needed.
///
/// The plugin passes them differently per platform: iOS keeps `duration`
/// seconds from `startTime`, while Android hands `duration` to Transcoder's
/// `TrimDataSource` as the time CUT FROM THE END. Rounding always keeps the
/// result at or under [max] (a 40.6 s clip on Android: cut 26 s → 14.6 s).
({int? startTime, int? duration}) trimArguments({
  required Duration total,
  required Duration max,
  required bool android,
}) {
  if (total <= max + VideoLimits.tolerance) {
    return (startTime: null, duration: null);
  }
  if (android) {
    final cutMs = (total - max).inMilliseconds;
    return (startTime: 0, duration: (cutMs / 1000).ceil());
  }
  return (startTime: 0, duration: max.inSeconds);
}

/// Picked file → upload-ready video.
///
/// Android / iOS: always re-encoded to ≤ 720p (whatever quality the phone
/// recorded), longer videos keep their first [maxDuration]; if 720p is
/// still ≥ 20 MB a 540p pass follows. The result is checked again (length
/// and size), so a plugin that did not trim or shrink is never uploaded.
/// Web: no encoder, the file must already fit the limits.
Future<VideoCheckResult> prepareVideoForUpload(
  XFile file, {
  required Duration maxDuration,
  VideoProbe? probe,
  VideoTranscoder transcoder = const PlatformVideoTranscoder(),
  bool? android,
  void Function(double progress)? onProgress,
}) async {
  final read = probe ?? probeVideoDuration;
  if (!transcoder.isSupported) {
    return inspectPickedVideo(file, maxDuration: maxDuration, probe: read);
  }
  final total = await read(file);
  if (total == null) {
    return (video: null, problem: VideoProblem.unreadable);
  }
  final trim = trimArguments(
    total: total,
    max: maxDuration,
    android: android ?? defaultTargetPlatform == TargetPlatform.android,
  );
  VideoCheckResult? last;
  const passes = [VideoTargetQuality.hd720, VideoTargetQuality.sd540];
  for (var i = 0; i < passes.length; i++) {
    final out = await transcoder.transcode(
      path: file.path,
      quality: passes[i],
      startTime: trim.startTime,
      duration: trim.duration,
      onProgress: onProgress == null
          ? null
          : (value) => onProgress((i + value) / passes.length),
    );
    if (out == null) {
      // Encoder failed: the original is still fine if it already fits.
      return inspectPickedVideo(file, maxDuration: maxDuration, probe: read);
    }
    final result = XFile(
      out.path,
      name: out.path.split(RegExp(r'[\\/]')).last,
      mimeType: 'video/mp4',
      length: out.sizeBytes,
    );
    final length = await read(result);
    final problem = checkVideo(
      sizeBytes: out.sizeBytes,
      duration: length,
      maxDuration: maxDuration,
    );
    last = (
      video: problem == null
          ? PickedVideo(
              file: result,
              duration: length!,
              sizeBytes: out.sizeBytes,
              contentType: 'video/mp4',
              wasTrimmed: trim.duration != null,
            )
          : null,
      problem: problem,
    );
    // Only "too large" gets a smaller second pass.
    if (problem != VideoProblem.tooLarge) {
      break;
    }
  }
  onProgress?.call(1);
  return last!;
}

/// Size + length check of a file as it is (web, tests).
Future<VideoCheckResult> inspectPickedVideo(
  XFile file, {
  required Duration maxDuration,
  VideoProbe? probe,
}) async {
  final size = await file.length();
  // Size first: no need to open a 200 MB file in the player.
  final early = checkVideo(
    sizeBytes: size,
    duration: const Duration(seconds: 1),
    maxDuration: maxDuration,
  );
  if (early != null) {
    return (video: null, problem: early);
  }
  final duration = await (probe ?? probeVideoDuration)(file);
  final problem = checkVideo(
    sizeBytes: size,
    duration: duration,
    maxDuration: maxDuration,
  );
  if (problem != null) {
    return (video: null, problem: problem);
  }
  return (
    video: PickedVideo(
      file: file,
      duration: duration!,
      sizeBytes: size,
      contentType: videoContentType(
        mimeType: file.mimeType,
        fileName: file.name,
      ),
    ),
    problem: null,
  );
}

/// Opens the gallery / camera for a video. The camera stops at
/// [maxDuration]; a longer gallery video is trimmed by
/// [prepareVideoForUpload].
Future<XFile?> pickVideoFile(ImageSource source, Duration maxDuration) {
  return ImagePicker().pickVideo(source: source, maxDuration: maxDuration);
}
