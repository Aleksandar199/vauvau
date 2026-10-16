import 'package:flutter/material.dart';

import '../../map/domain/completed_walk.dart';
import 'rewards_models.dart';

/// Every reward number lives here. The ones marked [RULES] are repeated in
/// `firestore.rules` (search "RewardRules") – the rules recompute the reward
/// from the walk record, so change both files together.
abstract final class RewardRules {
  /// [RULES] XP and points per whole recognized km (1st km included).
  static const int xpPerKm = 5;
  static const int pointsPerKm = 5;

  /// A walk counts (and pays) only from 1 whole recognized km.
  static const int minRewardKm = 1;

  /// [RULES] Max XP/points from km per Belgrade day (= 6 km). Raising it
  /// means editing this constant and `30` in `walkEntryOk` in the rules.
  static const int dailyKmPointsCap = 30;

  /// [RULES] Average over the whole walk above this is not walking.
  static const double maxAverageKmh = 7;

  /// [RULES] Longer walks are not rewarded (forgotten running session).
  static const Duration maxWalkDuration = Duration(hours: 4);

  /// [RULES] A walk must be claimed within this time after it ended
  /// (offline queue), challenges for periods inside this window.
  static const Duration claimWindow = Duration(hours: 48);

  /// Recovered walks older than this are dropped as interrupted.
  static const Duration maxRecoveryAge = Duration(hours: 6);

  /// Default bonuses (admin can change per challenge in Firestore).
  static const int dailyChallengeXp = 10;
  static const int dailyChallengePoints = 10;
  static const int weeklyGoalWalks = 3;
  static const int weeklyGoalXp = 20;
  static const int weeklyGoalPoints = 20;

  /// Group walk bonus – NOT active: participation can't be confirmed
  /// reliably without a server (anyone can add themselves to an event).
  static const int groupWalkXp = 15;
  static const int groupWalkPoints = 15;
  static const bool groupWalkRewardsEnabled = false;

  static int wholeKm(int recognizedMeters) => recognizedMeters ~/ 1000;

  /// Points (= XP) for one walk given what was already paid today.
  static int walkReward({
    required int recognizedMeters,
    required int paidTodayPoints,
  }) {
    final km = wholeKm(recognizedMeters);
    if (km < minRewardKm) return 0;
    final raw = km * pointsPerKm;
    final room = dailyKmPointsCap - paidTodayPoints;
    if (room <= 0) return 0;
    return raw < room ? raw : room;
  }

  /// Why a walk can't be rewarded (null = it can, if ≥ 1 km).
  static WalkIneligibleReason? ineligibleReason(CompletedWalk walk) {
    if (walk.userId.isEmpty || walk.userId == 'local-user') {
      return WalkIneligibleReason.notSignedIn;
    }
    if (walk.mockDetected) return WalkIneligibleReason.mockLocation;
    if (walk.durationSeconds > maxWalkDuration.inSeconds) {
      return WalkIneligibleReason.tooLong;
    }
    if (walk.durationSeconds <= 0 ||
        walk.recognizedMeters * 3600 >
            walk.durationSeconds * maxAverageKmh * 1000) {
      return WalkIneligibleReason.tooFastAverage;
    }
    if (wholeKm(walk.recognizedMeters) < minRewardKm) {
      return WalkIneligibleReason.tooShort;
    }
    return null;
  }

  /// Walk gets a ledger entry (may be 0 points) so it counts toward km
  /// challenges; flagged walks get none.
  static bool countsTowardChallenges(CompletedWalk walk) {
    final reason = ineligibleReason(walk);
    return (reason == null || reason == WalkIneligibleReason.tooShort) &&
        walk.recognizedMeters >= 100;
  }

  /// Marker in the partner name of coupon templates; such a coupon can't be
  /// activated until the admin enters the real partner.
  static const String placeholderPartner = 'Partner (upiši naziv)';

  static bool isPlaceholderPartner(String partnerName) =>
      partnerName.trim().isEmpty || partnerName.contains('(upiši naziv)');

