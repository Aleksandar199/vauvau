import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/location/presentation/home_city_provider.dart';
import 'package:vauvau/features/lost_dogs/data/local_lost_dog_repository.dart';
import 'package:vauvau/features/lost_dogs/domain/lost_dog.dart';
import 'package:vauvau/features/lost_dogs/domain/lost_dog_city.dart';
import 'package:vauvau/features/lost_dogs/domain/lost_dog_matcher.dart';
import 'package:vauvau/features/lost_dogs/presentation/lost_dog_strings.dart';
import 'package:vauvau/features/lost_dogs/presentation/lost_dogs_controller.dart';
import 'package:vauvau/features/lost_dogs/presentation/lost_dogs_screen.dart';

const _noviSad = HomeCity(
  id: 'novi_sad',
  name: 'Novi Sad',
  coord: GeoCoord.noviSad,
);

LostDog _dog(
  String id, {
  String city = 'Novi Sad',
  String cityId = '',
  String type = LostDogType.lost,
  DateTime? createdAt,
}) {
  final created =
      createdAt ?? DateTime.now().subtract(const Duration(hours: 1));
  return LostDog(
    id: id,
    dogName: 'Pas $id',
    breed: 'Labrador',
    type: type,
    city: city,
    cityId: cityId,
    neighborhood: 'Centar',
    lostDate: created,
    description: 'Crni labrador sa crvenom ogrlicom.',
    imageUrl: '',
    contactPhone: '064000000',
    uploaderUserId: 'owner-$id',
    status: LostDogStatus.active,
    createdAt: created,
  );
}

ProviderContainer _container(List<LostDog> seed, {HomeCity? home}) {
  final repo = LocalLostDogRepository(seed: seed);
  final container = ProviderContainer(
    overrides: [
      lostDogRepositoryProvider.overrideWithValue(repo),
      homeCityProvider.overrideWithValue(home),
    ],
  );
  addTearDown(() {
    container.dispose();
    repo.dispose();
  });
  return container;
}

