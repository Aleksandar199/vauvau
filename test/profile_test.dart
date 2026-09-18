import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/profile/domain/matching_filters.dart';
import 'package:vauvau/features/profile/presentation/profile_controller.dart';
import 'package:vauvau/features/profile/presentation/profile_screen.dart';
import 'package:vauvau/features/profile/presentation/profile_strings.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<ProviderContainer> _pumpProfile(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      discoverImageFactoryProvider.overrideWith((ref) {
        return (_) => MemoryImage(_transparentPng);
      }),
    ],
  );
  addTearDown(container.dispose);
  container.read(discoverControllerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('loads profile info', (tester) async {
    await _pumpProfile(tester);

    expect(find.text('Luna'), findsWidgets);
    expect(find.text('Maks'), findsOneWidget);
    expect(find.text('Zlatni retriver • 3 god.'), findsOneWidget);
    expect(find.text(ProfileStrings.sizeLarge), findsOneWidget);
    expect(find.text(ProfileStrings.badgeChipped), findsOneWidget);
    expect(find.text(ProfileStrings.badgeVaccinated), findsOneWidget);
    expect(find.text('Novi Sad - Liman'), findsOneWidget);
    expect(find.text('Novi Sad - Liman 3'), findsOneWidget);
    expect(find.text('Aleksandar'), findsOneWidget);
    expect(
      find.text('Šetač iz Limana. Tražim druženje za Lunu uz Dunav.'),
      findsOneWidget,
    );
    expect(find.text(ProfileStrings.editProfile), findsOneWidget);
    expect(find.text(ProfileStrings.settings), findsOneWidget);
  });

  testWidgets('edits dog details and saves', (tester) async {
    final container = await _pumpProfile(tester);

    await tester.tap(find.text(ProfileStrings.editProfile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(ProfileStrings.saveChanges), findsOneWidget);
    expect(find.text(ProfileStrings.vaccines), findsOneWidget);
    expect(find.text(ProfileStrings.sterilized), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Luna'),
      'Luna Nova',
    );
    await tester.ensureVisible(find.text(ProfileStrings.saveChanges));
    await tester.tap(find.text(ProfileStrings.saveChanges));
    await tester.pumpAndSettle();

    expect(find.text(ProfileStrings.saved), findsOneWidget);
    expect(find.text('Luna Nova'), findsWidgets);
    expect(container.read(profileControllerProvider).dog.name, 'Luna Nova');
  });

  testWidgets('switches selected dog', (tester) async {
    final container = await _pumpProfile(tester);

    await tester.tap(find.text('Maks'));
    await tester.pump();

    expect(container.read(profileControllerProvider).dog.name, 'Maks');
    expect(find.textContaining('Mešanac'), findsWidgets);
  });

  testWidgets('opens settings and search filters', (tester) async {
    final container = await _pumpProfile(tester);

    await tester.tap(find.text(ProfileStrings.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(ProfileStrings.notifyWalks), findsOneWidget);
    expect(find.text(ProfileStrings.appVersion), findsOneWidget);
    expect(find.text(ProfileStrings.deleteAccount), findsOneWidget);

    await tester.tap(find.text(ProfileStrings.searchFilters));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(ProfileStrings.sizeFilter), findsOneWidget);

    await tester.tap(find.text(ProfileStrings.cityBeograd));
    await tester.pump();
    await tester.tap(find.text(ProfileStrings.applyFilters));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(matchingFiltersProvider).city, FilterCity.beograd);
    final visible = container.read(discoverControllerProvider).visible;
    expect(visible, isNotEmpty);
    expect(
      visible.every((profile) => profile.location.startsWith('Beograd')),
      isTrue,
    );
  });
}