  /// Coupon templates an admin adds with one tap: INACTIVE, placeholder
  /// partner, valid 60 days. Prices fit the scoring (≈ 30 points a day max).
  static List<Coupon> defaultCoupons(DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 60, 23, 59);
    Coupon template(
      String id,
      String title,
      String discount,
      int cost,
      int quantity,
    ) => Coupon(
      id: id,
      partnerName: placeholderPartner,
      title: title,
      description:
          'Šablon – pre aktivacije upiši pravog partnera, '
          'uslove i rok.',
      discountLabel: discount,
      pointsCost: cost,
      startsAt: start,
      expiresAt: end,
      maxQuantity: quantity,
      terms: 'Jednokratni kupon, ne kombinuje se sa drugim popustima.',
    );
    return [
      template(
        'default_treat',
        'Poslastica za psa',
        'Besplatna poslastica',
        40,
        50,
      ),
      template('default_10', 'Hrana i oprema', '10% popusta', 60, 50),
      template('default_15', 'Hrana i oprema', '15% popusta', 100, 30),
      template(
        'default_grooming',
        'Šišanje i kupanje',
        '15% na šišanje',
        150,
        20,
      ),
      template(
        'default_20',
        'Oprema (povodac, ogrlica, krevet)',
        '20% popusta na opremu',
        200,
        10,
      ),
    ];
  }

  /// Seeds an admin can add with one tap (ids are stable).
  static const List<Challenge> defaultChallenges = [
    Challenge(
      id: 'daily_2km',
      title: 'Prošetaj najmanje 2 km danas',
      description: 'Skupi 2 priznata kilometra u jednoj ili više šetnji.',
      period: ChallengePeriod.daily,
      metric: ChallengeMetric.distance,
      target: 2,
      rewardXp: dailyChallengeXp,
      rewardPoints: dailyChallengePoints,
      sortOrder: 1,
    ),
    Challenge(
      id: 'weekly_3walks',
      title: 'Ostvari tri šetnje ove nedelje',
      description: 'Tri šetnje od najmanje 1 km od ponedeljka do nedelje.',
      period: ChallengePeriod.weekly,
      metric: ChallengeMetric.walks,
      target: weeklyGoalWalks + 0.0,
      rewardXp: weeklyGoalXp,
      rewardPoints: weeklyGoalPoints,
      sortOrder: 2,
    ),
    Challenge(
      id: 'weekly_8km',
      title: 'Pređi ukupno 8 km ove nedelje',
      description: 'Zbir priznatih kilometara svih šetnji u nedelji.',
      period: ChallengePeriod.weekly,
      metric: ChallengeMetric.distance,
      target: 8,
      rewardXp: weeklyGoalXp,
      rewardPoints: weeklyGoalPoints,
      sortOrder: 3,
    ),
  ];
}

class RewardLevel {
  const RewardLevel({
    required this.index,
    required this.name,
    required this.minXp,
    required this.icon,
  });

  final int index;
  final String name;
  final int minXp;
  final IconData icon;
}

/// Levels from total XP (spending points never lowers a level).
abstract final class LevelRules {
  static const List<RewardLevel> levels = [
    RewardLevel(index: 0, name: 'Šapica', minXp: 0, icon: Icons.pets),
    RewardLevel(index: 1, name: 'Istraživač', minXp: 100, icon: Icons.explore),
    RewardLevel(index: 2, name: 'Avanturista', minXp: 250, icon: Icons.terrain),
    RewardLevel(
      index: 3,
      name: 'VauVau ambasador',
      minXp: 500,
      icon: Icons.military_tech,
    ),
  ];

  static RewardLevel levelFor(int xp) {
    var current = levels.first;
    for (final level in levels) {
      if (xp >= level.minXp) current = level;
    }
    return current;
  }

  static RewardLevel? nextLevel(int xp) {
    final index = levelFor(xp).index;
    return index + 1 < levels.length ? levels[index + 1] : null;
  }

  /// 0..1 inside the current level (1 at the top level).
  static double progress(int xp) {
    final current = levelFor(xp);
    final next = nextLevel(xp);
    if (next == null) return 1;
    return ((xp - current.minXp) / (next.minXp - current.minXp))
        .clamp(0, 1)
        .toDouble();
  }

  static int xpToNext(int xp) {
    final next = nextLevel(xp);
    return next == null ? 0 : next.minXp - xp;
  }

  /// The new level when [after] crosses a threshold, else null.
  static RewardLevel? unlocked(int before, int after) {
    final a = levelFor(before);
    final b = levelFor(after);
    return b.index > a.index ? b : null;
  }
}
