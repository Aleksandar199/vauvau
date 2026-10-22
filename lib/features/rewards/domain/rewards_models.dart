/// Data types of the "Dnevni VauVau izazov" feature (XP, poeni, izazovi,
/// kuponi). Firestore field names are documented on each `fromMap`.
library;

DateTime? _date(Object? raw) {
  // The data layer converts Firestore Timestamps to DateTime first.
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

int _int(Object? raw) => raw is num ? raw.toInt() : 0;

String _str(Object? raw) => raw is String ? raw : '';

/// `users/{uid}/rewards/summary` – XP never goes down, points are spent.
class RewardSummary {
  const RewardSummary({this.xp = 0, this.points = 0});

  factory RewardSummary.fromMap(Map<String, dynamic>? data) =>
      RewardSummary(xp: _int(data?['xp']), points: _int(data?['points']));

  static const empty = RewardSummary();

  final int xp;
  final int points;

  @override
  bool operator ==(Object other) =>
      other is RewardSummary && other.xp == xp && other.points == points;

  @override
  int get hashCode => Object.hash(xp, points);
}

/// Day (`rewards/d{dayKey}`) and week (`rewards/w{weekKey}`) progress built
/// only from rewarded walk entries.
class PeriodProgress {
  const PeriodProgress({this.meters = 0, this.walks = 0, this.walkPoints = 0});

  factory PeriodProgress.fromMap(Map<String, dynamic>? data) => PeriodProgress(
    meters: _int(data?['meters']),
    walks: _int(data?['walks']),
    walkPoints: _int(data?['walkPoints']),
  );

  static const empty = PeriodProgress();

  /// Recognized walking meters.
  final int meters;

  /// Walks of at least 1 recognized km.
  final int walks;

  /// Points from km already paid this period (daily cap).
  final int walkPoints;

  double get km => meters / 1000;
}

class RewardProgress {
  const RewardProgress({
    required this.dayKey,
    required this.weekKey,
    this.day = PeriodProgress.empty,
    this.week = PeriodProgress.empty,
  });

  final int dayKey;
  final int weekKey;
  final PeriodProgress day;
  final PeriodProgress week;
}

enum LedgerType { walk, challenge, coupon, other }

/// `users/{uid}/reward_ledger/{entryId}` – one immutable line per balance
/// change. The id is deterministic, so a repeated request cannot pay twice:
/// `walk_{walkId}`, `ch_{challengeId}_{periodKey}`, `coupon_{couponId}`.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.xp,
    required this.points,
    required this.reason,
    this.createdAt,
    this.walkId = '',
    this.challengeId = '',
    this.couponId = '',
    this.periodKey = 0,
    this.km = 0,
    this.userId = '',
  });

  factory LedgerEntry.fromMap(
    String id,
    Map<String, dynamic> data, {
    String userId = '',
  }) {
    return LedgerEntry(
      id: id,
      type: switch (data['type']) {
        'walk' => LedgerType.walk,
        'challenge' => LedgerType.challenge,
        'coupon' => LedgerType.coupon,
        _ => LedgerType.other,
      },
      xp: _int(data['xp']),
      points: _int(data['points']),
      reason: _str(data['reason']),
      createdAt: _date(data['createdAt']),
      walkId: _str(data['walkId']),
      challengeId: _str(data['challengeId']),
      couponId: _str(data['couponId']),
      periodKey: _int(data['periodKey'] ?? data['dayKey']),
      km: _int(data['km']),
      userId: userId,
    );
  }

  final String id;
  final LedgerType type;
  final int xp;
  final int points;
  final String reason;
  final DateTime? createdAt;
  final String walkId;
  final String challengeId;
  final String couponId;
  final int periodKey;
  final int km;

  /// Set when read through the admin collection-group query.
  final String userId;

  static String walkEntryId(String walkId) => 'walk_$walkId';

  static String challengeEntryId(String challengeId, int periodKey) =>
      'ch_${challengeId}_$periodKey';

  static String couponEntryId(String couponId) => 'coupon_$couponId';

  static String birthdayCouponEntryId(String couponId, int year) =>
      'coupon_${couponId}_$year';
}

enum ChallengePeriod { daily, weekly }

enum ChallengeMetric { distance, walks }

