import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vauvau/features/profile/presentation/profile_controller.dart';
import 'package:vauvau/features/profile/presentation/profile_strings.dart';
import 'package:vauvau/features/profile/presentation/settings_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('notification switches update settings', (tester) async {
    final container = await pumpSettings(tester);

    expect(container.read(appSettingsProvider).notifyMessages, isTrue);
    await tester.tap(find.text(ProfileStrings.notifyMessages));
    await tester.pumpAndSettle();
    expect(container.read(appSettingsProvider).notifyMessages, isFalse);

    await tester.tap(find.text(ProfileStrings.notifyWalks));
    await tester.tap(find.text(ProfileStrings.notifyMatches));
    await tester.pumpAndSettle();
    final settings = container.read(appSettingsProvider);
    expect(settings.notifyWalkRequests, isFalse);
    expect(settings.notifyNewMatches, isFalse);
  });

  testWidgets('enable notifications gives feedback', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text(ProfileStrings.enableNotifications));
    await tester.pump();
    expect(
      find.text(ProfileStrings.notificationsUnsupported),
      findsOneWidget,
    );
  });

  testWidgets('radius slider keeps settings and filters in sync',
      (tester) async {
    final container = await pumpSettings(tester);

    await tester.drag(find.byType(Slider), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(container.read(appSettingsProvider).radiusKm, 1);
    expect(container.read(matchingFiltersProvider).radiusKm, 1);

    final filters = container.read(matchingFiltersProvider);
    container
        .read(matchingFiltersProvider.notifier)
        .apply(filters.copyWith(radiusKm: 25));
    await tester.pumpAndSettle();
    expect(container.read(appSettingsProvider).radiusKm, 25);
    expect(find.text(ProfileStrings.radiusValue(25)), findsOneWidget);
  });

  testWidgets('location switch and filters respond, no account actions',
      (tester) async {
    final container = await pumpSettings(tester);

    await tester.ensureVisible(find.text(ProfileStrings.showLocation));
    await tester.tap(find.text(ProfileStrings.showLocation));
    await tester.pumpAndSettle();
    expect(container.read(appSettingsProvider).showLocationOnMap, isFalse);

    await tester.tap(find.text(ProfileStrings.searchFilters));
    await tester.pumpAndSettle();
    expect(find.text(ProfileStrings.applyFilters), findsOneWidget);
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    expect(
      find.text(ProfileStrings.signOut, skipOffstage: false),
      findsNothing,
    );
    expect(
      find.text(ProfileStrings.deleteAccount, skipOffstage: false),
      findsNothing,
    );
  });
}
