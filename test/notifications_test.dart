import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/home/presentation/home_tab.dart';
import 'package:vauvau/features/notifications/presentation/notification_controller.dart';
import 'package:vauvau/features/notifications/presentation/notification_screen.dart';
import 'package:vauvau/features/notifications/presentation/notification_strings.dart';

void main() {
  testWidgets('shows Serbian notification feed and unread highlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: NotificationScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(NotificationStrings.title), findsOneWidget);
    expect(find.text('Novi VauVau Match!'), findsOneWidget);
    expect(
      find.text('Rex i Luna žele da se upoznaju.'),
      findsOneWidget,
    );
    expect(
      find.text('Miloš te je pozvao u šetnju u Limanskom parku.'),
      findsOneWidget,
    );
    expect(find.text('Nova poruka od Ane.'), findsOneWidget);
  });

  testWidgets('walk notification opens the map tab', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: NotificationScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.text('Miloš te je pozvao u šetnju u Limanskom parku.'),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(homeTabIndexProvider), 1);
    expect(
      container.read(notificationControllerProvider).firstWhere((item) => item.id == 'n-walk').isRead,
      isTrue,
    );
  });
}
