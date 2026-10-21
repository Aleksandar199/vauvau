import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../map/domain/completed_walk.dart';
import '../domain/belgrade_calendar.dart';
import '../domain/reward_rules.dart';
import '../domain/rewards_models.dart';
import '../domain/rewards_repository.dart';
import 'reward_payloads.dart';

/// Firestore layout (no duplicate collections):
/// - `users/{uid}/walks/{walkId}` – walk + route, owner only (existing).
/// - `users/{uid}/rewards/summary` – xp, points, lastEntryId.
/// - `users/{uid}/rewards/d{dayKey}` / `w{weekKey}` – km/walk progress.
/// - `users/{uid}/reward_ledger/{entryId}` – immutable balance changes.
/// - `reward_challenges/{id}`, `reward_coupons/{id}` – admin content.
/// - `coupon_claims/{couponId}_{uid}` – the user's coupon + code.
class FirestoreRewardsRepository implements RewardsRepository {
  FirestoreRewardsRepository(this._db, {Duration? commitTimeout})
    : _commitTimeout = commitTimeout ?? const Duration(seconds: 12);

  final FirebaseFirestore _db;
  final Duration _commitTimeout;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _summary(String uid) =>
      _user(uid).collection('rewards').doc('summary');

  DocumentReference<Map<String, dynamic>> _day(String uid, int key) =>
      _user(uid).collection('rewards').doc('d$key');

  DocumentReference<Map<String, dynamic>> _week(String uid, int key) =>
      _user(uid).collection('rewards').doc('w$key');

  CollectionReference<Map<String, dynamic>> _ledger(String uid) =>
      _user(uid).collection('reward_ledger');

  CollectionReference<Map<String, dynamic>> _walks(String uid) =>
      _user(uid).collection('walks');

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _db.collection('reward_challenges');

  CollectionReference<Map<String, dynamic>> get _coupons =>
      _db.collection('reward_coupons');

  CollectionReference<Map<String, dynamic>> get _claims =>
      _db.collection('coupon_claims');

  // --- Streams ---------------------------------------------------------------

  @override
  Stream<RewardSummary> watchSummary(String uid) {
    return FirestoreAuthGuard.guardedStream<RewardSummary>(
      label: 'rewards.summary',
      empty: RewardSummary.empty,
      create: () => _summary(
        uid,
      ).snapshots().map((snap) => RewardSummary.fromMap(snap.data())),
    );
  }

  @override
  Stream<RewardProgress> watchProgress(
    String uid, {
    required int dayKey,
    required int weekKey,
  }) {
    return FirestoreAuthGuard.guardedStream<RewardProgress>(
      label: 'rewards.progress',
      empty: RewardProgress(dayKey: dayKey, weekKey: weekKey),
      create: () {
        late StreamController<RewardProgress> controller;
        var day = PeriodProgress.empty;
        var week = PeriodProgress.empty;
        final subs = <StreamSubscription<Object?>>[];
        void emit() => controller.add(
          RewardProgress(
            dayKey: dayKey,
            weekKey: weekKey,
            day: day,
            week: week,
          ),
        );
        controller = StreamController<RewardProgress>(
          onListen: () {
            subs
              ..add(
                _day(uid, dayKey).snapshots().listen((snap) {
                  day = PeriodProgress.fromMap(snap.data());
                  emit();
                }, onError: controller.addError),
              )
              ..add(
                _week(uid, weekKey).snapshots().listen((snap) {
                  week = PeriodProgress.fromMap(snap.data());
                  emit();
                }, onError: controller.addError),
              );
          },
          onCancel: () async {
            for (final sub in subs) {
              await sub.cancel();
            }
          },
        );
        return controller.stream;
      },
    );
  }

