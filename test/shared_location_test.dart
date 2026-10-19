import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/core/geo/shared_location.dart';
import 'package:vauvau/features/map/data/firestore_walk_presence_repository.dart';

const _exact = GeoCoord(45.255123, 19.845678);

void main() {
  group('SharedLocation', () {
    test('približna tačka je centar ćelije, a ne GPS tačka', () {
      final approx = SharedLocation.approximate(_exact);
      expect(approx, isNot(_exact));
      // Najviše pola dijagonale ćelije (~140 m) od prave tačke.
      expect(haversineKm(approx, _exact) * 1000, lessThan(150));
      // Isto za sve tačke u istoj ćeliji, i stabilno (idempotentno).
      expect(SharedLocation.approximate(approx), approx);
      expect(
        SharedLocation.approximate(const GeoCoord(45.2551, 19.8457)),
        approx,
      );
    });

    test('susedne ćelije se razlikuju, pa se pomeranje ipak vidi grubo', () {
      final a = SharedLocation.approximate(const GeoCoord(45.2551, 19.8457));
      final b = SharedLocation.approximate(const GeoCoord(45.2551, 19.8497));
      expect(a, isNot(b));
      expect(haversineKm(a, b) * 1000, greaterThan(100));
    });

    test('radi i za negativne koordinate', () {
      final approx = SharedLocation.approximate(const GeoCoord(-33.9, -70.65));
      expect(haversineKm(approx, const GeoCoord(-33.9, -70.65)) * 1000,
          lessThan(160));
    });
  });

  group('Prisustvo u šetnji (dogs) ne otkriva tačnu lokaciju', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreWalkPresenceRepository repo;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      repo = FirestoreWalkPresenceRepository(firestore);
      await firestore.collection('dogs').doc('rex').set({
        'ownerId': 'me',
        'name': 'Rex',
      });
    });

    Future<Map<String, dynamic>> dog() async =>
        (await firestore.collection('dogs').doc('rex').get()).data()!;

    test('setWalking upisuje centar ćelije u sva polja lokacije', () async {
      await repo.setWalking(
        userId: 'me',
        dogId: 'rex',
        isWalking: true,
        location: _exact,
        statusMessage: 'U šetnji',
      );
      final data = await dog();
      final approx = SharedLocation.approximate(_exact);
      expect(data['isWalking'], isTrue);
      expect(data['latitude'], approx.latitude);
      expect(data['longitude'], approx.longitude);
      final point = data['lastKnownLocation'] as GeoPoint;
      expect(point.latitude, approx.latitude);
      expect(point.longitude, approx.longitude);
      // Nigde u dokumentu psa nema tačne tačke.
      expect(data.values.whereType<num>(), isNot(contains(_exact.latitude)));
      expect(data.values.whereType<num>(), isNot(contains(_exact.longitude)));
    });

    test('pomeranje unutar iste ćelije ne piše ništa novo', () async {
      await repo.setWalking(
        userId: 'me',
        dogId: 'rex',
        isWalking: true,
        location: _exact,
      );
      // Ručno „obeležimo“ dokument: upis bi ga prepisao.
      await firestore.collection('dogs').doc('rex').update({'latitude': 1.0});
      await repo.updateLocation(
        userId: 'me',
        dogId: 'rex',
        location: const GeoCoord(45.2551, 19.8457),
      );
      expect((await dog())['latitude'], 1.0);
    });

    test('prelazak u drugu ćeliju upisuje novi centar', () async {
      await repo.setWalking(
        userId: 'me',
        dogId: 'rex',
        isWalking: true,
        location: _exact,
      );
      const moved = GeoCoord(45.2601, 19.8501);
      await repo.updateLocation(userId: 'me', dogId: 'rex', location: moved);
      final approx = SharedLocation.approximate(moved);
      final data = await dog();
      expect(data['latitude'], approx.latitude);
      expect(data['longitude'], approx.longitude);
    });

    test('kraj šetnje takođe upisuje samo približnu tačku', () async {
      await repo.setWalking(
        userId: 'me',
        dogId: 'rex',
        isWalking: false,
        location: _exact,
      );
      final data = await dog();
      expect(data['isWalking'], isFalse);
      expect(data['latitude'], SharedLocation.approximate(_exact).latitude);
    });
  });
}
