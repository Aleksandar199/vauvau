import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vauvau/core/media/picked_video.dart';
import 'package:vauvau/core/media/story_video.dart';
import 'package:vauvau/core/media/tap_to_play_video.dart';
import 'package:vauvau/core/media/video_limits.dart';
import 'package:vauvau/core/media/video_strings.dart';
import 'package:vauvau/core/media/video_transcoder.dart';
import 'package:vauvau/core/widgets/media_source_row.dart';
import 'package:vauvau/features/moments/data/firestore_moments_repository.dart';
import 'package:vauvau/features/moments/domain/moment_model.dart';
import 'package:vauvau/features/stories/domain/story.dart';
import 'package:vauvau/services/storage_service.dart';

void main() {
  group('checkVideo', () {
    const story = VideoLimits.maxDuration;

    test('accepts a short, small video', () {
      expect(
        checkVideo(
          sizeBytes: 5 * 1024 * 1024,
          duration: const Duration(seconds: 14),
          maxDuration: story,
        ),
        isNull,
      );
    });

    test('stories and posts share the 15 s limit', () {
      expect(VideoLimits.maxDuration, const Duration(seconds: 15));
    });

    test('rounding up to the tolerance is fine, longer is too long', () {
      expect(
        checkVideo(
          sizeBytes: 1000,
          duration: const Duration(milliseconds: 15800),
          maxDuration: story,
        ),
        isNull,
      );
      expect(
        checkVideo(
          sizeBytes: 1000,
          duration: const Duration(seconds: 16),
          maxDuration: story,
        ),
        VideoProblem.tooLong,
      );
    });

    test('size: 20 MB and more is refused (same as storage.rules)', () {
      expect(
        checkVideo(
          sizeBytes: VideoLimits.maxBytes,
          duration: const Duration(seconds: 5),
          maxDuration: story,
        ),
        VideoProblem.tooLarge,
      );
      expect(
        checkVideo(
          sizeBytes: VideoLimits.maxBytes - 1,
          duration: const Duration(seconds: 5),
          maxDuration: story,
        ),
        isNull,
      );
    });

    test('empty file and unknown length are refused', () {
      expect(
        checkVideo(sizeBytes: 0, duration: null, maxDuration: story),
        VideoProblem.empty,
      );
      expect(
        checkVideo(sizeBytes: 10, duration: null, maxDuration: story),
        VideoProblem.unreadable,
      );
      expect(
        checkVideo(sizeBytes: 10, duration: Duration.zero, maxDuration: story),
        VideoProblem.unreadable,
      );
    });

    test('every problem has a message naming the limit', () {
      for (final problem in VideoProblem.values) {
        expect(VideoStrings.problem(problem, story), isNotEmpty);
      }
      expect(VideoStrings.problem(VideoProblem.tooLong, story), contains('15'));
      expect(
        VideoStrings.problem(VideoProblem.tooLarge, story),
        contains('20 MB'),
      );
    });
  });

  group('inspectPickedVideo', () {
    XFile file(int size) => XFile.fromData(
          Uint8List(size),
          name: 'clip.mov',
          mimeType: 'video/quicktime',
        );

    test('returns the video with its type and length', () async {
      final result = await inspectPickedVideo(
        file(4096),
        maxDuration: VideoLimits.maxDuration,
        probe: (_) async => const Duration(seconds: 9),
      );
      expect(result.problem, isNull);
      expect(result.video!.duration, const Duration(seconds: 9));
      expect(result.video!.sizeBytes, 4096);
      expect(result.video!.contentType, 'video/quicktime');
    });

    test('too long video is refused', () async {
      final result = await inspectPickedVideo(
        file(4096),
        maxDuration: VideoLimits.maxDuration,
        probe: (_) async => const Duration(seconds: 40),
      );
      expect(result.video, isNull);
      expect(result.problem, VideoProblem.tooLong);
    });

    test('too large video is refused without opening it', () async {
      var probed = false;
      final result = await inspectPickedVideo(
        file(VideoLimits.maxBytes + 1),
        maxDuration: VideoLimits.maxDuration,
        probe: (_) async {
          probed = true;
          return const Duration(seconds: 5);
        },
      );
      expect(result.problem, VideoProblem.tooLarge);
      expect(probed, isFalse);
    });

    test('unreadable video is refused', () async {
      final result = await inspectPickedVideo(
        file(4096),
        maxDuration: VideoLimits.maxDuration,
        probe: (_) async => null,
      );
      expect(result.problem, VideoProblem.unreadable);
    });
  });

  group('trimArguments', () {
    const max = VideoLimits.maxDuration;

    test('no trim up to 15 s (+ rounding tolerance)', () {
      for (final android in [true, false]) {
        expect(
          trimArguments(
            total: const Duration(milliseconds: 15800),
            max: max,
            android: android,
          ),
          (startTime: null, duration: null),
        );
      }
    });

    test('Android: duration = seconds cut from the end, rounded up', () {
      // 40.6 s → cut 26 s → 14.6 s kept (never more than 15 s).
      expect(
        trimArguments(
          total: const Duration(milliseconds: 40600),
          max: max,
          android: true,
        ),
        (startTime: 0, duration: 26),
      );
      expect(
        trimArguments(
          total: const Duration(seconds: 16),
          max: max,
          android: true,
        ),
        (startTime: 0, duration: 1),
      );
    });

    test('iOS: duration = seconds kept', () {
      expect(
        trimArguments(
          total: const Duration(minutes: 3),
          max: max,
          android: false,
        ),
        (startTime: 0, duration: 15),
      );
    });
  });

  group('prepareVideoForUpload', () {
    final source = XFile.fromData(
      Uint8List(4096),
      name: 'IMG_0001.MOV',
      mimeType: 'video/quicktime',
      path: '/source.mov',
    );

    test('long 4K video: first 15 s kept, re-encoded to 720p mp4', () async {
      final t = _FakeTranscoder({VideoTargetQuality.hd720: 8 * 1024 * 1024});
      final progress = <double>[];
      final result = await prepareVideoForUpload(
        source,
        maxDuration: VideoLimits.maxDuration,
        transcoder: t,
        android: true,
        onProgress: progress.add,
        probe: (file) async => file.path == '/source.mov'
            ? const Duration(seconds: 42)
            : const Duration(milliseconds: 14800),
      );
      expect(result.problem, isNull);
      final video = result.video!;
      expect(video.wasTrimmed, isTrue);
      expect(video.contentType, 'video/mp4');
      expect(video.sizeBytes, 8 * 1024 * 1024);
      expect(video.file.path, '/out_hd720.mp4');
      expect(t.calls, [(VideoTargetQuality.hd720, 0, 27)]);
      expect(progress.last, 1);
    });

    test('still too large at 720p → second pass at 540p', () async {
      final t = _FakeTranscoder({
        VideoTargetQuality.hd720: VideoLimits.maxBytes + 10,
        VideoTargetQuality.sd540: 9 * 1024 * 1024,
      });
      final result = await prepareVideoForUpload(
        source,
        maxDuration: VideoLimits.maxDuration,
        transcoder: t,
        android: false,
        probe: (_) async => const Duration(seconds: 12),
      );
      expect(result.problem, isNull);
      expect(result.video!.wasTrimmed, isFalse);
      expect(result.video!.file.path, '/out_sd540.mp4');
      expect(t.calls.map((c) => c.$1), [
        VideoTargetQuality.hd720,
        VideoTargetQuality.sd540,
      ]);
      expect(t.calls.first.$2, isNull, reason: '12 s needs no trim');
    });

    test('too large even at 540p is refused', () async {
      final t = _FakeTranscoder({
        VideoTargetQuality.hd720: VideoLimits.maxBytes + 10,
        VideoTargetQuality.sd540: VideoLimits.maxBytes + 5,
      });
      final result = await prepareVideoForUpload(
        source,
        maxDuration: VideoLimits.maxDuration,
        transcoder: t,
        probe: (_) async => const Duration(seconds: 10),
      );
      expect(result.problem, VideoProblem.tooLarge);
    });

    test('a result that was not trimmed is never accepted', () async {
      // e.g. an encoder that ignored the trim: still 40 s after encoding.
      final t = _FakeTranscoder({VideoTargetQuality.hd720: 5 * 1024 * 1024});
      final result = await prepareVideoForUpload(
        source,
        maxDuration: VideoLimits.maxDuration,
        transcoder: t,
        android: false,
        probe: (_) async => const Duration(seconds: 40),
      );
      expect(result.problem, VideoProblem.tooLong);
      expect(t.calls, hasLength(1), reason: 'only size gets a second pass');
    });

    test('unreadable source and failed encoder', () async {
      final unreadable = await prepareVideoForUpload(
        source,
        maxDuration: VideoLimits.maxDuration,
        transcoder: _FakeTranscoder(const {}),
        probe: (_) async => null,
      );
      expect(unreadable.problem, VideoProblem.unreadable);

      // Encoder failed: a source that already fits is used as it is.
      final fallback = await prepareVideoForUpload(
        source,
        maxDuration: VideoLimits.maxDuration,
        transcoder: _FakeTranscoder(const {}),
        probe: (_) async => const Duration(seconds: 8),
      );
      expect(fallback.problem, isNull);
      expect(fallback.video!.file.path, '/source.mov');
    });

    test('web (no encoder): only the limits are checked', () async {
      final t = _FakeTranscoder(const {}, supported: false);
      final result = await prepareVideoForUpload(
        source,
        maxDuration: VideoLimits.maxDuration,
        transcoder: t,
        probe: (_) async => const Duration(seconds: 30),
      );
      expect(result.problem, VideoProblem.tooLong);
      expect(t.calls, isEmpty);
    });
  });

  group('content types', () {
    test('mime type wins, then extension, mp4 by default', () {
      expect(videoContentType(mimeType: 'video/webm'), 'video/webm');
      expect(videoContentType(fileName: 'a.MOV'), 'video/quicktime');
      expect(videoContentType(fileName: 'a.3gp'), 'video/3gpp');
      expect(videoContentType(mimeType: 'video/*', fileName: 'x'), 'video/mp4');
      expect(videoExtension('video/quicktime'), '.mov');
      expect(videoExtension('video/mp4'), '.mp4');
    });

    test('video bytes are recognised (story copied to a highlight)', () {
      Uint8List ftyp(String brand) => Uint8List.fromList([
            0,
            0,
            0,
            0x20,
            ...'ftyp'.codeUnits,
            ...brand.codeUnits,
          ]);
      expect(StorageService.sniffVideoContentType(ftyp('isom')), 'video/mp4');
      expect(
        StorageService.sniffVideoContentType(ftyp('qt  ')),
        'video/quicktime',
      );
      expect(StorageService.sniffVideoContentType(ftyp('3gp4')), 'video/3gpp');
      expect(
        StorageService.sniffVideoContentType(
          Uint8List.fromList([0x1A, 0x45, 0xDF, 0xA3, 0]),
        ),
        'video/webm',
      );
      expect(
        StorageService.sniffVideoContentType(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
        ),
        isNull,
      );
    });

    test('duration label', () {
      expect(formatVideoDuration(const Duration(seconds: 7)), '0:07');
      expect(formatVideoDuration(const Duration(seconds: 30)), '0:30');
    });

    test('story progress follows the video, capped', () {
      const max = Duration(seconds: 16);
      expect(
        storyVideoItemDuration(const Duration(seconds: 9), max),
        const Duration(seconds: 9),
      );
      expect(storyVideoItemDuration(const Duration(minutes: 2), max), max);
      expect(
        storyVideoItemDuration(Duration.zero, max),
        const Duration(seconds: 6),
      );
    });
  });

  group('old documents stay photos', () {
    test('moment without mediaType is an image; video is read', () {
      final legacy = momentFromMap('m1', {
        'authorUserId': 'a',
        'momentPhotoUrl': 'https://x/1.jpg',
      });
      expect(legacy.mediaType, MomentMediaType.image);
      expect(legacy.isVideo, isFalse);
      final video = momentFromMap('m2', {
        'kind': 'post',
        'authorUserId': 'a',
        'momentPhotoUrl': 'https://x/2.mp4',
        'mediaType': 'video',
      });
      expect(video.isVideo, isTrue);
      expect(momentFromMap('m3', {'mediaType': 'gif'}).isVideo, isFalse);
      expect(video.copyWith(likes: ['b']).isVideo, isTrue);
    });

    test('story media type', () {
      expect(StoryMediaType.fromKey(null), StoryMediaType.image);
      expect(StoryMediaType.fromKey('image'), StoryMediaType.image);
      expect(StoryMediaType.fromKey('video'), StoryMediaType.video);
      expect(StoryMediaType.fromKey(42), StoryMediaType.image);
    });
  });

  group('MediaSourceRow', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            // The app theme makes buttons full width; the row must not care.
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      );
    }

    testWidgets('Galerija and Kamera are equal tiles in one row', (
      tester,
    ) async {
      var video = false;
      final taps = <String>[];
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => MediaSourceRow(
            video: video,
            onVideoChanged: (value) => setState(() => video = value),
            onGallery: () => taps.add('gallery'),
            onCamera: () => taps.add('camera'),
          ),
        ),
      );
      final gallery = tester.getRect(
        find.byKey(const ValueKey('media-gallery')),
      );
      final camera = tester.getRect(find.byKey(const ValueKey('media-camera')));
      expect(gallery.top, camera.top);
      expect(gallery.height, camera.height);
      expect(gallery.width, closeTo(camera.width, 0.5));
      expect(gallery.width, greaterThan(120));
      expect(find.text(VideoStrings.camera), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('media-gallery')));
      await tester.tap(find.byKey(const ValueKey('media-camera')));
      expect(taps, ['gallery', 'camera']);

      await tester.tap(find.byKey(const ValueKey('media-mode-video')));
      await tester.pump();
      expect(find.text(VideoStrings.recordVideo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without camera the gallery takes the whole row', (
      tester,
    ) async {
      await pump(
        tester,
        MediaSourceRow(
          video: false,
          showCamera: false,
          onVideoChanged: (_) {},
          onGallery: () {},
          onCamera: () {},
        ),
      );
      expect(find.byKey(const ValueKey('media-camera')), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('media-gallery'))).width,
        closeTo(328, 0.5),
      );
    });
  });

  group('TapToPlayVideo', () {
    testWidgets('shows a poster and downloads nothing before a tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 300,
            height: 400,
            child: TapToPlayVideo(
              source: 'https://example.com/v.mp4',
              durationLabel: '0:12',
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('video-play-button')), findsOneWidget);
      expect(find.text('0:12'), findsOneWidget);
    });

    testWidgets('video thumbnail never loads the video', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: VideoThumbnail())),
      );
      expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
    });
  });
}

class _FakeTranscoder implements VideoTranscoder {
  _FakeTranscoder(this.sizes, {this.supported = true});

  /// Output size per pass; a missing pass = encoder failure.
  final Map<VideoTargetQuality, int> sizes;
  final bool supported;
  final calls = <(VideoTargetQuality, int?, int?)>[];

  @override
  bool get isSupported => supported;

  @override
  Future<TranscodedVideo?> transcode({
    required String path,
    required VideoTargetQuality quality,
    int? startTime,
    int? duration,
    void Function(double progress)? onProgress,
  }) async {
    calls.add((quality, startTime, duration));
    onProgress?.call(0.5);
    final size = sizes[quality];
    if (size == null) {
      return null;
    }
    return TranscodedVideo(path: '/out_${quality.name}.mp4', sizeBytes: size);
  }

  @override
  Future<void> clearCache() async {}
}
