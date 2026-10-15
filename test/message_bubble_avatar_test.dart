import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/chat/domain/chat_message.dart';
import 'package:vauvau/features/chat/presentation/widgets/message_bubble.dart';
import 'package:vauvau/features/discover/presentation/widgets/dog_photo_gallery.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool isMine,
  required VoidCallback onAvatarTap,
  VoidCallback? onLongPress,
}) {
  final now = DateTime(2026, 10, 15, 10);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: ChatMessage(
            id: 'm1',
            text: 'Vidimo se u parku',
            sentAt: now,
            isMine: isMine,
          ),
          now: now,
          fallbackSenderName: 'Ana',
          onAvatarTap: onAvatarTap,
          onLongPress: onLongPress,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tapping the message text does not open the profile',
      (tester) async {
    var opened = 0;
    var longPressed = 0;
    await _pump(
      tester,
      isMine: false,
      onAvatarTap: () => opened++,
      onLongPress: () => longPressed++,
    );

    await tester.tap(find.text('Vidimo se u parku'));
    await tester.pump();
    expect(opened, 0);

    await tester.longPress(find.text('Vidimo se u parku'));
    await tester.pump();
    expect(longPressed, 1);
    expect(opened, 0);
  });

  testWidgets('tapping the sender avatar opens the profile', (tester) async {
    var opened = 0;
    await _pump(tester, isMine: false, onAvatarTap: () => opened++);

    await tester.tap(find.byKey(const ValueKey('message-sender-avatar')));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('tapping a photo in a message opens it full screen',
      (tester) async {
    final now = DateTime(2026, 10, 15, 10);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: ChatMessage(
              id: 'm-photo',
              text: '',
              imageUrl: 'https://example.com/dog.jpg',
              sentAt: now,
              isMine: false,
            ),
            now: now,
          ),
        ),
      ),
    );

    expect(find.byType(DogPhotoViewer), findsNothing);
    await tester.tap(find.byKey(const ValueKey('message-image')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DogPhotoViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DogPhotoViewer), findsNothing);
  });

  testWidgets('own messages have no tappable profile avatar', (tester) async {
    var opened = 0;
    await _pump(tester, isMine: true, onAvatarTap: () => opened++);

    expect(find.byKey(const ValueKey('message-sender-avatar')), findsNothing);
    await tester.tap(find.text('Vidimo se u parku'));
    await tester.pump();
    expect(opened, 0);
  });
}
