import 'dart:async';

import '../../map/data/walk_history_repository.dart';
import '../../map/domain/completed_walk.dart';
import '../../map/domain/walk_record.dart';
import '../domain/belgrade_calendar.dart';
import '../domain/reward_rules.dart';
import '../domain/rewards_models.dart';
import '../domain/rewards_repository.dart';
import 'reward_payloads.dart';

/// In-memory implementation (no Firebase, tests). Applies the same checks
/// as the Firestore rules so the business logic can be tested in Dart.
class LocalRewardsRepository implements RewardsRepository {
  LocalRewardsRepository({
    this.walkHistory,
    List<Challenge>? challenges,
    List<Coupon>? coupons,
  }) {
    for (final challenge in challenges ?? RewardRules.defaultChallenges) {
      _challenges[challenge.id] = challenge;
    }
    for (final coupon in coupons ?? const <Coupon>[]) {
      _coupons[coupon.id] = coupon;
    }
  }

  final WalkHistoryRepository? walkHistory;
  final Map<String, RewardSummary> _summaries = {};
  final Map<String, PeriodProgress> _progress = {};
  final Map<String, Map<String, LedgerEntry>> _ledger = {};
  final Map<String, Challenge> _challenges = {};
  final Map<String, Coupon> _coupons = {};
  final Map<String, CouponClaim> _claims = {};
  final Map<String, Map<String, CompletedWalk>> _walks = {};
  final _changes = StreamController<void>.broadcast();
  var _couponSeq = 0;

  /// Saved walks per user (tests).
  Map<String, CompletedWalk> walksOf(String uid) => _walks[uid] ?? const {};

  void dispose() => _changes.close();

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  RewardSummary summaryOf(String uid) => _summaries[uid] ?? RewardSummary.empty;

  PeriodProgress _period(String uid, String key) =>
      _progress['$uid/$key'] ?? PeriodProgress.empty;

  void _addEntry(String uid, LedgerEntry entry) {
    final s = summaryOf(uid);
    final points = s.points + entry.points;
    if (points < 0) {
      throw const RewardsException(RewardsErrorCode.insufficientPoints);
    }
    _ledger.putIfAbsent(uid, () => {})[entry.id] = entry;
    _summaries[uid] = RewardSummary(xp: s.xp + entry.xp, points: points);
  }

  bool _hasEntry(String uid, String id) =>
      _ledger[uid]?.containsKey(id) ?? false;

  @override
  Stream<RewardSummary> watchSummary(String uid) => _live(() => summaryOf(uid));

  @override
  Stream<RewardProgress> watchProgress(
    String uid, {
    required int dayKey,
    required int weekKey,
  }) => _live(
    () => RewardProgress(
      dayKey: dayKey,
      weekKey: weekKey,
      day: _period(uid, 'd$dayKey'),
      week: _period(uid, 'w$weekKey'),
    ),
  );

