import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/map/domain/completed_walk.dart';
import 'package:vauvau/features/rewards/data/firestore_rewards_repository.dart';
import 'package:vauvau/features/rewards/data/reward_payloads.dart';
import 'package:vauvau/features/rewards/domain/rewards_models.dart';

final DateTime _now = DateTime.now();

CompletedWalk _walk({String id = 'w1', int meters = 2500, bool mock = false}) =>
    CompletedWalk(
      id: id,
      userId: 'u1',
      dogId: 'd',
      startedAt: _now.subtract(const Duration(minutes: 31)),
      endedAt: _now.subtract(const Duration(minutes: 1)),
      durationSeconds: 1800,
      recognizedMeters: meters,
      mockDetected: mock,
    );

void main() {
  group('Odgovor servera → rezultat šetnje', () {
    test('nagrađena šetnja sa izazovom', () {
      final result = walkResultFromServer({
        'status': 'rewarded',
        'xp': 10,
        'points': 10,
        'xpBefore': 95,
        'capped': false,
        'challenges': [
          {'id': 'daily_2km', 'title': '2 km danas', 'xp': 10, 'points': 10},
        ],
      });
      expect(result.saved, isTrue);
      expect(result.eligible, isTrue);
      expect(result.points, 10);
      expect(result.totalXp, 20);
      expect(result.xpBefore, 95);
      expect(result.xpAfter, 115);
      expect(result.challengeEntries.single.reason, 'Izazov: 2 km danas');
    });

    test('dnevni limit se vidi kao capped', () {
      final result = walkResultFromServer({
        'status': 'rewarded',
        'xp': 10,
        'points': 10,
        'capped': true,
      });
      expect(result.capped, isTrue);
    });

    test('odbijena šetnja: razlog iz servera', () {
      Map<String, dynamic> rejected(String reason) => {
        'status': 'rejected',
        'reason': reason,
      };
      expect(
        walkResultFromServer(rejected('mock_location')).ineligibleReason,
        WalkIneligibleReason.mockLocation,
      );
      expect(
        walkResultFromServer(rejected('suspicious_route')).ineligibleReason,
        WalkIneligibleReason.suspiciousGps,
      );
      expect(
        walkResultFromServer(rejected('duplicate_route')).ineligibleReason,
        WalkIneligibleReason.duplicateRoute,
      );
      expect(
        walkResultFromServer(rejected('expired')).ineligibleReason,
        WalkIneligibleReason.walkExpired,
      );
      expect(
        walkResultFromServer(rejected('route_sparse')).ineligibleReason,
        WalkIneligibleReason.serverRejected,
      );
      final ignored = walkResultFromServer({
        'status': 'ignored',
        'reason': 'too_short',
      });
      expect(ignored.points, 0);
      expect(ignored.ineligibleReason, WalkIneligibleReason.tooShort);
    });
  });

  group('FirestoreRewardsRepository.saveWalk (server plaća)', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreRewardsRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = FirestoreRewardsRepository(
        firestore,
        resultWait: const Duration(milliseconds: 300),
      );
    });

    test(
      'čuva samo zapis šetnje (nikad poene), pa čeka odgovor servera',
      () async {
        final saving = repo.saveWalk(_walk());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Klijent je upisao samo šetnju: ni evidencije ni salda.
        expect((await firestore.doc('users/u1/walks/w1').get()).exists, isTrue);
        expect(
          (await firestore.collection('users/u1/reward_ledger').get()).docs,
          isEmpty,
        );
        expect(
          (await firestore.doc('users/u1/rewards/summary').get()).exists,
          isFalse,
        );

        // „Cloud Function“ odgovara.
        await firestore.doc('users/u1/reward_results/w1').set({
          'status': 'rewarded',
          'xp': 10,
          'points': 10,
          'xpBefore': 0,
        });
        final result = await saving;
        expect(result.saved, isTrue);
        expect(result.points, 10);
        expect(result.pendingSync, isFalse);
      },
    );

    test(
      'server ne odgovori na vreme: šetnja je sačuvana, nagrada stiže',
      () async {
        final result = await repo.saveWalk(_walk());
        expect(result.saved, isTrue);
        expect(result.pendingSync, isTrue);
        expect(result.points, 0);
      },
    );

    test('odbijena šetnja iz servera dobija razlog', () async {
      final saving = repo.saveWalk(_walk());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await firestore.doc('users/u1/reward_results/w1').set({
        'status': 'rejected',
        'reason': 'duplicate_route',
      });
      final result = await saving;
      expect(result.points, 0);
      expect(result.ineligibleReason, WalkIneligibleReason.duplicateRoute);
    });

    test('lažna lokacija: čuva se, ne čeka se server', () async {
      final started = DateTime.now();
      final result = await repo.saveWalk(_walk(mock: true));
      expect(DateTime.now().difference(started).inMilliseconds, lessThan(250));
      expect(result.saved, isTrue);
      expect(result.ineligibleReason, WalkIneligibleReason.mockLocation);
    });

    test('ponovni poziv ne piše šetnju drugi put', () async {
      await repo.saveWalk(_walk(mock: true));
      final first = await firestore.doc('users/u1/walks/w1').get();
      await repo.saveWalk(_walk(mock: true));
      final second = await firestore.doc('users/u1/walks/w1').get();
      expect(second.data(), first.data());
      expect(
        (await firestore.collection('users/u1/walks').get()).docs,
        hasLength(1),
      );
    });

    test('retryPendingWalks i claimChallenges ne diraju bazu', () async {
      expect(await repo.retryPendingWalks('u1'), isEmpty);
      expect(await repo.claimChallenges('u1'), isEmpty);
      expect((await firestore.collection('users').get()).docs, isEmpty);
    });
  });
}