Future<void> _load(ProviderContainer container) async {
  container.listen(lostDogsControllerProvider, (_, _) {});
  container.listen(cityLostDogsProvider, (_, _) {});
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('old listings without cityId', () {
    test('map by city name: case, diacritics, Cyrillic, aliases', () {
      expect(LostDogCity.idOf(_dog('a', city: 'Novi Sad')), 'novi_sad');
      expect(LostDogCity.idOf(_dog('b', city: '  novi sad ')), 'novi_sad');
      expect(LostDogCity.idOf(_dog('c', city: 'Нови Сад')), 'novi_sad');
      expect(LostDogCity.idOf(_dog('d', city: 'NIS - Medijana')), 'nis');
      expect(LostDogCity.idOf(_dog('e', city: 'Niš')), 'nis');
      expect(LostDogCity.idOf(_dog('f', city: 'Beograd')), 'beograd');
      expect(LostDogCity.idOf(_dog('g', city: 'Szabadka')), 'subotica');
      expect(LostDogCity.idOf(_dog('h', city: 'Зрењанин')), 'zrenjanin');
    });

    test('unknown or empty city goes to "other", never disappears', () {
      final pancevo = _dog('p', city: 'Pančevo');
      final empty = _dog('e', city: '');
      final ostalo = _dog('o', city: 'Ostalo');
      for (final dog in [pancevo, empty, ostalo]) {
        expect(LostDogCity.idOf(dog), isNull);
        expect(LostDogCity.matches(dog, LostDogCity.other), isTrue);
        expect(LostDogCity.matches(dog, LostDogCity.all), isTrue);
        expect(LostDogCity.matches(dog, 'novi_sad'), isFalse);
      }
    });

    test('stored cityId wins over the free-text city', () {
      final dog = _dog('x', city: 'Liman', cityId: 'novi_sad');
      expect(LostDogCity.idOf(dog), 'novi_sad');
    });
  });

  test('filter keeps only the chosen city', () {
    final dogs = [
      _dog('ns', city: 'Novi Sad'),
      _dog('bg', city: 'Beograd', cityId: 'beograd'),
      _dog('xx', city: 'Pančevo'),
    ];
    expect(LostDogCity.filter(dogs, 'novi_sad').map((d) => d.id), ['ns']);
    expect(LostDogCity.filter(dogs, 'beograd').map((d) => d.id), ['bg']);
    expect(LostDogCity.filter(dogs, LostDogCity.other).map((d) => d.id), [
      'xx',
    ]);
    expect(LostDogCity.filter(dogs, LostDogCity.all), hasLength(3));
  });

  test('default filter is the home city, otherwise all cities', () {
    expect(LostDogCity.defaultFilter('nis'), 'nis');
    expect(LostDogCity.defaultFilter(null), LostDogCity.all);
    expect(LostDogCity.defaultFilter('pariz'), LostDogCity.all);
  });

  test('form city maps to cityId; "Ostalo" stores none', () {
    expect(LostDogCity.idForFormCity('Novi Sad'), 'novi_sad');
    expect(LostDogCity.idForFormCity('Niš'), 'nis');
    expect(LostDogCity.idForFormCity('Subotica'), 'subotica');
    expect(LostDogCity.idForFormCity('Ostalo'), isNull);
  });

  test('matcher does not pair dogs from different cities', () {
    final lost = _dog('lost', city: 'Beograd', cityId: 'beograd');
    final found = _dog(
      'found',
      city: 'Novi Sad',
      cityId: 'novi_sad',
      type: LostDogType.found,
    );
    expect(LostDogMatcher.matchesFor(found, [lost]), isEmpty);
    final lostNs = _dog('lost-ns', city: 'Нови Сад');
    expect(LostDogMatcher.matchesFor(found, [lostNs]), isNotEmpty);
  });

  group('emergency popup', () {
    test('alerts only for the same city', () async {
      final container = _container([
        _dog('ns', city: 'Novi Sad', cityId: 'novi_sad'),
        _dog('bg', city: 'Beograd', cityId: 'beograd'),
        _dog('old-ns', city: 'novi sad'),
        _dog('unknown', city: 'Pančevo'),
      ], home: _noviSad);
      await _load(container);
      expect(
        container.read(emergencyLostDogsProvider).map((d) => d.id).toSet(),
        {'ns', 'old-ns'},
      );
    });

    test('user without a city keeps the old behaviour (every city)', () async {
      final container = _container([
        _dog('ns', cityId: 'novi_sad'),
        _dog('bg', city: 'Beograd', cityId: 'beograd'),
      ]);
      await _load(container);
      expect(container.read(emergencyLostDogsProvider), hasLength(2));
    });

    test('older than 24 h never alerts', () async {
      final container = _container([
        _dog(
          'ns',
          cityId: 'novi_sad',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ], home: _noviSad);
      await _load(container);
      expect(container.read(emergencyLostDogsProvider), isEmpty);
    });
  });

  test('city catalog starts at the home city and can switch', () async {
    final container = _container([
      _dog('ns', cityId: 'novi_sad'),
      _dog('old-ns', city: 'Novi Sad'),
      _dog('bg', city: 'Beograd', cityId: 'beograd'),
      _dog('xx', city: 'Pančevo'),
    ], home: _noviSad);
    await _load(container);
    expect(container.read(lostDogCityFilterProvider), 'novi_sad');
    expect(container.read(cityLostDogsProvider).map((d) => d.id).toSet(), {
      'ns',
      'old-ns',
    });

    container.read(lostDogCityFilterProvider.notifier).select('beograd');
    await _load(container);
    expect(container.read(cityLostDogsProvider).map((d) => d.id), ['bg']);

    container
        .read(lostDogCityFilterProvider.notifier)
        .select(LostDogCity.other);
    expect(container.read(cityLostDogsProvider).map((d) => d.id), ['xx']);

    container.read(lostDogCityFilterProvider.notifier).select(LostDogCity.all);
    expect(container.read(cityLostDogsProvider), hasLength(4));
  });

  test('new listing keeps its cityId', () async {
    final container = _container(const [], home: _noviSad);
    await _load(container);
    final ok = await container
        .read(lostDogsControllerProvider.notifier)
        .report(
          dogName: 'Maks',
          city: 'Kragujevac',
          cityId: 'kragujevac',
          neighborhood: 'Centar',
          eventDate: DateTime.now(),
          description: 'Opis',
          contactPhone: '064',
          type: LostDogType.lost,
          breed: 'Labrador',
        );
    expect(ok, isTrue);
    final dogs = await container
        .read(lostDogRepositoryProvider)
        .watchLostDogsInCity('kragujevac')
        .first;
    expect(dogs.single.cityId, 'kragujevac');
  });

  testWidgets('screen shows the home city, all cities and empty city state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = LocalLostDogRepository(
      seed: [
        _dog('ns', cityId: 'novi_sad'),
        _dog('bg', city: 'Beograd', cityId: 'beograd'),
      ],
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lostDogRepositoryProvider.overrideWithValue(repo),
          homeCityProvider.overrideWithValue(_noviSad),
        ],
        child: const MaterialApp(home: LostDogsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final nsChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('lost-dog-city-novi_sad')),
    );
    expect(nsChip.selected, isTrue);
    expect(find.text('Pas ns je nestao'), findsOneWidget);
    expect(find.text('Pas bg je nestao'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('lost-dog-city-all')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Pas ns je nestao'), findsOneWidget);
    expect(find.text('Pas bg je nestao'), findsOneWidget);

    final other = find.byKey(const ValueKey('lost-dog-city-other'));
    await tester.scrollUntilVisible(
      other,
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('lost-dog-city-filter')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    await tester.tap(other);
    await tester.pump();
    await tester.pump();
    expect(
      find.text(LostDogStrings.emptyInCity(LostDogStrings.otherCity)),
      findsOneWidget,
    );
  });
}
