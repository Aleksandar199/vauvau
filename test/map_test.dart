import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/map/presentation/map_screen.dart';
import 'package:vauvau/features/map/presentation/map_strings.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<void> _pumpMap(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverImageFactoryProvider.overrideWith((ref) {
          return (_) => MemoryImage(_transparentPng);
        }),
      ],
      child: const MaterialApp(home: Scaffold(body: MapScreen())),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('toggles Započni šetnju and Završi šetnju', (tester) async {
    await _pumpMap(tester);

    expect(find.text(MapStrings.startWalk), findsOneWidget);

    await tester.tap(find.text(MapStrings.startWalk));
    await tester.pump();

    expect(find.text(MapStrings.confirm), findsOneWidget);
    await tester.tap(find.text(MapStrings.confirm));
    await tester.pump();

    expect(find.text(MapStrings.walking), findsOneWidget);
    expect(find.text(MapStrings.remaining(30)), findsOneWidget);
    expect(find.text(MapStrings.endWalk), findsOneWidget);
    expect(find.text(MapStrings.startWalk), findsNothing);

    await tester.tap(find.text(MapStrings.endWalk));
    await tester.pump();

    expect(find.text(MapStrings.startWalk), findsOneWidget);
    expect(find.text(MapStrings.walking), findsNothing);
  });

  testWidgets('renders map pins and location bottom sheet', (tester) async {
    await _pumpMap(tester);

    expect(find.byKey(const Key('place-park-ive-andrica')), findsOneWidget);
    expect(find.byKey(const Key('place-cafe-gabby')), findsOneWidget);
    expect(find.byKey(const Key('place-pet-house')), findsOneWidget);
    expect(find.byKey(const Key('place-dog-tales')), findsOneWidget);
    expect(find.byKey(const Key('walker-bobi')), findsOneWidget);

    await tester.ensureVisible(find.text(MapStrings.filterCafes));
    await tester.tap(find.text(MapStrings.filterCafes));
    await tester.pump();
    expect(find.byKey(const Key('place-cafe-gabby')), findsOneWidget);
    expect(find.byKey(const Key('place-park-ive-andrica')), findsNothing);
    expect(find.byKey(const Key('walker-bobi')), findsNothing);

    await tester.ensureVisible(find.text(MapStrings.filterMore));
    await tester.tap(find.text(MapStrings.filterMore));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(MapStrings.filterPetShops));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('place-pet-house')), findsOneWidget);
    expect(find.byKey(const Key('place-cafe-gabby')), findsNothing);

    await tester.ensureVisible(find.text(MapStrings.filterMore));
    await tester.tap(find.text(MapStrings.filterMore));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(MapStrings.filterGroomers));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('place-dog-tales')), findsOneWidget);
    expect(find.byKey(const Key('place-pet-house')), findsNothing);

    await tester.ensureVisible(find.text(MapStrings.filterParks));
    await tester.tap(find.text(MapStrings.filterParks));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('place-park-ive-andrica')));
    await tester.tap(find.byKey(const Key('place-park-ive-andrica')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Park za pse — Ive Andrića'), findsWidgets);
    expect(find.text(MapStrings.dogParkBadge), findsOneWidget);
    expect(find.textContaining('Ive Andrića •'), findsOneWidget);
    expect(find.textContaining(MapStrings.verifiedBadge), findsOneWidget);
    expect(find.text(MapStrings.openProfile), findsOneWidget);
    expect(find.text(MapStrings.navigation), findsOneWidget);
    expect(find.text(MapStrings.reportChange), findsOneWidget);
  });

  testWidgets('switches map city to Belgrade', (tester) async {
    await _pumpMap(tester);

    expect(find.text(MapStrings.cityNoviSad), findsOneWidget);
    expect(find.text(MapStrings.cityBelgrade), findsOneWidget);
    expect(find.byKey(const Key('place-cafe-gabby')), findsOneWidget);
    expect(find.byKey(const Key('place-bg-cafe-witch')), findsNothing);

    await tester.tap(find.text(MapStrings.cityBelgrade));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('place-bg-cafe-witch')), findsOneWidget);
    expect(find.byKey(const Key('place-cafe-gabby')), findsNothing);
    expect(find.byKey(const Key('walker-bobi')), findsNothing);
  });

  testWidgets('adds a user-submitted place to the map', (tester) async {
    await _pumpMap(tester);

    await tester.ensureVisible(find.text(MapStrings.addPlace));
    await tester.tap(find.text(MapStrings.addPlace));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.widgetWithText(TextFormField, MapStrings.placeName),
      'Moj park',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, MapStrings.placeAddress),
      'Liman',
    );
    await tester.ensureVisible(find.text(MapStrings.submitPlace));
    await tester.tap(find.text(MapStrings.submitPlace));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(MapStrings.placeAdded), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Moj park');
    await tester.pump();
    expect(find.byTooltip('Moj park'), findsOneWidget);
  });
}
