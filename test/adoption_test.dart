import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/adoption/data/local_adoption_repository.dart';
import 'package:vauvau/features/adoption/data/mock_adoption_dogs.dart';
import 'package:vauvau/features/adoption/presentation/adoption_controller.dart';
import 'package:vauvau/features/adoption/presentation/adoption_strings.dart';
import 'package:vauvau/features/adoption/presentation/screens/adoption_screen.dart';
import 'package:vauvau/features/adoption/presentation/widgets/add_adoption_dog_sheet.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  testWidgets('shows adoption listings and opens details', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverImageFactoryProvider.overrideWith((ref) {
            return (_) => MemoryImage(_transparentPng);
          }),
          adoptionRepositoryProvider.overrideWith(
            (ref) => LocalAdoptionRepository(seed: mockAdoptionDogs),
          ),
        ],
        child: const MaterialApp(home: AdoptionScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(AdoptionStrings.title), findsOneWidget);
    expect(find.text(AdoptionStrings.subtitle), findsOneWidget);
    expect(find.text(AdoptionStrings.addCta), findsOneWidget);
    expect(find.text('Bara 1 god.'), findsOneWidget);
    expect(find.text(AdoptionStrings.badge), findsWidgets);

    await tester.tap(find.text('Bara 1 god.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AdoptionStrings.story), findsOneWidget);
    expect(find.text(AdoptionStrings.sendMessage), findsOneWidget);
    expect(find.textContaining(AdoptionStrings.call), findsOneWidget);
  });

  testWidgets('add listing form shows required fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AddAdoptionDogScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(AdoptionStrings.addTitle), findsOneWidget);
    expect(find.text(AdoptionStrings.name), findsWidgets);
    expect(find.text(AdoptionStrings.sizeSmall), findsOneWidget);
    expect(find.text(AdoptionStrings.story), findsWidgets);
    expect(find.text(AdoptionStrings.city), findsWidgets);
    expect(find.text(AdoptionStrings.neighborhood), findsWidgets);
  });
}
