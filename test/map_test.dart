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

    expect(find.byKey(const Key('place-liman-park')), findsOneWidget);
    expect(find.byKey(const Key('place-dvoriste')), findsOneWidget);
    expect(find.byKey(const Key('place-za-moju-dusu')), findsOneWidget);
    expect(find.byKey(const Key('walker-bobi')), findsOneWidget);

    await tester.tap(find.text(MapStrings.filterCafes));
    await tester.pump();
    expect(find.byKey(const Key('place-dvoriste')), findsOneWidget);
    expect(find.byKey(const Key('walker-bobi')), findsNothing);

    await tester.tap(find.text(MapStrings.filterParks));
    await tester.pump();

    await tester.tap(find.byKey(const Key('place-liman-park')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Limanski park istrčavalište'), findsWidgets);
    expect(find.text(MapStrings.park), findsOneWidget);
    expect(find.text('Liman 3, Novi Sad'), findsOneWidget);
    expect(find.text(MapStrings.nearbyCount(4)), findsOneWidget);
    expect(find.text(MapStrings.join), findsOneWidget);
    expect(find.text(MapStrings.directions), findsOneWidget);
  });
}
