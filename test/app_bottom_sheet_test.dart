import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/widgets/app_bottom_sheet.dart';

void main() {
  testWidgets('sheet content stays above the system navigation bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    // 3-button navigation bar: 48 logical px at the bottom (edge-to-edge).
    tester.view.padding = const FakeViewPadding(bottom: 96);
    tester.view.viewPadding = const FakeViewPadding(bottom: 96);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      key: const Key('submit'),
                      onPressed: () {},
                      child: const Text('Pošalji na pregled'),
                    ),
                  ],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final bottom = tester.getBottomLeft(find.byKey(const Key('submit'))).dy;
    // Screen is 800 logical px tall; bar covers the last 48.
    expect(bottom, lessThanOrEqualTo(800 - 48));
  });
}
