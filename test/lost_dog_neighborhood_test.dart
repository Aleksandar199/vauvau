import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/location/presentation/home_city_provider.dart';
import 'package:vauvau/features/lost_dogs/data/local_lost_dog_repository.dart';
import 'package:vauvau/features/lost_dogs/presentation/lost_dog_strings.dart';
import 'package:vauvau/features/lost_dogs/presentation/lost_dogs_controller.dart';
import 'package:vauvau/features/lost_dogs/presentation/report_lost_dog_sheet.dart';

const _belgrade = HomeCity(
  id: 'beograd',
  name: 'Beograd',
  coord: GeoCoord.belgrade,
);

void main() {
  test('Belgrade has an expanded neighborhood list', () {
    final hoods = SerbiaLocations.neighborhoodsForAdoptionCity('Beograd');
    expect(hoods.length, greaterThanOrEqualTo(50));
    expect(
      hoods,
      containsAll([
        'Dorćol',
        'Vračar',
        'Novi Beograd',
        'Zemun',
        'Voždovac',
        'Zvezdara',
        'Čukarica',
        'Rakovica',
        'Karaburma',
        'Banovo brdo',
      ]),
    );
    expect(hoods.toSet().length, hoods.length);
    final ids = [
      for (final hood in SerbiaLocations.cityById('beograd')!.neighborhoods)
        hood.id,
    ];
    expect(ids.toSet().length, ids.length);
    expect(ids, containsAll(['dorcol', 'vracar', 'novi_beograd']));
  });

  testWidgets('lost report accepts a manually typed neighborhood',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = LocalLostDogRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeCityProvider.overrideWithValue(_belgrade),
          lostDogRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showReportLostDogSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Beograd'), findsOneWidget);
    expect(find.text('Altina'), findsOneWidget);
    expect(find.byKey(const ValueKey('lost-custom-hood')), findsNothing);

    await tester.tap(find.text('Altina'));
    await tester.pumpAndSettle();
    final custom = find.text(SerbiaLocations.customNeighborhoodLabel);
    await tester.scrollUntilVisible(
      custom,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(custom.last);
    await tester.pumpAndSettle();

    final customField = find.byKey(const ValueKey('lost-custom-hood'));
    expect(customField, findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, LostDogStrings.dogName),
      'Maks',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, LostDogStrings.description),
      'Crni pas sa crvenom ogrlicom.',
    );
    final formScroll = find.byType(Scrollable).first;
    final phone = find.widgetWithText(TextFormField, LostDogStrings.phone);
    await tester.scrollUntilVisible(phone, 200, scrollable: formScroll);
    await tester.enterText(phone, '064000000');

    final publish = find.text(LostDogStrings.publish);
    await tester.scrollUntilVisible(publish, 200, scrollable: formScroll);
    await tester.ensureVisible(find.text(LostDogStrings.publish));
    await tester.tap(find.text(LostDogStrings.publish));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(LostDogStrings.customNeighborhoodRequired),
      -200,
      scrollable: formScroll,
    );
    expect(find.text(LostDogStrings.customNeighborhoodRequired), findsOneWidget);

    await tester.enterText(customField, 'Blok 45');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(publish, 200, scrollable: formScroll);
    await tester.ensureVisible(publish);
    await tester.pumpAndSettle();
    await tester.tap(publish);
    await tester.pumpAndSettle();

    expect(find.byType(ReportLostDogSheet), findsNothing);
    final dogs = await repo.watchLostDogs().first;
    final saved = dogs.firstWhere((dog) => dog.dogName == 'Maks');
    expect(saved.city, 'Beograd');
    expect(saved.neighborhood, 'Blok 45');
  });
}