  @override
  Stream<List<LedgerEntry>> watchLedger(String uid, {int limit = 50}) {
    return FirestoreAuthGuard.guardedStream<List<LedgerEntry>>(
      label: 'rewards.ledger',
      empty: const [],
      create: () => _ledger(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snap) => [
              for (final doc in snap.docs)
                LedgerEntry.fromMap(doc.id, plainData(doc.data())),
            ],
          ),
    );
  }

  @override
  Stream<List<Challenge>> watchChallenges({bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _challenges;
    if (activeOnly) query = query.where('isActive', isEqualTo: true);
    return FirestoreAuthGuard.guardedStream<List<Challenge>>(
      label: 'rewards.challenges',
      empty: const [],
      create: () => query.snapshots().map((snap) {
        final list = [
          for (final doc in snap.docs)
            Challenge.fromMap(doc.id, plainData(doc.data())),
        ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return list;
      }),
    );
  }

  @override
  Stream<List<Coupon>> watchCoupons({bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _coupons;
    if (activeOnly) query = query.where('isActive', isEqualTo: true);
    return FirestoreAuthGuard.guardedStream<List<Coupon>>(
      label: 'rewards.coupons',
      empty: const [],
      create: () => query.snapshots().map((snap) {
        final list = [
          for (final doc in snap.docs)
            Coupon.fromMap(doc.id, plainData(doc.data())),
        ]..sort((a, b) => a.pointsCost.compareTo(b.pointsCost));
        return list;
      }),
    );
  }

  @override
  Stream<List<CouponClaim>> watchClaims(String uid) {
    // Equality filter only (no composite index); sorted on the client.
    return FirestoreAuthGuard.guardedStream<List<CouponClaim>>(
      label: 'rewards.claims',
      empty: const [],
      create: () => _claims
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map(
            (snap) => sortClaims([
              for (final doc in snap.docs)
                CouponClaim.fromMap(doc.id, plainData(doc.data())),
            ]),
          ),
    );
  }

  // --- Walks -----------------------------------------------------------------

  @override
  Future<WalkSaveResult> saveWalk(CompletedWalk walk, {DateTime? now}) async {
    final reason = RewardRules.ineligibleReason(walk);
    final walkRef = _walks(walk.userId).doc(walk.id);
    final walkData = walkPayload(walk);

    if (!RewardRules.countsTowardChallenges(walk)) {
      final saved = await _saveWalkOnly(walkRef, walk, walkData);
      return WalkSaveResult(
        saved: saved.saved,
        pendingSync: saved.pending,
        ineligibleReason: reason,
      );
    }

    try {
      final outcome = await _payWalk(
        walk.userId,
        walkRef: walkRef,
        walkData: walkData,
        recognizedMeters: walk.recognizedMeters,
        endedAt: walk.endedAt,
      );
      return WalkSaveResult(
        saved: true,
        eligible: reason == null,
        ineligibleReason: reason,
        xp: outcome.points,
        points: outcome.points,
        capped: outcome.capped,
        alreadyRewarded: outcome.already,
        pendingSync: outcome.pending,
        xpBefore: outcome.xpBefore,
        xpAfter: outcome.xpBefore + outcome.points,
      );
    } on RewardsException catch (error) {
      debugPrint('Walk reward not written: $error');
      // Old rules / offline read: keep at least the walk (reward retried
      // later by retryPendingWalks while inside the claim window).
      final saved = await _saveWalkOnly(walkRef, walk, walkData);
      return WalkSaveResult(
        saved: saved.saved,
        pendingSync: saved.pending || error.code == RewardsErrorCode.offline,
        rewardDenied: error.code == RewardsErrorCode.denied,
        ineligibleReason: reason,
      );
    }
  }

  /// Writes walk + ledger + summary + day + week in one batch.
  Future<_PayOutcome> _payWalk(
    String uid, {
    required DocumentReference<Map<String, dynamic>> walkRef,
    required Map<String, Object?>? walkData,
    required int recognizedMeters,
    required DateTime endedAt,
  }) async {
    final entryId = LedgerEntry.walkEntryId(walkRef.id);
    final ledgerRef = _ledger(uid).doc(entryId);
    final dayKey = BelgradeCalendar.dayKey(endedAt);
    final weekKey = BelgradeCalendar.weekKey(endedAt);
    final dayRef = _day(uid, dayKey);
    final weekRef = _week(uid, weekKey);

    final List<DocumentSnapshot<Map<String, dynamic>>> snaps;
    try {
      snaps = await Future.wait([
        ledgerRef.get(),
        walkRef.get(),
        _summary(uid).get(),
        dayRef.get(),
        weekRef.get(),
      ]);
    } catch (error) {
      throw _mapError(error);
    }
    final summary = RewardSummary.fromMap(snaps[2].data());
    if (snaps[0].exists) {
      return _PayOutcome(points: 0, already: true, xpBefore: summary.xp);
    }
    final day = PeriodProgress.fromMap(snaps[3].data());
    final week = PeriodProgress.fromMap(snaps[4].data());
    final km = RewardRules.wholeKm(recognizedMeters);
    final points = RewardRules.walkReward(
      recognizedMeters: recognizedMeters,
      paidTodayPoints: day.walkPoints,
    );
    final counted = km >= RewardRules.minRewardKm ? 1 : 0;

    final batch = _db.batch();
    // Walk docs are immutable under the rules: only create when missing.
    if (!snaps[1].exists && walkData != null) {
      batch.set(walkRef, walkData);
    }
    batch
      ..set(ledgerRef, {
        'type': 'walk',
        'walkId': walkRef.id,
        'km': km,
        'dayKey': dayKey,
        'weekKey': weekKey,
        'xp': points,
        'points': points,
        'reason': walkReason(km, points),
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(_summary(uid), {
        'xp': summary.xp + points,
        'points': summary.points + points,
        'lastEntryId': entryId,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        dayRef,
        progressPayload(day, recognizedMeters, counted, points, entryId),
      )
      ..set(
        weekRef,
        progressPayload(week, recognizedMeters, counted, points, entryId),
      );

    final pending = await _commit(batch);
    return _PayOutcome(
      points: points,
      capped: points < km * RewardRules.pointsPerKm,
      pending: pending,
      xpBefore: summary.xp,
    );
  }

  Future<({bool saved, bool pending})> _saveWalkOnly(
    DocumentReference<Map<String, dynamic>> walkRef,
    CompletedWalk walk,
    Map<String, Object?> walkData,
  ) async {
    if (!walk.worthSaving) return (saved: false, pending: false);
    try {
      final existing = await walkRef.get();
      if (existing.exists) return (saved: true, pending: false);
    } catch (_) {
      // Offline without cache: just queue the write.
    }
    try {
      final batch = _db.batch()..set(walkRef, walkData);
      final pending = await _commit(batch);
      return (saved: true, pending: pending);
    } on RewardsException catch (error) {
      if (error.code != RewardsErrorCode.denied) {
        return (saved: false, pending: false);
      }
    }
    // Last resort for the currently deployed (old) rules: the legacy array
    // on the public profile, without the route.
    try {
      await _user(walk.userId).set({
        'walkHistory': FieldValue.arrayUnion([legacyWalkPayload(walk)]),
      }, SetOptions(merge: true));
      return (saved: true, pending: false);
    } catch (error) {
      debugPrint('Walk save failed: $error');
      return (saved: false, pending: false);
    }
  }

  @override
  Future<List<LedgerEntry>> retryPendingWalks(
    String uid, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    // A bit inside the rules' window so the server clock still accepts it.
    final cutoff = at.subtract(
      RewardRules.claimWindow - const Duration(minutes: 10),
    );
    final paid = <LedgerEntry>[];
    try {
      final snap = await _walks(
        uid,
      ).where('endedAt', isGreaterThan: Timestamp.fromDate(cutoff)).get();
      for (final doc in snap.docs) {
        final walk = completedWalkFromDoc(uid, doc.id, plainData(doc.data()));
        if (walk == null || !RewardRules.countsTowardChallenges(walk)) {
          continue;
        }
        final outcome = await _payWalk(
          uid,
          walkRef: doc.reference,
          walkData: null,
          recognizedMeters: walk.recognizedMeters,
          endedAt: walk.endedAt,
        );
        if (!outcome.already && !outcome.pending) {
          paid.add(
            LedgerEntry(
              id: LedgerEntry.walkEntryId(doc.id),
              type: LedgerType.walk,
              xp: outcome.points,
              points: outcome.points,
              reason: walkReason(
                RewardRules.wholeKm(walk.recognizedMeters),
                outcome.points,
              ),
              walkId: doc.id,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('retryPendingWalks: $error');
    }
    return paid;
  }

  // --- Challenges ------------------------------------------------------------

  @override
  Future<List<LedgerEntry>> claimChallenges(
    String uid, {
    DateTime? now,
    DateTime? at,
  }) async {
    final current = now ?? DateTime.now();
    final moments = {current, ?at};
    final paid = <LedgerEntry>[];
    List<Challenge> challenges;
    try {
      final snap = await _challenges.where('isActive', isEqualTo: true).get();
      challenges = [
        for (final doc in snap.docs)
          Challenge.fromMap(doc.id, plainData(doc.data())),
      ];
    } catch (error) {
      debugPrint('claimChallenges: $error');
      return paid;
    }
    final seen = <String>{};
    for (final moment in moments) {
      final dayKey = BelgradeCalendar.dayKey(moment);
      final weekKey = BelgradeCalendar.weekKey(moment);
      RewardProgress progress;
      try {
        final snaps = await Future.wait([
          _day(uid, dayKey).get(),
          _week(uid, weekKey).get(),
        ]);
        progress = RewardProgress(
          dayKey: dayKey,
          weekKey: weekKey,
          day: PeriodProgress.fromMap(snaps[0].data()),
          week: PeriodProgress.fromMap(snaps[1].data()),
        );
      } catch (error) {
        debugPrint('claimChallenges progress: $error');
        continue;
      }
      for (final challenge in challenges) {
        if (!challenge.isMet(progress)) continue;
        final periodKey = challenge.periodKey(progress);
        final entryId = LedgerEntry.challengeEntryId(challenge.id, periodKey);
        if (!seen.add(entryId)) continue;
        final entry = await _claimChallenge(uid, challenge, periodKey, entryId);
        if (entry != null) paid.add(entry);
      }
    }
    return paid;
  }

  Future<LedgerEntry?> _claimChallenge(
    String uid,
    Challenge challenge,
    int periodKey,
    String entryId,
  ) async {
    final ledgerRef = _ledger(uid).doc(entryId);
    final reason = challengeReason(challenge);
    try {
      final created = await _db
          .runTransaction<bool>((tx) async {
            final existing = await tx.get(ledgerRef);
            if (existing.exists) return false;
            final summary = RewardSummary.fromMap(
              (await tx.get(_summary(uid))).data(),
            );
            tx
              ..set(ledgerRef, {
                'type': 'challenge',
                'challengeId': challenge.id,
                'periodKey': periodKey,
                'xp': challenge.rewardXp,
                'points': challenge.rewardPoints,
                'reason': reason,
                'createdAt': FieldValue.serverTimestamp(),
              })
              ..set(_summary(uid), {
                'xp': summary.xp + challenge.rewardXp,
                'points': summary.points + challenge.rewardPoints,
                'lastEntryId': entryId,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            return true;
          })
          .timeout(_commitTimeout);
      if (!created) return null;
      return LedgerEntry(
        id: entryId,
        type: LedgerType.challenge,
        xp: challenge.rewardXp,
        points: challenge.rewardPoints,
        reason: reason,
        challengeId: challenge.id,
        periodKey: periodKey,
      );
    } catch (error) {
      // Offline, rules not deployed or already paid by another device.
      debugPrint('Challenge ${challenge.id} not claimed: $error');
      return null;
    }
  }

  // --- Coupons ---------------------------------------------------------------

  @override
  Future<CouponClaim> claimCoupon(
    String uid,
    String couponId, {
    DateTime? now,
  }) async {
    final couponRef = _coupons.doc(couponId);
    final claimRef = _claims.doc(CouponClaim.docId(couponId, uid));
    final entryId = LedgerEntry.couponEntryId(couponId);
    final ledgerRef = _ledger(uid).doc(entryId);
    try {
      return await _db
          .runTransaction<CouponClaim>((tx) async {
            final couponSnap = await tx.get(couponRef);
            if (!couponSnap.exists) {
              throw const RewardsException(RewardsErrorCode.inactive);
            }
            final coupon = Coupon.fromMap(
              couponId,
              plainData(couponSnap.data()!),
            );
            final claimSnap = await tx.get(claimRef);
            if (claimSnap.exists) {
              throw const RewardsException(RewardsErrorCode.alreadyClaimed);
            }
            final summary = RewardSummary.fromMap(
              (await tx.get(_summary(uid))).data(),
            );
            checkCouponClaimable(coupon, summary, now ?? DateTime.now());

            final code = CouponCode.generate();
            final claimData = claimPayload(coupon, uid, code);
            tx
              ..set(claimRef, claimData)
              ..update(couponRef, {'claimedCount': coupon.claimedCount + 1})
              ..set(ledgerRef, {
                'type': 'coupon',
                'couponId': couponId,
                'xp': 0,
                'points': -coupon.pointsCost,
                'reason': couponReason(coupon),
                'createdAt': FieldValue.serverTimestamp(),
              })
              ..set(_summary(uid), {
                'xp': summary.xp,
                'points': summary.points - coupon.pointsCost,
                'lastEntryId': entryId,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            return CouponClaim(
              id: claimRef.id,
              couponId: couponId,
              userId: uid,
              code: code,
              status: ClaimStatus.claimed,
              pointsCost: coupon.pointsCost,
              claimedAt: now ?? DateTime.now(),
              expiresAt: coupon.expiresAt,
              partnerName: coupon.partnerName,
              title: coupon.title,
              discountLabel: coupon.discountLabel,
              partnerId: coupon.partnerId,
            );
          })
          .timeout(_commitTimeout);
    } on RewardsException {
      rethrow;
    } on TimeoutException {
      throw const RewardsException(RewardsErrorCode.offline);
    } catch (error) {
      throw _mapError(error);
    }
  }

  // --- Partner shop ------------------------------------------------------------

  @override
  Future<CouponClaim?> findPartnerClaim(String partnerId, String code) async {
    if (partnerId.isEmpty) return null;
    try {
      // Both filters are needed: the rules only allow the partner's own list.
      final snap = await _claims
          .where('partnerId', isEqualTo: partnerId)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return CouponClaim.fromMap(doc.id, plainData(doc.data()));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> partnerRedeem(
    String claimId, {
    required String byUid,
    DateTime? now,
  }) async {
    try {
      await _claims.doc(claimId).update({
        'status': 'redeemed',
        'redeemedAt': FieldValue.serverTimestamp(),
        'redeemedBy': byUid,
      });
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Stream<List<CouponClaim>> watchPartnerClaims(
    String partnerId, {
    int limit = 50,
  }) {
    if (partnerId.isEmpty) return Stream.value(const []);
    return FirestoreAuthGuard.guardedStream<List<CouponClaim>>(
      label: 'rewards.partnerClaims',
      empty: const [],
      create: () => _claims
          .where('partnerId', isEqualTo: partnerId)
          .orderBy('claimedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snap) => [
              for (final doc in snap.docs)
                CouponClaim.fromMap(doc.id, plainData(doc.data())),
            ],
          ),
    );
  }

  // --- Admin -------------------------------------------------------------------

  @override
  Future<void> saveChallenge(Challenge challenge) async {
    final ref = challenge.id.isEmpty
        ? _challenges.doc()
        : _challenges.doc(challenge.id);
    await ref.set({
      ...challenge.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setChallengeActive(String id, bool active) => _challenges
      .doc(id)
      .update({'isActive': active, 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> saveCoupon(Coupon coupon) async {
    if (coupon.id.isEmpty) {
      await _coupons.doc().set({
        ...couponPayload(coupon),
        'claimedCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    // claimedCount is never overwritten by an edit.
    await _coupons.doc(coupon.id).set({
      ...couponPayload(coupon),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setCouponActive(String id, bool active) =>
      _coupons.doc(id).update({'isActive': active});

  @override
  Future<void> setCouponRemaining(String id, int remaining) {
    if (remaining < 0) throw ArgumentError.value(remaining, 'remaining');
    final ref = _coupons.doc(id);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final claimed = Coupon.fromMap(id, plainData(snap.data() ?? {}))
          .claimedCount;
      tx.update(ref, {
        'maxQuantity': claimed + remaining,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Stream<List<LedgerEntry>> watchAllLedger({int limit = 100}) {
    return FirestoreAuthGuard.guardedStream<List<LedgerEntry>>(
      label: 'rewards.adminLedger',
      empty: const [],
      create: () => _db
          .collectionGroup('reward_ledger')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snap) => [
              for (final doc in snap.docs)
                LedgerEntry.fromMap(
                  doc.id,
                  plainData(doc.data()),
                  userId: doc.reference.parent.parent?.id ?? '',
                ),
            ],
          ),
    );
  }

  @override
  Stream<List<CouponClaim>> watchAllClaims({int limit = 200}) {
    return FirestoreAuthGuard.guardedStream<List<CouponClaim>>(
      label: 'rewards.adminClaims',
      empty: const [],
      create: () => _claims
          .orderBy('claimedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snap) => [
              for (final doc in snap.docs)
                CouponClaim.fromMap(doc.id, plainData(doc.data())),
            ],
          ),
    );
  }

  @override
  Future<void> adminSetClaimStatus(
    String claimId,
    ClaimStatus status, {
    String byUid = '',
  }) {
    final cancelled = status == ClaimStatus.cancelled;
    return _claims.doc(claimId).update({
      'status': status.name,
      cancelled ? 'cancelledAt' : 'redeemedAt': FieldValue.serverTimestamp(),
      if (!cancelled && byUid.isNotEmpty) 'redeemedBy': byUid,
    });
  }

  // --- Helpers -----------------------------------------------------------------

  /// Commits; returns true when the write is only queued (offline).
  Future<bool> _commit(WriteBatch batch) async {
    try {
      await batch.commit().timeout(_commitTimeout);
      return false;
    } on TimeoutException {
      // Firestore keeps the batch in its offline queue and sends it later.
      return true;
    } catch (error) {
      throw _mapError(error);
    }
  }

  RewardsException _mapError(Object error) {
    if (error is RewardsException) return error;
    if (FirestoreAuthGuard.isPermissionDenied(error)) {
      return RewardsException(RewardsErrorCode.denied, '$error');
    }
    if (error is FirebaseException &&
        (error.code == 'unavailable' || error.code == 'deadline-exceeded')) {
      return RewardsException(RewardsErrorCode.offline, '$error');
    }
    if (error is TimeoutException) {
      return const RewardsException(RewardsErrorCode.offline);
    }
    return RewardsException(RewardsErrorCode.unknown, '$error');
  }
}

class _PayOutcome {
  const _PayOutcome({
    required this.points,
    this.capped = false,
    this.already = false,
    this.pending = false,
    this.xpBefore = 0,
  });

  final int points;
  final bool capped;
  final bool already;
  final bool pending;
  final int xpBefore;
}
