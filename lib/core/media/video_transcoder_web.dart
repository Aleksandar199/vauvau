import 'video_transcoder_api.dart';

/// Web: no re-encoding (no native encoder); the picked file is checked
/// against the limits as it is.
class PlatformVideoTranscoder implements VideoTranscoder {
  const PlatformVideoTranscoder();

  @override
  bool get isSupported => false;


  @override
  Future<TranscodedVideo?> transcode({
    required String path,
    required VideoTargetQuality quality,
    int? startTime,
    int? duration,
    void Function(double progress)? onProgress,
  }) async => null;

  @override
  Future<void> clearCache() async {}
}
