import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vauvau/core/media/picked_video.dart';
import 'package:vauvau/core/media/story_video.dart';
import 'package:vauvau/core/media/tap_to_play_video.dart';
import 'package:vauvau/core/media/video_limits.dart';
import 'package:vauvau/core/media/video_strings.dart';
import 'package:vauvau/core/widgets/media_source_row.dart';
import 'package:vauvau/features/moments/data/firestore_moments_repository.dart';
import 'package:vauvau/features/moments/domain/moment_model.dart';
import 'package:vauvau/features/stories/domain/story.dart';
import 'package:vauvau/services/storage_service.dart';

void main() {
  group('checkVideo', () {
    const story = VideoLimits.storyMaxDuration;
    const post = VideoLimits.postMaxDuration;

    test('accepts a short, small video', () {
      expect(
        checkVideo(
          sizeBytes: 5 * 1024 * 1024,
          duration: const Duration(seconds: 14),
          maxDuration: story,
        ),
        isNull,
      );
      expect(
        checkVideo(
          sizeBytes: 5 * 1024 * 1024,
          duration: const Duration(seconds: 29),
          maxDuration: post,
        ),
        isNull,
      );
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
      expect(
        checkVideo(
          sizeBytes: 1000,
          duration: const Duration(seconds: 31),
          maxDuration: post,
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
        maxDuration: VideoLimits.storyMaxDuration,
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
        maxDuration: VideoLimits.storyMaxDuration,
        probe: (_) async => const Duration(seconds: 40),
      );
      expect(result.video, isNull);
      expect(result.problem, VideoProblem.tooLong);
    });

    test('too large video is refused without opening it', () async {
      var probed = false;
      final result = await inspectPickedVideo(
        file(VideoLimits.maxBytes + 1),
        maxDuration: VideoLimits.postMaxDuration,
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
        maxDuration: VideoLimits.postMaxDuration,
        probe: (_) async => null,
      );
      expect(result.problem, VideoProblem.unreadable);
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
