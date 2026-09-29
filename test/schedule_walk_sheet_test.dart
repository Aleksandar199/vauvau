import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/chat/presentation/chat_strings.dart';
import 'package:vauvau/features/chat/presentation/schedule_walk_sheet.dart';

Future<void> _pumpSheet(
  WidgetTester tester, {
  Size size = const Size(390, 640),
  double keyboard = 0,
  bool resizeToAvoidBottomInset = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: ScheduleWalkBottomSheet(onSend: (_, _) {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

Rect _rect(WidgetTester tester, Finder finder) {
  return tester.getRect(finder.first);
}

void main() {
  testWidgets('title, fields and action buttons are all on screen',
      (tester) async {
    await _pumpSheet(tester);

    expect(find.text(ChatStrings.walkSheetTitle), findsOneWidget);
    expect(find.text(ChatStrings.cancel), findsOneWidget);
    expect(find.text(ChatStrings.sendInvite), findsOneWidget);

    final screen = tester.view.physicalSize;
    final title = _rect(tester, find.text(ChatStrings.walkSheetTitle));
    final cancel = _rect(tester, find.text(ChatStrings.cancel));
    final send = _rect(tester, find.text(ChatStrings.sendInvite));

    expect(title.top, greaterThanOrEqualTo(0));
    expect(cancel.bottom, lessThanOrEqualTo(screen.height + 0.5));
    expect(send.bottom, lessThanOrEqualTo(screen.height + 0.5));
    expect(cancel.center.dy, moreOrLessEquals(send.center.dy, epsilon: 8));
    expect(cancel.left, lessThan(send.left));
    expect(title.bottom, lessThan(cancel.top));
  });

  testWidgets('buttons stay visible when the keyboard is open', (tester) async {
    const keyboard = 280.0;
    const size = Size(390, 640);
    await _pumpSheet(
      tester,
      size: size,
      keyboard: keyboard,
      resizeToAvoidBottomInset: false,
    );

    final visibleBottom = size.height - keyboard;
    final cancel = _rect(tester, find.text(ChatStrings.cancel));
    final send = _rect(tester, find.text(ChatStrings.sendInvite));

    expect(cancel.bottom, lessThanOrEqualTo(visibleBottom + 0.5));
    expect(send.bottom, lessThanOrEqualTo(visibleBottom + 0.5));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('buttons stay on screen in a short viewport', (tester) async {
    await _pumpSheet(tester, size: const Size(360, 480));

    final screen = tester.view.physicalSize;
    final cancel = _rect(tester, find.text(ChatStrings.cancel));
    final send = _rect(tester, find.text(ChatStrings.sendInvite));

    expect(find.text(ChatStrings.cancel), findsOneWidget);
    expect(find.text(ChatStrings.sendInvite), findsOneWidget);
    expect(cancel.bottom, lessThanOrEqualTo(screen.height + 0.5));
    expect(send.bottom, lessThanOrEqualTo(screen.height + 0.5));
  });

  testWidgets('showModalBottomSheet keeps actions pinned with keyboard',
      (tester) async {
    const size = Size(390, 640);
    const keyboard = 280.0;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    showScheduleWalkSheet(
                      context: context,
                      onSend: (_, _) {},
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    await tester.pump();

    final cancel = _rect(tester, find.text(ChatStrings.cancel));
    final send = _rect(tester, find.text(ChatStrings.sendInvite));
    expect(cancel.bottom, lessThanOrEqualTo(size.height - keyboard + 8));
    expect(send.bottom, lessThanOrEqualTo(size.height - keyboard + 8));
    expect(cancel.left, lessThan(send.left));
  });
}