/// `reward_challenges/{id}` – created and activated by an admin only.
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.period,
    required this.metric,
    required this.target,
    required this.rewardXp,
    required this.rewardPoints,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Challenge.fromMap(String id, Map<String, dynamic> data) => Challenge(
    id: id,
    title: _str(data['title']),
    description: _str(data['description']),
    period: data['period'] == 'weekly'
        ? ChallengePeriod.weekly
        : ChallengePeriod.daily,
    metric: data['metric'] == 'walks'
        ? ChallengeMetric.walks
        : ChallengeMetric.distance,
    target: data['target'] is num ? (data['target'] as num).toDouble() : 0,
    rewardXp: _int(data['rewardXp']),
    rewardPoints: _int(data['rewardPoints']),
    isActive: data['isActive'] == true,
    sortOrder: _int(data['sortOrder']),
  );

  final String id;
  final String title;
  final String description;
  final ChallengePeriod period;
  final ChallengeMetric metric;

  /// km for [ChallengeMetric.distance], walk count for [ChallengeMetric.walks].
  final double target;
  final int rewardXp;
  final int rewardPoints;
  final bool isActive;
  final int sortOrder;

  Map<String, Object?> toMap() => {
    'title': title,
    'description': description,
    'period': period.name,
    'metric': metric.name,
    'target': target,
    'rewardXp': rewardXp,
    'rewardPoints': rewardPoints,
    'isActive': isActive,
    'sortOrder': sortOrder,
  };

  int periodKey(RewardProgress progress) =>
      period == ChallengePeriod.daily ? progress.dayKey : progress.weekKey;

  /// Current value toward [target] (km or walks).
  double currentValue(RewardProgress progress) {
    final p = period == ChallengePeriod.daily ? progress.day : progress.week;
    return metric == ChallengeMetric.distance ? p.km : p.walks.toDouble();
  }

  /// Same comparison the rules make (meters vs target × 1000).
  bool isMet(RewardProgress progress) {
    final p = period == ChallengePeriod.daily ? progress.day : progress.week;
    return metric == ChallengeMetric.distance
        ? p.meters >= target * 1000
        : p.walks >= target;
  }

  double fraction(RewardProgress progress) {
    if (target <= 0) return 1;
    return (currentValue(progress) / target).clamp(0, 1).toDouble();
  }

  Challenge copyWith({bool? isActive}) => Challenge(
    id: id,
    title: title,
    description: description,
    period: period,
    metric: metric,
    target: target,
    rewardXp: rewardXp,
    rewardPoints: rewardPoints,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder,
  );
}

enum CouponAvailability { available, notStarted, expired, soldOut, inactive }

/// `reward_coupons/{id}` – partner offer entered by an admin.
class Coupon {
  const Coupon({
    required this.id,
    required this.partnerName,
    required this.title,
    required this.description,
    required this.discountLabel,
    required this.pointsCost,
    required this.startsAt,
    required this.expiresAt,
    required this.maxQuantity,
    this.claimedCount = 0,
    this.terms = '',
    this.isActive = false,
    this.partnerId = '',
    this.isBirthday = false,
  });

  factory Coupon.fromMap(String id, Map<String, dynamic> data) => Coupon(
    id: id,
    partnerName: _str(data['partnerName']),
    title: _str(data['title']),
    description: _str(data['description']),
    discountLabel: _str(data['discountLabel']),
    pointsCost: _int(data['pointsCost']),
    startsAt: _date(data['startsAt']) ?? DateTime(2000),
    expiresAt: _date(data['expiresAt']) ?? DateTime(2000),
    maxQuantity: _int(data['maxQuantity']),
    claimedCount: _int(data['claimedCount']),
    terms: _str(data['terms']),
    isActive: data['isActive'] == true,
    partnerId: _str(data['partnerId']),
    isBirthday: data['isBirthday'] == true,
  );

  final String id;
  final String partnerName;
  final String title;
  final String description;

  /// e.g. "15% popusta".
  final String discountLabel;
  final int pointsCost;
  final DateTime startsAt;
  final DateTime expiresAt;
  final int maxQuantity;
  final int claimedCount;
  final String terms;
  final bool isActive;

  /// `partners/{id}`; that partner's shop accounts see and redeem its claims.
  final String partnerId;

  /// Birthday gift (admin, Nagrade → Rođendanski poklon): free, only for an
  /// owner whose dog has a birthday in the last 30 days, once a year; not in
  /// the normal coupon list.
  final bool isBirthday;

  int get remaining => (maxQuantity - claimedCount).clamp(0, maxQuantity);

  CouponAvailability availability(DateTime now) {
    if (!isActive) return CouponAvailability.inactive;
    if (now.isBefore(startsAt)) return CouponAvailability.notStarted;
    if (!now.isBefore(expiresAt)) return CouponAvailability.expired;
    if (claimedCount >= maxQuantity) return CouponAvailability.soldOut;
    return CouponAvailability.available;
  }
}

