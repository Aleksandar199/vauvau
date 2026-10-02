import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/discover/presentation/widgets/dog_photo_gallery.dart';

const _pixel =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

void main() {
  Future<void> pumpGallery(WidgetTester tester, List<String> photos) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              DogPhotoGallery(photos: photos, seed: 'luna', height: 420),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('swipes between photos and updates counter', (tester) async {
    await pumpGallery(tester, [_pixel, _pixel, _pixel]);

    expect(find.text('1/3'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('opens full screen viewer on the current photo', (tester) async {
    await pumpGallery(tester, [_pixel, _pixel]);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();

    expect(find.byType(DogPhotoViewer), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(DogPhotoViewer), findsNothing);
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('single photo hides swipe controls', (tester) async {
    await pumpGallery(tester, [_pixel]);

    expect(find.text('1/1'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.byIcon(Icons.zoom_out_map_rounded), findsOneWidget);
  });
}
