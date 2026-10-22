/// Limits for short videos in stories and Moments posts, and the pure
/// decision whether a video may be uploaded.
///
/// Users pick or record in whatever quality the phone has; on Android / iOS
/// the app re-encodes to at most 720p (~4 Mbit/s, so 15 s ≈ 7–8 MB) and keeps
/// only the first [maxDuration] (`prepareVideoForUpload`). [maxBytes] is a
/// safety net (a second 540p pass, then refusal) and the same limit as
/// storage.rules; every view downloads the whole file (Storage quota).
class VideoLimits {
  const VideoLimits._();

  /// Stories and posts: a short clip.
  static const Duration maxDuration = Duration(seconds: 15);

  /// Same limit as `isValidVideo()` in storage.rules (strictly less than).
  static const int maxBytes = 20 * 1024 * 1024;

  /// Picker / container rounding: a 15.4 s clip from a 15 s camera limit
  /// is still accepted.
  static const Duration tolerance = Duration(milliseconds: 900);

  static const Set<String> allowedMimeTypes = {
    'video/mp4',
    'video/quicktime',
    'video/webm',
    'video/3gpp',
  };
}

enum VideoProblem { tooLong, tooLarge, empty, unreadable }

/// Null = OK. [duration] null means the video could not be read (no
/// duration from the player) – such a file would not play either.
VideoProblem? checkVideo({
  required int sizeBytes,
  required Duration? duration,
  required Duration maxDuration,
  int maxBytes = VideoLimits.maxBytes,
}) {
  if (sizeBytes <= 0) {
    return VideoProblem.empty;
  }
  if (sizeBytes >= maxBytes) {
    return VideoProblem.tooLarge;
  }
  if (duration == null || duration <= Duration.zero) {
    return VideoProblem.unreadable;
  }
  if (duration > maxDuration + VideoLimits.tolerance) {
    return VideoProblem.tooLong;
  }
  return null;
}

/// Content type stored in Storage: the picker's mime type when it is a
/// known video type, otherwise from the file extension; mp4 by default.
String videoContentType({String? mimeType, String fileName = ''}) {
  final mime = mimeType?.trim().toLowerCase() ?? '';
  if (VideoLimits.allowedMimeTypes.contains(mime)) {
    return mime;
  }
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.mov')) {
    return 'video/quicktime';
  }
  if (lower.endsWith('.webm')) {
    return 'video/webm';
  }
  if (lower.endsWith('.3gp')) {
    return 'video/3gpp';
  }
  return 'video/mp4';
}

String videoExtension(String contentType) {
  switch (contentType) {
    case 'video/quicktime':
      return '.mov';
    case 'video/webm':
      return '.webm';
    case 'video/3gpp':
      return '.3gp';
    default:
      return '.mp4';
  }
}

/// "0:07" style label for a video length.
String formatVideoDuration(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
