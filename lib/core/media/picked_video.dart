import 'dart:async';

import 'package:image_picker/image_picker.dart';

import 'video_controller.dart';
import 'video_limits.dart';

/// Reads a video's length (null when the player cannot open it).
typedef VideoProbe = Future<Duration?> Function(XFile file);

/// A picked video that passed [checkVideo].
class PickedVideo {
  const PickedVideo({
    required this.file,
    required this.duration,
    required this.sizeBytes,
    required this.contentType,
  });

  final XFile file;
  final Duration duration;
  final int sizeBytes;
  final String contentType;
}

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

/// Size + length check of a picked file. Returns the video or the problem.
Future<({PickedVideo? video, VideoProblem? problem})> inspectPickedVideo(
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
/// [maxDuration]; the gallery cannot be limited, so [inspectPickedVideo]
/// checks the result.
Future<XFile?> pickVideoFile(ImageSource source, Duration maxDuration) {
  return ImagePicker().pickVideo(source: source, maxDuration: maxDuration);
}
