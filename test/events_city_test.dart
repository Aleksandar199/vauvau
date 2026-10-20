import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/events/data/local_events_repository.dart';
import 'package:vauvau/features/events/data/seed_events.dart';
import 'package:vauvau/features/events/domain/event_model.dart';
import 'package:vauvau/features/events/presentation/create_event_screen.dart';
import 'package:vauvau/features/events/presentation/events_controller.dart';
import 'package:vauvau/features/events/presentation/events_screen.dart';
import 'package:vauvau/features/events/presentation/events_strings.dart';
import 'package:vauvau/features/location/presentation/home_city_provider.dart';
import 'package:vauvau/features/map/data/nis_dog_places_seed.dart';
import 'package:vauvau/features/map/data/poi_seed_data.dart';
import 'package:vauvau/features/map/domain/map_place.dart';
import 'package:vauvau/features/map/presentation/walk_controller.dart';
import 'package:vauvau/features/moments/presentation/create_moment_sheet.dart';
import 'package:vauvau/features/moments/presentation/moments_strings.dart';

const _nisHome = HomeCity(
  id: SerbiaLocations.nisId,
  name: 'Niš',
  coord: GeoCoord.nis,
);

EventModel _event({
  required String id,
  required String locationName,
  String cityId = '',
}) {
  return EventModel(
    id: id,
    title: 'Šetnja $id',
    locationName: locationName,
    dateTime: DateTime.now().add(const Duration(days: 1)),
    description: 'Opis',
    imageUrl: '',
    organizerUserId: 'u1',
    organizerName: 'Ana',
    participantUserIds: const ['u1'],
    createdAt: DateTime.now(),
    cityId: cityId,
  );
}

List<MapPlace> get _seedPlaces =>
    [for (final poi in PoiSeedData.allVerified) MapPlace.fromPoi(poi)];

