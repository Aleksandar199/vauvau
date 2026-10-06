import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/lost_dogs/data/local_lost_dog_repository.dart';
import 'package:vauvau/features/lost_dogs/domain/lost_dog.dart';
import 'package:vauvau/features/lost_dogs/domain/lost_dog_matcher.dart';
import 'package:vauvau/features/lost_dogs/presentation/lost_dog_strings.dart';
import 'package:vauvau/features/lost_dogs/presentation/lost_dogs_controller.dart';
import 'package:vauvau/features/lost_dogs/presentation/lost_dogs_screen.dart';

LostDog _maks() {
  return LostDog(
    id: 'maks-1',
    dogName: 'Maks',
    breed: 'Zlatni retriver',
    type: LostDogType.lost,
    city: 'Novi Sad',
    neighborhood: 'Telep',
    lostDate: DateTime(2026, 9, 27),
    description: 'Crno-beli, crvena ogrlica.',
    imageUrl: 'https://example.com/maks.jpg',
    contactPhone: '064000000',
    uploaderUserId: 'owner-1',
    status: LostDogStatus.legacyMissing,
    createdAt: DateTime(2026, 9, 27, 10),
  );
}

LostDog _foundOnTelep() {
  return LostDog(
    id: 'found-1',
    dogName: 'Nepoznat pas',
    breed: 'Zlatni retriver',
    type: LostDogType.found,
    city: 'Novi Sad',
    neighborhood: 'Telep',
    lostDate: DateTime(2026, 9, 28),
    foundDate: DateTime(2026, 9, 28),
    description: 'Veliki zlatni pas, crvena ogrlica.',
    imageUrl: 'https://example.com/found.jpg',
    contactPhone: '064111111',
    uploaderUserId: 'finder-1',
    status: LostDogStatus.active,
    createdAt: DateTime(2026, 9, 28, 10),
  );
}

void main() {
  test('matches found dog to lost dog in same neighborhood and breed', () {
    final matches = LostDogMatcher.matchesFor(_foundOnTelep(), [_maks()]);
    expect(matches, isNotEmpty);
    expect(matches.first.dogName, 'Maks');
  });

  testWidgets('shows missing dog card and report CTA', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lostDogRepositoryProvider.overrideWith(
            (ref) {
              final repo = LocalLostDogRepository(seed: [_maks()]);
              ref.onDispose(repo.dispose);
              return repo;
            },
          ),
        ],
        child: const MaterialApp(home: LostDogsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(LostDogStrings.title), findsOneWidget);
    expect(find.text(LostDogStrings.banner), findsOneWidget);
    expect(find.byTooltip(LostDogStrings.addCta), findsOneWidget);
    expect(find.text('Maks je nestao'), findsOneWidget);
    expect(find.textContaining('Novi Sad – Telep'), findsWidgets);
    expect(find.text(LostDogStrings.sighting), findsOneWidget);
    expect(find.text(LostDogStrings.missingBadge), findsOneWidget);
  });

  testWidgets('shows found tab card, green contact and match banner', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lostDogRepositoryProvider.overrideWith(
            (ref) {
              final repo = LocalLostDogRepository(
                seed: [_maks(), _foundOnTelep()],
              );
              ref.onDispose(repo.dispose);
              return repo;
            },
          ),
        ],
        child: const MaterialApp(home: LostDogsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(Tab).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(LostDogStrings.foundBadge), findsOneWidget);
    expect(find.text(LostDogStrings.contactFinder), findsOneWidget);
    expect(find.textContaining('MOGUĆE POKLAPANJE'), findsOneWidget);
    expect(find.textContaining('Maks'), findsWidgets);
  });
}