enum ClaimStatus { claimed, redeemed, expired, cancelled }

/// `coupon_claims/{couponId}_{uid}` – a user's coupon with its unique code.
/// One per user per offer; never deleted by the user.
class CouponClaim {
  const CouponClaim({
    required this.id,
    required this.couponId,
    required this.userId,
    required this.code,
    required this.status,
    required this.pointsCost,
    this.claimedAt,
    this.redeemedAt,
    this.expiresAt,
    this.partnerName = '',
    this.title = '',
    this.discountLabel = '',
    this.partnerId = '',
    this.redeemedBy = '',
  });

  factory CouponClaim.fromMap(String id, Map<String, dynamic> data) =>
      CouponClaim(
        id: id,
        couponId: _str(data['couponId']),
        userId: _str(data['userId']),
        code: _str(data['code']),
        status: switch (data['status']) {
          'redeemed' => ClaimStatus.redeemed,
          'cancelled' => ClaimStatus.cancelled,
          _ => ClaimStatus.claimed,
        },
        pointsCost: _int(data['pointsCost']),
        claimedAt: _date(data['claimedAt']),
        redeemedAt: _date(data['redeemedAt']),
        expiresAt: _date(data['expiresAt']),
        partnerName: _str(data['partnerName']),
        title: _str(data['title']),
        discountLabel: _str(data['discountLabel']),
        partnerId: _str(data['partnerId']),
        redeemedBy: _str(data['redeemedBy']),
      );

  final String id;
  final String couponId;
  final String userId;
  final String code;

  /// Stored status (claimed / redeemed / cancelled).
  final ClaimStatus status;
  final int pointsCost;
  final DateTime? claimedAt;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;
  final String partnerName;
  final String title;
  final String discountLabel;

  /// Copied from the coupon at claim time (the rules check it).
  final String partnerId;

  /// uid of the partner / admin account that marked it used.
  final String redeemedBy;

  static String docId(String couponId, String uid) => '${couponId}_$uid';

  /// Birthday gift claim: one per user per birthday year.
  static String birthdayDocId(String couponId, String uid, int year) =>
      '${couponId}_${uid}_$year';

  /// Adds "expired" for unused coupons past their end date.
  ClaimStatus effectiveStatus(DateTime now) {
    final end = expiresAt;
    if (status == ClaimStatus.claimed && end != null && !now.isBefore(end)) {
      return ClaimStatus.expired;
    }
    return status;
  }
}

enum RewardsErrorCode {
  insufficientPoints,
  soldOut,
  expired,
  notStarted,
  inactive,
  alreadyClaimed,

  /// Firestore rules rejected the write (new rules not deployed yet, or the
  /// client sent something the rules do not allow).
  denied,
  offline,
  signedOut,
  unknown,
}

class RewardsException implements Exception {
  const RewardsException(this.code, [this.detail = '']);

  final RewardsErrorCode code;
  final String detail;

  @override
  String toString() =>
      'RewardsException(${code.name}${detail.isEmpty ? '' : ': $detail'})';
}

/// Result of saving a finished walk.
class WalkSaveResult {
  const WalkSaveResult({
    required this.saved,
    this.xp = 0,
    this.points = 0,
    this.capped = false,
    this.eligible = false,
    this.ineligibleReason,
    this.alreadyRewarded = false,
    this.pendingSync = false,
    this.rewardDenied = false,
    this.challengeEntries = const [],
    this.xpBefore = 0,
    this.xpAfter = 0,
  });

  final bool saved;
  final int xp;
  final int points;

  /// Daily km cap cut the reward.
  final bool capped;
  final bool eligible;
  final WalkIneligibleReason? ineligibleReason;
  final bool alreadyRewarded;

  /// Written to the offline queue; the server confirms later.
  final bool pendingSync;

  /// Rules refused the reward (e.g. new rules not deployed).
  final bool rewardDenied;
  final List<LedgerEntry> challengeEntries;
  final int xpBefore;
  final int xpAfter;

  int get totalXp =>
      xp + challengeEntries.fold(0, (sum, entry) => sum + entry.xp);

  int get totalPoints =>
      points + challengeEntries.fold(0, (sum, entry) => sum + entry.points);
}

enum WalkIneligibleReason {
  notSignedIn,
  tooShort,
  tooLong,
  mockLocation,
  tooFastAverage,
  recoveredWithoutTracking,
}
