import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../map/data/walk_history_repository.dart';
import '../../map/domain/completed_walk.dart';
import '../../map/presentation/walk_history_controller.dart';
import '../data/firestore_rewards_repository.dart';
import '../data/local_rewards_repository.dart';
import '../domain/belgrade_calendar.dart';
import '../domain/rewards_models.dart';
import '../domain/rewards_repository.dart';

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreRewardsRepository(FirebaseFirestore.instance);
  }
  final history = ref.watch(walkHistoryRepositoryProvider);
  final repo = LocalRewardsRepository(
    walkHistory: history is LocalWalkHistoryRepository ? history : null,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Injectable clock (tests).
final rewardsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final rewardsUidProvider = Provider<String>((ref) {
  return ref.watch(
    authStateProvider.select((auth) => auth.asData?.value?.uid ?? ''),
  );
});

typedef PeriodKeys = ({int day, int week});

/// Current Belgrade day/week. Switches by itself at Belgrade midnight (a
/// timer), not when the app happens to be opened.
class PeriodKeysController extends Notifier<PeriodKeys> {
  Timer? _timer;

  @override
  PeriodKeys build() {
    ref.onDispose(() => _timer?.cancel());
    final now = ref.watch(rewardsClockProvider)();
    _schedule(now);
    return _keys(now);
  }

  PeriodKeys _keys(DateTime now) =>
      (day: BelgradeCalendar.dayKey(now), week: BelgradeCalendar.weekKey(now));

  void _schedule(DateTime now) {
    _timer?.cancel();
    final wait =
        BelgradeCalendar.nextMidnight(now).difference(now) +
        const Duration(seconds: 1);
    _timer = Timer(wait, () {
      final next = ref.read(rewardsClockProvider)();
      state = _keys(next);
      _schedule(next);
    });
  }
}

final periodKeysProvider = NotifierProvider<PeriodKeysController, PeriodKeys>(
  PeriodKeysController.new,
);

final rewardSummaryProvider = StreamProvider.autoDispose<RewardSummary>((ref) {
  final uid = ref.watch(rewardsUidProvider);
  if (uid.isEmpty) return Stream.value(RewardSummary.empty);
  return ref.watch(rewardsRepositoryProvider).watchSummary(uid);
});

final rewardProgressProvider = StreamProvider.autoDispose<RewardProgress>((
  ref,
) {
  final uid = ref.watch(rewardsUidProvider);
  final keys = ref.watch(periodKeysProvider);
  if (uid.isEmpty) {
    return Stream.value(RewardProgress(dayKey: keys.day, weekKey: keys.week));
  }
  return ref
      .watch(rewardsRepositoryProvider)
      .watchProgress(uid, dayKey: keys.day, weekKey: keys.week);
});

final rewardLedgerProvider = StreamProvider.autoDispose<List<LedgerEntry>>((
  ref,
) {
  final uid = ref.watch(rewardsUidProvider);
  if (uid.isEmpty) return Stream.value(const []);
  return ref.watch(rewardsRepositoryProvider).watchLedger(uid);
});

final activeChallengesProvider = StreamProvider.autoDispose<List<Challenge>>((
  ref,
) {
  return ref.watch(rewardsRepositoryProvider).watchChallenges();
});

final activeCouponsProvider = StreamProvider.autoDispose<List<Coupon>>((ref) {
  return ref.watch(rewardsRepositoryProvider).watchCoupons();
});

final myCouponClaimsProvider = StreamProvider.autoDispose<List<CouponClaim>>((
  ref,
) {
  final uid = ref.watch(rewardsUidProvider);
  if (uid.isEmpty) return Stream.value(const []);
  return ref.watch(rewardsRepositoryProvider).watchClaims(uid);
});

/// Saves finished walks and pays walk + challenge rewards.
class WalkRewardsService {
  WalkRewardsService(this._ref);

  final Ref _ref;

  RewardsRepository get _repo => _ref.read(rewardsRepositoryProvider);

  Future<WalkSaveResult> saveCompletedWalk(CompletedWalk walk) async {
    final now = _ref.read(rewardsClockProvider)();
    WalkSaveResult result;
    try {
      result = await _repo.saveWalk(walk, now: now);
    } catch (error) {
      debugPrint('saveCompletedWalk failed: $error');
      return const WalkSaveResult(saved: false);
    }
    _ref.invalidate(walkHistoryProvider);
    if (!result.saved || result.pendingSync || walk.userId.isEmpty) {
      return result;
    }
    final challenges = await _repo.claimChallenges(
      walk.userId,
      now: now,
      at: walk.endedAt,
    );
    if (challenges.isEmpty) return result;
    final extraXp = challenges.fold(0, (total, e) => total + e.xp);
    return WalkSaveResult(
      saved: result.saved,
      xp: result.xp,
      points: result.points,
      capped: result.capped,
      eligible: result.eligible,
      ineligibleReason: result.ineligibleReason,
      alreadyRewarded: result.alreadyRewarded,
      challengeEntries: challenges,
      xpBefore: result.xpBefore,
      xpAfter: result.xpAfter + extraXp,
    );
  }

  /// Hub opened: pay offline-saved walks and met challenges.
  Future<List<LedgerEntry>> syncPending() async {
    final uid = _ref.read(rewardsUidProvider);
    if (uid.isEmpty) return const [];
    final now = _ref.read(rewardsClockProvider)();
    final walks = await _repo.retryPendingWalks(uid, now: now);
    final challenges = await _repo.claimChallenges(
      uid,
      now: now,
      at: now.subtract(const Duration(days: 1)),
    );
    return [...walks, ...challenges];
  }

  Future<CouponClaim> claimCoupon(String couponId) {
    final uid = _ref.read(rewardsUidProvider);
    if (uid.isEmpty) {
      throw const RewardsException(RewardsErrorCode.signedOut);
    }
    return _repo.claimCoupon(
      uid,
      couponId,
      now: _ref.read(rewardsClockProvider)(),
    );
  }
}

final walkRewardsServiceProvider = Provider<WalkRewardsService>(
  WalkRewardsService.new,
);
