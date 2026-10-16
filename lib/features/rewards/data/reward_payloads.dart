import 'package:cloud_firestore/cloud_firestore.dart';

import '../../map/domain/completed_walk.dart';
import '../../map/domain/walk_tracking.dart';
import '../domain/rewards_models.dart';

/// Firestore Timestamps → DateTime so domain models stay Firebase-free.
Map<String, dynamic> plainData(Map<String, dynamic> data) => {
  for (final entry in data.entries)
    entry.key: entry.value is Timestamp
        ? (entry.value as Timestamp).toDate()
        : entry.value,
};

List<CouponClaim> sortClaims(List<CouponClaim> claims) => claims
  ..sort(
    (a, b) => (b.claimedAt ?? DateTime(2000)).compareTo(
      a.claimedAt ?? DateTime(2000),
    ),
  );

/// `users/{uid}/walks/{walkId}` – owner-only; the precise route stays here.
Map<String, Object?> walkPayload(CompletedWalk walk) => {
  'id': walk.id,
  'userId': walk.userId,
  'dogId': walk.dogId,
  'dogName': walk.dogName,
  // Old readers use distanceKm; the rules use recognizedMeters.
  'distanceKm': walk.recognizedMeters / 1000,
  'recognizedMeters': walk.recognizedMeters,
  'excludedMeters': walk.excludedMeters,
  'durationSeconds': walk.durationSeconds,
  'statusMessage': walk.statusMessage,
  'startedAt': Timestamp.fromDate(walk.startedAt),
  'endedAt': Timestamp.fromDate(walk.endedAt),
  // Firestore forbids arrays inside arrays → list of {points: [...]}.
  'route': [
    for (final segment in thinSegments(walk.segments))
      {
        'points': [for (final p in segment) p.toJson()],
      },
  ],
  'flags': {
    'vehicle': walk.vehicleDetected,
    'mock': walk.mockDetected,
    'approximate': walk.approximate,
    'recovered': walk.recovered,
  },
  'acceptedFixes': walk.acceptedFixes,
  'rejectedFixes': walk.rejectedFixes,
  'createdAt': FieldValue.serverTimestamp(),
};

/// Fallback for the old deployed rules (public profile array, no route).
Map<String, Object?> legacyWalkPayload(CompletedWalk walk) => {
  'id': walk.id,
  'userId': walk.userId,
  'dogId': walk.dogId,
  'distanceKm': walk.recognizedMeters / 1000,
  'durationSeconds': walk.durationSeconds,
  'statusMessage': walk.statusMessage,
  'startedAt': Timestamp.fromDate(walk.startedAt),
  'endedAt': Timestamp.fromDate(walk.endedAt),
};

CompletedWalk? completedWalkFromDoc(
  String uid,
  String id,
  Map<String, dynamic> data,
) {
  final started = data['startedAt'];
  final ended = data['endedAt'];
  final meters = data['recognizedMeters'];
  final duration = data['durationSeconds'];
  if (started is! DateTime ||
      ended is! DateTime ||
      meters is! num ||
      duration is! num) {
    return null;
  }
  final flags = data['flags'] is Map ? data['flags'] as Map : const {};
  return CompletedWalk(
    id: id,
    userId: uid,
    dogId: data['dogId'] as String? ?? '',
    startedAt: started,
    endedAt: ended,
    durationSeconds: duration.toInt(),
    recognizedMeters: meters.toInt(),
    mockDetected: flags['mock'] == true,
    vehicleDetected: flags['vehicle'] == true,
  );
}

Map<String, Object?> progressPayload(
  PeriodProgress before,
  int meters,
  int counted,
  int points,
  String entryId,
) => {
  'meters': before.meters + meters,
  'walks': before.walks + counted,
  'walkPoints': before.walkPoints + points,
  'lastEntryId': entryId,
  'updatedAt': FieldValue.serverTimestamp(),
};

String walkReason(int km, int points) => points > 0
    ? 'Šetnja: $km km'
    : (km >= 1
          ? 'Šetnja: $km km (dnevni limit dostignut)'
          : 'Šetnja ispod 1 km');

String challengeReason(Challenge challenge) => 'Izazov: ${challenge.title}';

String couponReason(Coupon coupon) =>
    'Kupon: ${coupon.partnerName} – ${coupon.discountLabel}';

/// Same checks the rules make; throws a typed error before any write.
void checkCouponClaimable(Coupon coupon, RewardSummary summary, DateTime now) {
  switch (coupon.availability(now)) {
    case CouponAvailability.inactive:
      throw const RewardsException(RewardsErrorCode.inactive);
    case CouponAvailability.notStarted:
      throw const RewardsException(RewardsErrorCode.notStarted);
    case CouponAvailability.expired:
      throw const RewardsException(RewardsErrorCode.expired);
    case CouponAvailability.soldOut:
      throw const RewardsException(RewardsErrorCode.soldOut);
    case CouponAvailability.available:
      break;
  }
  if (summary.points < coupon.pointsCost) {
    throw const RewardsException(RewardsErrorCode.insufficientPoints);
  }
}

Map<String, Object?> claimPayload(Coupon coupon, String uid, String code) => {
  'userId': uid,
  'couponId': coupon.id,
  'code': code,
  'status': 'claimed',
  'pointsCost': coupon.pointsCost,
  'partnerName': coupon.partnerName,
  'title': coupon.title,
  'discountLabel': coupon.discountLabel,
  'expiresAt': Timestamp.fromDate(coupon.expiresAt),
  'claimedAt': FieldValue.serverTimestamp(),
};

Map<String, Object?> couponPayload(Coupon coupon) => {
  'partnerName': coupon.partnerName,
  'title': coupon.title,
  'description': coupon.description,
  'discountLabel': coupon.discountLabel,
  'pointsCost': coupon.pointsCost,
  'startsAt': Timestamp.fromDate(coupon.startsAt),
  'expiresAt': Timestamp.fromDate(coupon.expiresAt),
  'maxQuantity': coupon.maxQuantity,
  'terms': coupon.terms,
  'isActive': coupon.isActive,
};