void main() {
  group('EventVenues.forCity', () {
    test('Novi Sad keeps classic venues and ends with custom entry', () {
      final venues = EventVenues.forCity(SerbiaLocations.noviSadId, _seedPlaces);
      expect(venues.first, 'Limanski park');
      expect(venues, contains('Petrovaradinska tvrđava'));
      expect(venues.last, EventVenues.customOption);
      expect(venues.toSet().length, venues.length);
    });

    test('Niš offers only Niš parks and walking areas', () {
      final venues = EventVenues.forCity(SerbiaLocations.nisId, _seedPlaces);
      expect(venues, contains('Park Čair'));
      expect(venues, contains('Park za pse u Čairu'));
      expect(venues, isNot(contains('Limanski park')));
      final shops = NisDogPlacesSeed.petShops.map((p) => p.name);
      expect(venues.where(shops.contains), isEmpty);
      expect(venues.last, EventVenues.customOption);
    });

    test('every city has at least one walk location besides custom', () {
      for (final city in SerbiaLocations.cities) {
        final venues = EventVenues.forCity(city.id, _seedPlaces);
        expect(venues.length, greaterThan(1), reason: city.id);
      }
    });
  });

  group('EventVenues.cityIdForEvent', () {
    test('uses explicit cityId', () {
      expect(
        EventVenues.cityIdForEvent(
          _event(id: 'a', locationName: 'Limanski park', cityId: 'nis'),
        ),
        'nis',
      );
    });

    test('legacy Novi Sad venue without cityId maps to Novi Sad', () {
      expect(
        EventVenues.cityIdForEvent(
          _event(id: 'b', locationName: 'Kamenički park'),
        ),
        SerbiaLocations.noviSadId,
      );
    });

    test('unknown legacy location stays unassigned', () {
      expect(
        EventVenues.cityIdForEvent(_event(id: 'c', locationName: 'Negde')),
        isNull,
      );
    });

    test('seed events are tagged as Novi Sad', () {
      for (final event in SeedEvents.all) {
        expect(event.cityId, SerbiaLocations.noviSadId);
        expect(SeedEvents.firestoreData(event)['cityId'], 'novi_sad');
      }
    });
  });

  test('create stores the chosen city', () async {
    final repo = LocalEventsRepository(currentUserId: 'u1');
    addTearDown(repo.dispose);
    final container = ProviderContainer(
      overrides: [eventsRepositoryProvider.overrideWith((ref) => repo)],
    );
    addTearDown(container.dispose);

    final id = await container.read(eventsControllerProvider.notifier).create(
          title: 'Šetnja Čair',
          locationName: 'Park Čair',
          dateTime: DateTime.now().add(const Duration(days: 2)),
          description: 'Opis',
          cityId: SerbiaLocations.nisId,
        );
    final events = await repo.watchEvents().first;
    expect(events.firstWhere((e) => e.id == id).cityId, 'nis');
  });

  group('EventsScreen city filter', () {
    Future<void> pump(WidgetTester tester, LocalEventsRepository repo) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsRepositoryProvider.overrideWith((ref) => repo),
            homeCityProvider.overrideWithValue(_nisHome),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('defaults to home city and switches between cities',
        (tester) async {
      final repo = LocalEventsRepository(currentUserId: 'local-user');
      addTearDown(repo.dispose);
      await repo.createEvent(
        _event(id: 'nis-walk', locationName: 'Park Čair', cityId: 'nis'),
      );
      await pump(tester, repo);

      final nsTitle = SeedEvents.all.first.title;
      expect(find.text('Šetnja nis-walk'), findsOneWidget);
      expect(find.text(nsTitle), findsNothing);

      await tester.tap(find.text('Novi Sad'));
      await tester.pump();
      expect(find.text(nsTitle), findsOneWidget);
      expect(find.text('Šetnja nis-walk'), findsNothing);

      await tester.tap(find.text(EventsStrings.filterAllCities));
      await tester.pump();
      expect(find.text(nsTitle), findsOneWidget);
      expect(find.text('Šetnja nis-walk'), findsOneWidget);
    });

    testWidgets('shows empty state for a city without events', (tester) async {
      final repo = LocalEventsRepository(currentUserId: 'local-user');
      addTearDown(repo.dispose);
      await pump(tester, repo);
      expect(find.text(EventsStrings.emptyCity('Niš')), findsOneWidget);
    });
  });

  testWidgets('create form lists locations of the selected city',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeCityProvider.overrideWithValue(_nisHome),
          mapPlacesProvider.overrideWithValue(_seedPlaces),
        ],
        child: const MaterialApp(home: Scaffold(body: CreateEventScreen())),
      ),
    );
    await tester.pump();

    final nisFirst =
        EventVenues.forCity(SerbiaLocations.nisId, _seedPlaces).first;
    expect(find.text('Niš'), findsOneWidget);
    expect(find.text(nisFirst), findsOneWidget);

    await tester.tap(find.text('Niš'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novi Sad').last);
    await tester.pumpAndSettle();

    expect(find.text('Limanski park'), findsOneWidget);
    expect(find.text(nisFirst), findsNothing);
  });

  testWidgets('add story form lists locations of the selected city',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeCityProvider.overrideWithValue(_nisHome),
          mapPlacesProvider.overrideWithValue(_seedPlaces),
        ],
        child: const MaterialApp(home: Scaffold(body: CreateMomentSheet())),
      ),
    );
    await tester.pump();

    final nisFirst =
        EventVenues.forCity(SerbiaLocations.nisId, _seedPlaces).first;
    // City and location are optional; the location starts empty and its
    // list offers the places of the selected city.
    expect(find.text(MomentsStrings.cityOptional), findsOneWidget);
    expect(find.text(nisFirst), findsNothing);
    await tester.tap(find.text(MomentsStrings.noLocation));
    await tester.pumpAndSettle();
    await tester.tap(find.text(nisFirst).last);
    await tester.pumpAndSettle();
    expect(find.text(nisFirst), findsOneWidget);

    await tester.tap(find.text('Niš'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kragujevac').last);
    await tester.pumpAndSettle();

    final kgFirst =
        EventVenues.forCity(SerbiaLocations.kragujevacId, _seedPlaces).first;
    // A new city resets the location to "Bez lokacije".
    expect(find.text(nisFirst), findsNothing);
    await tester.tap(find.text(MomentsStrings.noLocation));
    await tester.pumpAndSettle();
    expect(find.text(kgFirst), findsWidgets);
    expect(find.text(nisFirst), findsNothing);
  });
}
