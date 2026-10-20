import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/images/blur_fill_image.dart';
import 'package:vauvau/features/discover/presentation/widgets/dog_photo_gallery.dart';
import 'package:vauvau/features/events/domain/event_model.dart';
import 'package:vauvau/features/events/presentation/widgets/event_card.dart';
import 'package:vauvau/features/events/presentation/widgets/event_photo.dart';

// 1×1 transparent PNG – keeps the test off the network.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const _dataUrl = 'data:image/png;base64,$_pngBase64';

EventModel _event({String imageUrl = _dataUrl}) => EventModel(
      id: 'event-1',
      title: 'Šetnja na keju',
      locationName: 'Kej',
      dateTime: DateTime(2030, 1, 1, 10),
      description: 'Opis',
      imageUrl: imageUrl,
      organizerUserId: 'u1',
      organizerName: 'Ana',
      participantUserIds: const [],
      createdAt: DateTime(2029, 12, 1),
    );

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: ListView(children: [child])),
    );

void main() {
  testWidgets('event card shows the whole photo on a blurred fill',
      (tester) async {
    await tester.pumpWidget(
      _host(
        EventCard(
          event: _event(),
          joined: false,
          onJoin: () {},
          onOpenChat: () {},
        ),
      ),
    );

    expect(find.byType(EventPhoto), findsOneWidget);
    expect(find.byType(BlurFillImage), findsOneWidget);
    final fits = tester
        .widgetList<Image>(
          find.descendant(
            of: find.byType(BlurFillImage),
            matching: find.byType(Image),
          ),
        )
        .map((image) => image.fit)
        .toList();
    // Foreground shows the full image; cover is only the blurred background.
    expect(fits, contains(BoxFit.contain));
    expect(find.byType(ImageFiltered), findsOneWidget);

    final ratio = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byType(BlurFillImage),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(ratio.aspectRatio, closeTo(16 / 9, 0.001));
  });

  testWidgets('tapping the event photo opens the full-screen viewer',
      (tester) async {
    await tester.pumpWidget(_host(EventPhoto(event: _event())));

    await tester.tap(find.byType(EventPhoto));
    await tester.pumpAndSettle();

    expect(find.byType(DogPhotoViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(DogPhotoViewer), findsNothing);
  });

  testWidgets('event without a real photo keeps the fallback and no viewer',
      (tester) async {
    await tester.pumpWidget(_host(EventPhoto(event: _event(imageUrl: ''))));

    await tester.tap(find.byType(EventPhoto));
    await tester.pumpAndSettle();

    expect(find.byType(DogPhotoViewer), findsNothing);
  });

  testWidgets('local preview opens a zoomable full-screen preview',
      (tester) async {
    final bytes = base64Decode(_pngBase64);
    Widget image(BoxFit fit) => Image.memory(bytes, fit: fit);

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => BlurFillImage(
            imageBuilder: image,
            onTap: () => showImageFullScreen(context, imageBuilder: image),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(BlurFillImage));
    await tester.pumpAndSettle();

    expect(find.byType(FullScreenImagePreview), findsOneWidget);
    final viewerImage = tester.widget<Image>(
      find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(Image),
      ),
    );
    expect(viewerImage.fit, BoxFit.contain);
  });
}
