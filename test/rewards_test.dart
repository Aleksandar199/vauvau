import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/map/domain/completed_walk.dart';
import 'package:vauvau/features/rewards/data/local_rewards_repository.dart';
import 'package:vauvau/features/rewards/data/reward_payloads.dart';
import 'package:vauvau/features/rewards/domain/belgrade_calendar.dart';
import 'package:vauvau/features/rewards/domain/reward_rules.dart';
import 'package:vauvau/features/rewards/domain/rewards_models.dart';
import 'package:vauvau/features/rewards/domain/rewards_repository.dart';

final DateTime _now = DateTime.utc(2026, 10, 16, 10); // petak

CompletedWalk _walk(
  String id, {
  required int meters,
  int minutes = 30,
  String uid = 'u1',
  DateTime? endedAt,
  bool mock = false,
}) {
  final end = endedAt ?? _now.subtract(const Duration(minutes: 1));
  return CompletedWalk(
    id: id,
    userId: uid,
    dogId: 'dog',
    startedAt: end.subtract(Duration(minutes: minutes)),
    endedAt: end,
    durationSeconds: minutes * 60,
    recognizedMeters: meters,
    mockDetected: mock,
  );
}

Coupon _coupon({
  String id = 'c1',
  int cost = 100,
  int max = 5,
  int claimed = 0,
  bool active = true,
  DateTime? startsAt,
  DateTime? expiresAt,
}) => Coupon(
  id: id,
  partnerName: 'Test shop',
  title: 'Hrana',
  description: '',
  discountLabel: '15% popusta',
  pointsCost: cost,
  startsAt: startsAt ?? _now.subtract(const Duration(days: 1)),
  expiresAt: expiresAt ?? _now.add(const Duration(days: 10)),
  maxQuantity: max,
  claimedCount: claimed,
  isActive: active,
);

/// Repo with [points] already earned by u1/u2 (via walks the day before).
Future<LocalRewardsRepository> _repoWithPoints(
  int walksOf6km, {
  List<Coupon> coupons = const [],
}) async {
  final repo = LocalRewardsRepository(challenges: const [], coupons: coupons);
  for (final uid in ['u1', 'u2']) {
    for (var i = 0; i < walksOf6km; i++) {
      // One walk per day (30 points = daily cap), claimed right away.
      final endedAt = _now.subtract(Duration(days: i, minutes: 1));
      await repo.saveWalk(
        _walk('$uid-$i', uid: uid, meters: 6000, minutes: 60, endedAt: endedAt),
        now: endedAt.add(const Duration(minutes: 1)),
      );
    }
  }
  return repo;
}

