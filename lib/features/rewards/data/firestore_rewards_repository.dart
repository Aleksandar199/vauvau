import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../map/domain/completed_walk.dart';
import '../domain/birthday_reward.dart';
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
  FirestoreRewardsRepository(
    this._db, {
    Duration? commitTimeout,
    Duration? resultWait,
  }) : _commitTimeout = commitTimeout ?? const Duration(seconds: 12),
       _resultWait = resultWait ?? defaultResultWait;

  final FirebaseFirestore _db;
  final Duration _commitTimeout;
  final Duration _resultWait;

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
  //
  // The app only SAVES the walk. The rewardWalk Cloud Function
  // (functions/rewards.js) re-checks the route, pays XP / points / challenge
  // bonuses and writes the outcome to users/{uid}/reward_results/{walkId};
  // the rules forbid clients from writing balances.

  /// How long "Završi šetnju" waits for the server's verdict before it says
  /// the reward will follow (slow network, function cold start).
  static const Duration defaultResultWait = Duration(seconds: 25);

  @override
  Future<WalkSaveResult> saveWalk(CompletedWalk walk, {DateTime? now}) async {
    final reason = RewardRules.ineligibleReason(walk);
    final walkRef = _walks(walk.userId).doc(walk.id);
    final saved = await _saveWalkOnly(walkRef, walk, walkPayload(walk));
    if (!saved.saved) {
      return WalkSaveResult(saved: false, ineligibleReason: reason);
    }
    // Flagged / too short / web: nothing to wait for (the server also
    // rejects flagged walks, but the app already knows why).
    if (!RewardRules.countsTowardChallenges(walk)) {
      return WalkSaveResult(
        saved: true,
        pendingSync: saved.pending,
        ineligibleReason: reason,
      );
    }
    if (saved.pending) {
      return WalkSaveResult(saved: true, pendingSync: true);
    }
    try {
      final data = await _awaitResult(walk.userId, walk.id);
      return walkResultFromServer(data);
    } on TimeoutException {
      return const WalkSaveResult(saved: true, pendingSync: true);
    } catch (error) {
      debugPrint('Walk result not read: $error');
      return const WalkSaveResult(saved: true, pendingSync: true);
    }
  }

  Future<Map<String, dynamic>> _awaitResult(String uid, String walkId) async {
    final ref = _user(uid).collection('reward_results').doc(walkId);
    final snap = await ref
        .snapshots()
        .firstWhere((snapshot) => snapshot.exists)
        .timeout(_resultWait);
    return plainData(snap.data()!);
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
      debugPrint('Walk save failed: $error');
      return (saved: false, pending: false);
    }
  }

  // The server pays everything; nothing to retry or claim from the app.

  @override
  Future<List<LedgerEntry>> retryPendingWalks(
    String uid, {
    DateTime? now,
  }) async => const [];

  @override
  Future<List<LedgerEntry>> claimChallenges(
    String uid, {
    DateTime? now,
    DateTime? at,
  }) async => const [];

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
            // The birthday gift goes only through claimBirthdayCoupon.
            if (coupon.isBirthday) {
              throw const RewardsException(RewardsErrorCode.inactive);
            }
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

  DocumentReference<Map<String, dynamic>> _birthdayMarker(
    String uid,
    int year,
  ) => _db
      .collection('birthday_claims')
      .doc(BirthdayEligibility.markerId(uid, year));

  @override
  Future<bool> hasBirthdayClaim(String uid, int year) async {
    try {
      return (await _birthdayMarker(uid, year).get()).exists;
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CouponClaim> claimBirthdayCoupon(
    String uid,
    String couponId,
    BirthdayEligibility eligibility, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    if (at.isBefore(eligibility.birthday) ||
        !at.isBefore(eligibility.deadline)) {
      throw const RewardsException(RewardsErrorCode.expired);
    }
    final year = eligibility.year;
    final couponRef = _coupons.doc(couponId);
    final claimRef = _claims.doc(CouponClaim.birthdayDocId(couponId, uid, year));
    final markerRef = _birthdayMarker(uid, year);
    final entryId = LedgerEntry.birthdayCouponEntryId(couponId, year);
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
            if (!coupon.isBirthday || coupon.pointsCost != 0) {
              throw const RewardsException(RewardsErrorCode.inactive);
            }
            if ((await tx.get(markerRef)).exists ||
                (await tx.get(claimRef)).exists) {
              throw const RewardsException(RewardsErrorCode.alreadyClaimed);
            }
            final summary = RewardSummary.fromMap(
              (await tx.get(_summary(uid))).data(),
            );
            checkCouponClaimable(coupon, summary, at);

            final code = CouponCode.generate();
            tx
              ..set(claimRef, {
                ...claimPayload(coupon, uid, code),
                'birthdayYear': year,
              })
              ..update(couponRef, {'claimedCount': coupon.claimedCount + 1})
              ..set(ledgerRef, {
                'type': 'coupon',
                'couponId': couponId,
                'birthdayYear': year,
                'xp': 0,
                'points': 0,
                'reason': couponReason(coupon),
                'createdAt': FieldValue.serverTimestamp(),
              })
              ..set(_summary(uid), {
                'xp': summary.xp,
                'points': summary.points,
                'lastEntryId': entryId,
                'updatedAt': FieldValue.serverTimestamp(),
              })
              ..set(markerRef, {
                'userId': uid,
                'couponId': couponId,
                'dogId': eligibility.dogId,
                'reminderId': eligibility.reminderId,
                // Exact instant: the rules compare it with the reminder date.
                'birthday': Timestamp.fromDate(eligibility.birthday),
                'birthdayYear': year,
                'createdAt': FieldValue.serverTimestamp(),
              });
            return CouponClaim(
              id: claimRef.id,
              couponId: couponId,
              userId: uid,
              code: code,
              status: ClaimStatus.claimed,
              pointsCost: 0,
              claimedAt: at,
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
  Future<void> setBirthdayCoupon(String id, {required bool birthday}) =>
      _coupons.doc(id).update({
        'isBirthday': birthday,
        // A birthday gift is free (the rules require 0 points).
        if (birthday) 'pointsCost': 0,
      });

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
