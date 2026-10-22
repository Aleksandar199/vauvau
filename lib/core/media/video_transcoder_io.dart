import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_compressor_plus/video_compressor_plus.dart';

import 'video_transcoder_api.dart';

/// Android: MediaCodec (Transcoder). iOS: AVAssetExportSession. No FFmpeg.
class PlatformVideoTranscoder implements VideoTranscoder {
  const PlatformVideoTranscoder();


  @override
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<TranscodedVideo?> transcode({
    required String path,
    required VideoTargetQuality quality,
    int? startTime,
    int? duration,
    void Function(double progress)? onProgress,
  }) async {
    final subscription = VideoCompress.compressProgress$.subscribe((value) {
      onProgress?.call((value / 100).clamp(0.0, 1.0));
    });
    try {
      final info = await VideoCompress.compressVideo(
        path,
        quality: switch (quality) {
          VideoTargetQuality.hd720 => VideoQuality.Res1280x720Quality,
          VideoTargetQuality.sd540 => VideoQuality.Res960x540Quality,
        },
        startTime: startTime,
        duration: duration,
        includeAudio: true,
        frameRate: 30,
      );
      final out = info?.path;
      if (info == null || info.isCancel == true || out == null) {
        return null;
      }
      final file = File(out);
      if (!await file.exists()) {
        return null;
      }
      return TranscodedVideo(path: out, sizeBytes: await file.length());
    } catch (error) {
      debugPrint('video transcode failed: $error');
      return null;
    } finally {
      subscription.unsubscribe();
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}
  }
}