void main() {
  group('RewardRules – bodovanje', () {
    test('5 XP/poena po celom km od 1 km, zaokruživanje naniže', () {
      expect(
        RewardRules.walkReward(recognizedMeters: 999, paidTodayPoints: 0),
        0,
      );
      expect(
        RewardRules.walkReward(recognizedMeters: 1000, paidTodayPoints: 0),
        5,
      );
      expect(
        RewardRules.walkReward(recognizedMeters: 2999, paidTodayPoints: 0),
        10,
      );
      expect(
        RewardRules.walkReward(recognizedMeters: 3000, paidTodayPoints: 0),
        15,
      );
    });

    test('dnevni limit od 30 poena za kilometre', () {
      expect(
        RewardRules.walkReward(recognizedMeters: 9000, paidTodayPoints: 0),
        30,
      );
      expect(
        RewardRules.walkReward(recognizedMeters: 4000, paidTodayPoints: 20),
        10,
      );
      expect(
        RewardRules.walkReward(recognizedMeters: 4000, paidTodayPoints: 30),
        0,
      );
    });

    test('nevažeće šetnje: lažna lokacija, vožnja, predugo, prekratko', () {
      expect(
        RewardRules.ineligibleReason(_walk('a', meters: 3000, mock: true)),
        WalkIneligibleReason.mockLocation,
      );
      expect(
        RewardRules.ineligibleReason(_walk('b', meters: 10000, minutes: 20)),
        WalkIneligibleReason.tooFastAverage,
      );
      expect(
        RewardRules.ineligibleReason(_walk('c', meters: 20000, minutes: 300)),
        WalkIneligibleReason.tooLong,
      );
      expect(
        RewardRules.ineligibleReason(_walk('d', meters: 700)),
        WalkIneligibleReason.tooShort,
      );
      expect(
        RewardRules.ineligibleReason(
          _walk('e', meters: 2000, uid: 'local-user'),
        ),
        WalkIneligibleReason.notSignedIn,
      );
      expect(RewardRules.ineligibleReason(_walk('f', meters: 3500)), isNull);
      // Kratka šetnja se ipak računa u kilometre izazova, lažna ne.
      expect(
        RewardRules.countsTowardChallenges(_walk('d', meters: 700)),
        isTrue,
      );
      expect(
        RewardRules.countsTowardChallenges(
          _walk('a', meters: 3000, mock: true),
        ),
        isFalse,
      );
    });
  });

  group('LevelRules – nivoi', () {
    test('pragovi Šapica / Istraživač / Avanturista / VauVau ambasador', () {
      expect(LevelRules.levelFor(0).name, 'Šapica');
      expect(LevelRules.levelFor(99).name, 'Šapica');
      expect(LevelRules.levelFor(100).name, 'Istraživač');
      expect(LevelRules.levelFor(249).name, 'Istraživač');
      expect(LevelRules.levelFor(250).name, 'Avanturista');
      expect(LevelRules.levelFor(499).name, 'Avanturista');
      expect(LevelRules.levelFor(500).name, 'VauVau ambasador');
      expect(LevelRules.levelFor(5000).name, 'VauVau ambasador');
    });

    test('napredak, XP do sledećeg i otključavanje', () {
      expect(LevelRules.progress(175), closeTo(0.5, 0.001));
      expect(LevelRules.xpToNext(175), 75);
      expect(LevelRules.nextLevel(600), isNull);
      expect(LevelRules.progress(600), 1);
      expect(LevelRules.unlocked(95, 105)?.name, 'Istraživač');
      expect(LevelRules.unlocked(105, 110), isNull);
    });
  });

  group('BelgradeCalendar – dnevni reset po Beogradu', () {
    test('letnje i zimsko vreme', () {
      expect(BelgradeCalendar.offsetHours(DateTime.utc(2026, 7, 1)), 2);
      expect(BelgradeCalendar.offsetHours(DateTime.utc(2026, 1, 15)), 1);
      // 2026: poslednja nedelja marta = 29., oktobra = 25.
      expect(BelgradeCalendar.offsetHours(DateTime.utc(2026, 3, 29, 0, 59)), 1);
      expect(BelgradeCalendar.offsetHours(DateTime.utc(2026, 3, 29, 1)), 2);
      expect(
        BelgradeCalendar.offsetHours(DateTime.utc(2026, 10, 25, 0, 59)),
        2,
      );
      expect(BelgradeCalendar.offsetHours(DateTime.utc(2026, 10, 25, 1)), 1);
      expect(BelgradeCalendar.offsetHours(DateTime.utc(2026, 10, 24, 23)), 2);
    });

    test('dan menja ponoć u Beogradu, ne UTC ni otvaranje aplikacije', () {
      // 22:30 UTC leti = 00:30 sledećeg dana u Beogradu.
      expect(
        BelgradeCalendar.dayKey(DateTime.utc(2026, 10, 16, 22, 30)),
        20261017,
      );
      expect(
        BelgradeCalendar.dayKey(DateTime.utc(2026, 10, 16, 21, 59)),
        20261016,
      );
      // Zimi je granica 23:00 UTC.
      expect(
        BelgradeCalendar.dayKey(DateTime.utc(2026, 12, 1, 22, 30)),
        20261201,
      );
      expect(
        BelgradeCalendar.dayKey(DateTime.utc(2026, 12, 1, 23, 30)),
        20261202,
      );
    });

    test('nedelja počinje u ponedeljak', () {
      expect(
        BelgradeCalendar.weekKey(DateTime.utc(2026, 10, 16, 10)),
        20261012,
      );
      expect(
        BelgradeCalendar.weekKey(DateTime.utc(2026, 10, 18, 21, 30)),
        20261012,
      );
      // Nedelja 22:30 UTC = ponedeljak 00:30 u Beogradu.
      expect(
        BelgradeCalendar.weekKey(DateTime.utc(2026, 10, 18, 22, 30)),
        20261019,
      );
    });

    test('sledeća ponoć, i u noći promene vremena', () {
      expect(
        BelgradeCalendar.nextMidnight(DateTime.utc(2026, 10, 16, 10)),
        DateTime.utc(2026, 10, 16, 22),
      );
      // Noć 24/25. okt: ponoć 25. je još letnje vreme (22:00 UTC).
      expect(
        BelgradeCalendar.nextMidnight(DateTime.utc(2026, 10, 24, 12)),
        DateTime.utc(2026, 10, 24, 22),
      );
      // Ponoć 26. je zimsko vreme (23:00 UTC).
      expect(
        BelgradeCalendar.nextMidnight(DateTime.utc(2026, 10, 25, 12)),
        DateTime.utc(2026, 10, 25, 23),
      );
    });
  });

  group('Šetnje – zaštita od duplih nagrada', () {
    test(
      'ista šetnja se nagrađuje samo jednom (ponovni zahtev / restart)',
      () async {
        final repo = LocalRewardsRepository(challenges: const []);
        final walk = _walk('w1', meters: 2500);
        final first = await repo.saveWalk(walk, now: _now);
        expect(first.points, 10);
        expect(first.xp, 10);
        final again = await repo.saveWalk(walk, now: _now);
        expect(again.alreadyRewarded, isTrue);
        expect(again.points, 0);
        expect(repo.summaryOf('u1'), const RewardSummary(xp: 10, points: 10));
        final retried = await repo.retryPendingWalks('u1', now: _now);
        expect(retried, isEmpty);
      },
    );

    test('dnevni limit kroz više šetnji istog dana', () async {
      final repo = LocalRewardsRepository(challenges: const []);
      expect(
        (await repo.saveWalk(
          _walk('a', meters: 4200, minutes: 50),
          now: _now,
        )).points,
        20,
      );
      final second = await repo.saveWalk(
        _walk('b', meters: 4000, minutes: 45),
        now: _now,
      );
      expect(second.points, 10);
      expect(second.capped, isTrue);
      expect(
        (await repo.saveWalk(_walk('c', meters: 3000), now: _now)).points,
        0,
      );
      expect(repo.summaryOf('u1').points, 30);
    });

    test('lažna i prespora/prebrza šetnja se ne nagrađuje', () async {
      final repo = LocalRewardsRepository(challenges: const []);
      final fake = await repo.saveWalk(
        _walk('m', meters: 3000, mock: true),
        now: _now,
      );
      expect(fake.points, 0);
      expect(fake.ineligibleReason, WalkIneligibleReason.mockLocation);
      final car = await repo.saveWalk(
        _walk('car', meters: 15000, minutes: 20),
        now: _now,
      );
      expect(car.points, 0);
      expect(repo.summaryOf('u1'), RewardSummary.empty);
    });
  });

  group('Izazovi', () {
    test('dnevni 2 km: nagrada samo jednom dnevno, sutra ponovo', () async {
      final repo = LocalRewardsRepository();
      await repo.saveWalk(_walk('a', meters: 1200), now: _now);
      expect(await repo.claimChallenges('u1', now: _now), isEmpty);
      await repo.saveWalk(_walk('b', meters: 900), now: _now);
      final paid = await repo.claimChallenges('u1', now: _now);
      expect(paid.map((e) => e.challengeId), ['daily_2km']);
      expect(await repo.claimChallenges('u1', now: _now), isEmpty);

      final tomorrow = _now.add(const Duration(days: 1));
      await repo.saveWalk(
        _walk('c', meters: 2100, endedAt: tomorrow),
        now: tomorrow,
      );
      final next = await repo.claimChallenges('u1', now: tomorrow);
      expect(next.map((e) => e.challengeId), contains('daily_2km'));
    });

    test('nedeljni: 3 šetnje od ≥ 1 km i 8 km ukupno', () async {
      final repo = LocalRewardsRepository();
      for (var i = 0; i < 3; i++) {
        final day = _now.subtract(Duration(days: i));
        await repo.saveWalk(
          _walk('w$i', meters: 2800, endedAt: day),
          now: _now,
        );
      }
      final paid = await repo.claimChallenges('u1', now: _now);
      expect(
        paid.map((e) => e.challengeId),
        containsAll(['weekly_3walks', 'weekly_8km']),
      );
      expect(await repo.claimChallenges('u1', now: _now), isEmpty);
    });

    test('neaktivan izazov se ne nagrađuje', () async {
      final repo = LocalRewardsRepository(
        challenges: [
          RewardRules.defaultChallenges.first.copyWith(isActive: false),
        ],
      );
      await repo.saveWalk(_walk('a', meters: 2500), now: _now);
      expect(await repo.claimChallenges('u1', now: _now), isEmpty);
    });
  });

  group('Kuponi', () {
    test('nedovoljno poena: odbijeno bez oduzimanja', () async {
      final repo = await _repoWithPoints(1, coupons: [_coupon()]);
      expect(repo.summaryOf('u1').points, 30);
      await expectLater(
        repo.claimCoupon('u1', 'c1', now: _now),
        throwsA(
          isA<RewardsException>().having(
            (e) => e.code,
            'code',
            RewardsErrorCode.insufficientPoints,
          ),
        ),
      );
      expect(repo.summaryOf('u1').points, 30);
    });

    test('preuzimanje troši poene, ne XP; isti kupon ne dva puta', () async {
      final repo = await _repoWithPoints(4, coupons: [_coupon()]);
      final before = repo.summaryOf('u1');
      final claim = await repo.claimCoupon('u1', 'c1', now: _now);
      expect(CouponCode.pattern.hasMatch(claim.code), isTrue);
      expect(repo.summaryOf('u1').points, before.points - 100);
      expect(repo.summaryOf('u1').xp, before.xp);
      expect(
        LevelRules.levelFor(repo.summaryOf('u1').xp),
        LevelRules.levelFor(before.xp),
      );
      await expectLater(
        repo.claimCoupon('u1', 'c1', now: _now),
        throwsA(isA<RewardsException>()),
      );
    });

    test('istekao, nije počeo, deaktiviran i rasprodat', () async {
      final repo = await _repoWithPoints(
        4,
        coupons: [
          _coupon(
            id: 'old',
            expiresAt: _now.subtract(const Duration(hours: 1)),
          ),
          _coupon(id: 'soon', startsAt: _now.add(const Duration(days: 1))),
          _coupon(id: 'off', active: false),
          _coupon(id: 'gone', max: 3, claimed: 3),
        ],
      );
      Future<RewardsErrorCode> codeOf(String id) async {
        try {
          await repo.claimCoupon('u1', id, now: _now);
          return RewardsErrorCode.unknown;
        } on RewardsException catch (e) {
          return e.code;
        }
      }

      expect(await codeOf('old'), RewardsErrorCode.expired);
      expect(await codeOf('soon'), RewardsErrorCode.notStarted);
      expect(await codeOf('off'), RewardsErrorCode.inactive);
      expect(await codeOf('gone'), RewardsErrorCode.soldOut);
      expect(repo.summaryOf('u1').points, 120);
    });

    test('ograničena količina i istovremeni zahtevi', () async {
      final repo = await _repoWithPoints(4, coupons: [_coupon(max: 1)]);
      final results = await Future.wait([
        repo
            .claimCoupon('u1', 'c1', now: _now)
            .then((_) => true)
            .catchError((_) => false),
        repo
            .claimCoupon('u2', 'c1', now: _now)
            .then((_) => true)
            .catchError((_) => false),
      ]);
      expect(results.where((ok) => ok), hasLength(1));
      final coupons = await repo.watchCoupons().first;
      expect(coupons.single.claimedCount, 1);
      // Poeni su skinuti samo onome ko je dobio kupon.
      final total = repo.summaryOf('u1').points + repo.summaryOf('u2').points;
      expect(total, 240 - 100);
    });

    test('jednokratni kupon: iskorišćen samo jednom; istekli status', () async {
      final repo = await _repoWithPoints(4, coupons: [_coupon()]);
      final claim = await repo.claimCoupon('u1', 'c1', now: _now);
      // Korisnik više sam ne označava kupon; to radi partner (ili admin).
      await repo.partnerRedeem(claim.id, byUid: 'shop', now: _now);
      await expectLater(
        repo.partnerRedeem(claim.id, byUid: 'shop', now: _now),
        throwsA(isA<RewardsException>()),
      );
      final stored = (await repo.watchClaims('u1').first).single;
      expect(stored.status, ClaimStatus.redeemed);
      expect(stored.redeemedBy, 'shop');

      final unused = CouponClaim(
        id: 'x',
        couponId: 'c',
        userId: 'u1',
        code: 'VV-AAAA2222',
        status: ClaimStatus.claimed,
        pointsCost: 10,
        expiresAt: _now,
      );
      expect(unused.effectiveStatus(_now), ClaimStatus.expired);
      expect(
        unused.effectiveStatus(_now.subtract(const Duration(minutes: 1))),
        ClaimStatus.claimed,
      );
    });
  });

  group('Predefinisani kuponi (šabloni)', () {
    test(
      'neaktivni, privremeni partner, stabilni id-jevi i ispravni rokovi',
      () {
        final templates = RewardRules.defaultCoupons(_now);
        expect(templates, isNotEmpty);
        expect(templates.map((c) => c.id).toSet(), hasLength(templates.length));
        for (final c in templates) {
          expect(c.isActive, isFalse);
          expect(RewardRules.isPlaceholderPartner(c.partnerName), isTrue);
          expect(c.pointsCost, greaterThan(0));
          expect(c.maxQuantity, greaterThan(0));
          expect(c.expiresAt.isAfter(c.startsAt), isTrue);
          expect(c.availability(_now), CouponAvailability.inactive);
        }
        expect(RewardRules.isPlaceholderPartner('Pet shop Šapa'), isFalse);
      },
    );

    test('šablon se ne prikazuje korisnicima dok nije aktiviran', () async {
      final repo = LocalRewardsRepository(challenges: const []);
      for (final c in RewardRules.defaultCoupons(_now)) {
        await repo.saveCoupon(c);
      }
      expect(await repo.watchCoupons().first, isEmpty);
      expect(await repo.watchCoupons(activeOnly: false).first, hasLength(5));
    });
  });

  group('Kompatibilnost sa postojećim profilima', () {
    test('korisnik bez dokumenata nagrada = 0 XP, Šapica', () {
      final summary = RewardSummary.fromMap(null);
      expect(summary, RewardSummary.empty);
      expect(LevelRules.levelFor(summary.xp).name, 'Šapica');
      expect(PeriodProgress.fromMap({'meters': 'x'}).meters, 0);
    });

    test('stara šetnja bez recognizedMeters se ne nagrađuje naknadno', () {
      final legacy = completedWalkFromDoc('u1', 'old', {
        'distanceKm': 5.0,
        'durationSeconds': 3600,
        'startedAt': _now.subtract(const Duration(hours: 1)),
        'endedAt': _now,
      });
      expect(legacy, isNull);
    });

    test('nepoznata/stara polja u kuponu i izazovu ne ruše čitanje', () {
      final c = Challenge.fromMap('x', {'title': 5, 'target': 'dva'});
      expect(c.title, '');
      expect(c.target, 0);
      expect(c.isActive, isFalse);
      final coupon = Coupon.fromMap('y', const {});
      expect(coupon.availability(_now), CouponAvailability.inactive);
    });
  });
}
