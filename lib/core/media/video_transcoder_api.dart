/// Output size of an upload video. The longer side is capped, the aspect
/// ratio and rotation are kept.
enum VideoTargetQuality {
  /// At most 1280×720 (portrait 720×1280). First choice.
  hd720,

  /// At most 960×540. Second pass when 720p is still too large.
  sd540,
}

/// One finished re-encode (a new mp4 in the app's cache folder).
class TranscodedVideo {
  const TranscodedVideo({required this.path, required this.sizeBytes});

  final String path;
  final int sizeBytes;
}

/// Shrinks (and optionally trims) a picked video on the phone.
abstract class VideoTranscoder {
  /// False on web: the browser cannot re-encode, so only the limits apply.
  bool get isSupported;

  /// [startTime] / [duration] are passed to the plugin as they are; build
  /// them with [trimArguments]. Null when the phone could not encode it.
  Future<TranscodedVideo?> transcode({
    required String path,
    required VideoTargetQuality quality,
    int? startTime,
    int? duration,
    void Function(double progress)? onProgress,
  });

  /// Deletes re-encoded files (after publishing or closing the form).
  Future<void> clearCache();
}