  @override
  Stream<List<LedgerEntry>> watchLedger(String uid, {int limit = 50}) =>
      _live(() {
        final list = (_ledger[uid]?.values.toList() ?? <LedgerEntry>[])
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
              a.createdAt ?? DateTime(2000),
            ),
          );
        return list.take(limit).toList();
      });

  @override
  Stream<List<Challenge>> watchChallenges({bool activeOnly = true}) => _live(
    () => [
      for (final c in _challenges.values)
        if (!activeOnly || c.isActive) c,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );

  @override
  Stream<List<Coupon>> watchCoupons({bool activeOnly = true}) => _live(
    () => [
      for (final c in _coupons.values)
        if (!activeOnly || c.isActive) c,
    ]..sort((a, b) => a.pointsCost.compareTo(b.pointsCost)),
  );

  @override
  Stream<List<CouponClaim>> watchClaims(String uid) => _live(
    () => sortClaims([
      for (final c in _claims.values)
        if (c.userId == uid) c,
    ]),
  );

  @override
  Future<WalkSaveResult> saveWalk(CompletedWalk walk, {DateTime? now}) async {
    final reason = RewardRules.ineligibleReason(walk);
    if (walk.worthSaving || RewardRules.countsTowardChallenges(walk)) {
      _walks.putIfAbsent(walk.userId, () => {})[walk.id] = walk;
      await walkHistory?.save(
        WalkRecord(
          id: walk.id,
          userId: walk.userId,
          dogId: walk.dogId,
          distanceKm: walk.recognizedKm,
          durationSeconds: walk.durationSeconds,
          startedAt: walk.startedAt,
          endedAt: walk.endedAt,
          statusMessage: walk.statusMessage,
        ),
      );
    }
    if (!RewardRules.countsTowardChallenges(walk)) {
      _notify();
      return WalkSaveResult(saved: walk.worthSaving, ineligibleReason: reason);
    }
    final xpBefore = summaryOf(walk.userId).xp;
    final points = _payWalk(walk, now ?? DateTime.now());
    _notify();
    if (points == null) {
      return WalkSaveResult(
        saved: true,
        alreadyRewarded: true,
        eligible: reason == null,
        ineligibleReason: reason,
        xpBefore: xpBefore,
        xpAfter: xpBefore,
      );
    }
    final km = RewardRules.wholeKm(walk.recognizedMeters);
    return WalkSaveResult(
      saved: true,
      eligible: reason == null,
      ineligibleReason: reason,
      xp: points,
      points: points,
      capped: points < km * RewardRules.pointsPerKm,
      xpBefore: xpBefore,
      xpAfter: xpBefore + points,
    );
  }

  /// Null when the walk was already paid.
  int? _payWalk(CompletedWalk walk, DateTime now) {
    final uid = walk.userId;
    final entryId = LedgerEntry.walkEntryId(walk.id);
    if (_hasEntry(uid, entryId)) return null;
    if (walk.endedAt.isBefore(now.subtract(RewardRules.claimWindow))) {
      throw const RewardsException(RewardsErrorCode.denied, 'claim window');
    }
    final dayKey = BelgradeCalendar.dayKey(walk.endedAt);
    final weekKey = BelgradeCalendar.weekKey(walk.endedAt);
    final day = _period(uid, 'd$dayKey');
    final week = _period(uid, 'w$weekKey');
    final km = RewardRules.wholeKm(walk.recognizedMeters);
    final points = RewardRules.walkReward(
      recognizedMeters: walk.recognizedMeters,
      paidTodayPoints: day.walkPoints,
    );
    final counted = km >= RewardRules.minRewardKm ? 1 : 0;
    _addEntry(
      uid,
      LedgerEntry(
        id: entryId,
        type: LedgerType.walk,
        xp: points,
        points: points,
        reason: walkReason(km, points),
        createdAt: now,
        walkId: walk.id,
        periodKey: dayKey,
        km: km,
      ),
    );
    PeriodProgress add(PeriodProgress p) => PeriodProgress(
      meters: p.meters + walk.recognizedMeters,
      walks: p.walks + counted,
      walkPoints: p.walkPoints + points,
    );
    _progress['$uid/d$dayKey'] = add(day);
    _progress['$uid/w$weekKey'] = add(week);
    return points;
  }

  @override
  Future<List<LedgerEntry>> retryPendingWalks(
    String uid, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final paid = <LedgerEntry>[];
    for (final walk in walksOf(uid).values) {
      if (!RewardRules.countsTowardChallenges(walk)) continue;
      if (walk.endedAt.isBefore(at.subtract(RewardRules.claimWindow))) continue;
      final points = _payWalk(walk, at);
      if (points != null) {
        paid.add(_ledger[uid]![LedgerEntry.walkEntryId(walk.id)]!);
      }
    }
    if (paid.isNotEmpty) _notify();
    return paid;
  }

  @override
  Future<List<LedgerEntry>> claimChallenges(
    String uid, {
    DateTime? now,
    DateTime? at,
  }) async {
    final current = now ?? DateTime.now();
    final paid = <LedgerEntry>[];
    for (final moment in {current, ?at}) {
      final progress = RewardProgress(
        dayKey: BelgradeCalendar.dayKey(moment),
        weekKey: BelgradeCalendar.weekKey(moment),
        day: _period(uid, 'd${BelgradeCalendar.dayKey(moment)}'),
        week: _period(uid, 'w${BelgradeCalendar.weekKey(moment)}'),
      );
      for (final challenge in _challenges.values) {
        if (!challenge.isActive || !challenge.isMet(progress)) continue;
        final periodKey = challenge.periodKey(progress);
        final entryId = LedgerEntry.challengeEntryId(challenge.id, periodKey);
        if (_hasEntry(uid, entryId)) continue;
        final entry = LedgerEntry(
          id: entryId,
          type: LedgerType.challenge,
          xp: challenge.rewardXp,
          points: challenge.rewardPoints,
          reason: challengeReason(challenge),
          createdAt: current,
          challengeId: challenge.id,
          periodKey: periodKey,
        );
        _addEntry(uid, entry);
        paid.add(entry);
      }
    }
    if (paid.isNotEmpty) _notify();
    return paid;
  }

  @override
  Future<CouponClaim> claimCoupon(
    String uid,
    String couponId, {
    DateTime? now,
  }) async {
    // Dart runs this synchronously up to the first await, so two parallel
    // calls can't both take the last coupon (like a Firestore transaction).
    final at = now ?? DateTime.now();
    final coupon = _coupons[couponId];
    if (coupon == null) {
      throw const RewardsException(RewardsErrorCode.inactive);
    }
    final claimId = CouponClaim.docId(couponId, uid);
    if (_claims.containsKey(claimId)) {
      throw const RewardsException(RewardsErrorCode.alreadyClaimed);
    }
    checkCouponClaimable(coupon, summaryOf(uid), at);
    _addEntry(
      uid,
      LedgerEntry(
        id: LedgerEntry.couponEntryId(couponId),
        type: LedgerType.coupon,
        xp: 0,
        points: -coupon.pointsCost,
        reason: couponReason(coupon),
        createdAt: at,
        couponId: couponId,
      ),
    );
    _coupons[couponId] = Coupon.fromMap(couponId, {
      ..._couponMap(coupon),
      'claimedCount': coupon.claimedCount + 1,
    });
    final claim = CouponClaim(
      id: claimId,
      couponId: couponId,
      userId: uid,
      code: CouponCode.generate(),
      status: ClaimStatus.claimed,
      pointsCost: coupon.pointsCost,
      claimedAt: at,
      expiresAt: coupon.expiresAt,
      partnerName: coupon.partnerName,
      title: coupon.title,
      discountLabel: coupon.discountLabel,
    );
    _claims[claimId] = claim;
    _notify();
    return claim;
  }

  @override
  Future<void> markRedeemed(String claimId) async {
    final claim = _claims[claimId];
    if (claim == null || claim.status != ClaimStatus.claimed) {
      throw const RewardsException(RewardsErrorCode.denied);
    }
    _claims[claimId] = _withStatus(claim, ClaimStatus.redeemed);
    _notify();
  }

  @override
  Future<void> saveChallenge(Challenge challenge) async {
    final id = challenge.id.isEmpty
        ? 'ch${_challenges.length + 1}'
        : challenge.id;
    _challenges[id] = Challenge.fromMap(id, challenge.toMap());
    _notify();
  }

  @override
  Future<void> setChallengeActive(String id, bool active) async {
    final c = _challenges[id];
    if (c != null) _challenges[id] = c.copyWith(isActive: active);
    _notify();
  }

  @override
  Future<void> saveCoupon(Coupon coupon) async {
    final id = coupon.id.isEmpty ? 'coupon${++_couponSeq}' : coupon.id;
    final claimed = _coupons[id]?.claimedCount ?? 0;
    _coupons[id] = Coupon.fromMap(id, {
      ..._couponMap(coupon),
      'claimedCount': claimed,
    });
    _notify();
  }

  @override
  Future<void> setCouponActive(String id, bool active) async {
    final c = _coupons[id];
    if (c != null) {
      _coupons[id] = Coupon.fromMap(id, {..._couponMap(c), 'isActive': active});
    }
    _notify();
  }

  @override
  Stream<List<LedgerEntry>> watchAllLedger({int limit = 100}) => _live(
    () => [
      for (final entry in _ledger.entries)
        for (final e in entry.value.values)
          LedgerEntry(
            id: e.id,
            type: e.type,
            xp: e.xp,
            points: e.points,
            reason: e.reason,
            createdAt: e.createdAt,
            walkId: e.walkId,
            challengeId: e.challengeId,
            couponId: e.couponId,
            periodKey: e.periodKey,
            km: e.km,
            userId: entry.key,
          ),
    ].take(limit).toList(),
  );

  @override
  Stream<List<CouponClaim>> watchAllClaims({int limit = 200}) =>
      _live(() => sortClaims(_claims.values.toList()).take(limit).toList());

  @override
  Future<void> adminSetClaimStatus(String claimId, ClaimStatus status) async {
    final claim = _claims[claimId];
    if (claim == null || claim.status != ClaimStatus.claimed) {
      throw const RewardsException(RewardsErrorCode.denied);
    }
    _claims[claimId] = _withStatus(claim, status);
    _notify();
  }

  CouponClaim _withStatus(CouponClaim c, ClaimStatus status) => CouponClaim(
    id: c.id,
    couponId: c.couponId,
    userId: c.userId,
    code: c.code,
    status: status,
    pointsCost: c.pointsCost,
    claimedAt: c.claimedAt,
    redeemedAt: status == ClaimStatus.redeemed ? DateTime.now() : null,
    expiresAt: c.expiresAt,
    partnerName: c.partnerName,
    title: c.title,
    discountLabel: c.discountLabel,
  );

  Map<String, dynamic> _couponMap(Coupon c) => {
    'partnerName': c.partnerName,
    'title': c.title,
    'description': c.description,
    'discountLabel': c.discountLabel,
    'pointsCost': c.pointsCost,
    'startsAt': c.startsAt,
    'expiresAt': c.expiresAt,
    'maxQuantity': c.maxQuantity,
    'claimedCount': c.claimedCount,
    'terms': c.terms,
    'isActive': c.isActive,
  };
}
