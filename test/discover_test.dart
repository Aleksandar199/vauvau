import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/discover/presentation/discover_screen.dart';
import 'package:vauvau/features/discover/presentation/discover_strings.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

DiscoverProfile _dog(
  String name, {
  String id = 'id',
  String breed = 'Mešanac',
  String location = 'Novi Sad - Liman',
}) {
  return DiscoverProfile(
    id: id,
    name: name,
    ownerName: 'Nikola',
    breed: breed,
    ageYears: 2,
    gender: 'mužjak',
    size: 'srednji',
    location: location,
    bio: 'Voli šetnje.',
    photoUrls: const ['https://example.com/dog.jpg'],
  );
}

Future<void> _pumpDiscover(
  WidgetTester tester, {
  required List<DiscoverProfile> profiles,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverImageFactoryProvider.overrideWith((ref) {
          return (_) => MemoryImage(_transparentPng);
        }),
        discoverProfilesProvider.overrideWith((ref) => profiles),
      ],
      child: const MaterialApp(
        home: Scaffold(body: DiscoverScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows directory cards in Serbian', (tester) async {
    await _pumpDiscover(tester, profiles: [_dog('Bobi')]);

    expect(find.text('Bobi, 2 god.'), findsOneWidget);
    expect(find.text('Mešanac • Novi Sad'), findsOneWidget);
    expect(find.text(DiscoverStrings.searchHint), findsOneWidget);
    expect(find.text(DiscoverStrings.chipAll), findsOneWidget);
    expect(find.byTooltip(DiscoverStrings.filters), findsOneWidget);
  });

  testWidgets('search with no matches shows empty state', (tester) async {
    await _pumpDiscover(tester, profiles: [_dog('Bobi')]);

    await tester.enterText(find.byType(TextField), 'xyznepostoji');
    await tester.pump();

    expect(find.text(DiscoverStrings.emptyTitle), findsOneWidget);
    expect(find.text(DiscoverStrings.emptySubtitle), findsOneWidget);
    expect(find.text(DiscoverStrings.resetFilters), findsOneWidget);
  });

  testWidgets('tapping a card opens the profile sheet', (tester) async {
    await _pumpDiscover(tester, profiles: [_dog('Bobi')]);

    await tester.tap(find.text('Bobi, 2 god.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(DiscoverStrings.details), findsOneWidget);
    expect(find.text(DiscoverStrings.owner), findsOneWidget);
    expect(find.text(DiscoverStrings.close), findsWidgets);
  });

  testWidgets('filter button opens matching filters', (tester) async {
    await _pumpDiscover(tester, profiles: [_dog('Bobi')]);

    await tester.tap(find.byTooltip(DiscoverStrings.filters));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(DiscoverStrings.genderTitle), findsOneWidget);
    expect(find.text(DiscoverStrings.applyFilters), findsOneWidget);
    expect(find.text(DiscoverStrings.reset), findsOneWidget);
  });
}
