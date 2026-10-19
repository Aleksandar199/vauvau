import 'dart:math';

import '../../map/domain/completed_walk.dart';
import 'rewards_models.dart';

/// XP / points / challenges / coupons. Firestore implementation writes
/// every balance change together with an immutable ledger entry; the rules
/// recheck the numbers (no Cloud Functions – see CLAUDE.md).
abstract class RewardsRepository {
  Stream<RewardSummary> watchSummary(String uid);

  Stream<RewardProgress> watchProgress(
    String uid, {
    required int dayKey,
    required int weekKey,
  });

  Stream<List<LedgerEntry>> watchLedger(String uid, {int limit = 50});

  Stream<List<Challenge>> watchChallenges({bool activeOnly = true});

  Stream<List<Coupon>> watchCoupons({bool activeOnly = true});

  Stream<List<CouponClaim>> watchClaims(String uid);

  /// Saves the walk (owner-only `users/{uid}/walks`) and, if it qualifies,
  /// pays it once (ledger id `walk_{walkId}`). Safe to call again.
  Future<WalkSaveResult> saveWalk(CompletedWalk walk, {DateTime? now});

  /// Pays recent saved walks that have no ledger entry yet (offline save,
  /// rules deployed later). Returns the new entries.
  Future<List<LedgerEntry>> retryPendingWalks(String uid, {DateTime? now});

  /// Pays every met, unpaid challenge for the periods of [at] and [now].
  Future<List<LedgerEntry>> claimChallenges(
    String uid, {
    DateTime? now,
    DateTime? at,
  });

  /// Atomic: enough points, active, in date range, stock left, once per user.
  Future<CouponClaim> claimCoupon(String uid, String couponId, {DateTime? now});

  // --- Partner shop (rules: role 'partner' + active partners/{partnerId}) ---
  // The user only shows the code; the partner (or admin) marks it used, so a
  // mistaken tap by the user can no longer burn the coupon.

  /// The claim with [code] among [partnerId]'s claims, or null.
  Future<CouponClaim?> findPartnerClaim(String partnerId, String code);

  /// claimed → redeemed (one way), stamped with [byUid] and server time.
  Future<void> partnerRedeem(
    String claimId, {
    required String byUid,
    DateTime? now,
  });

  /// Latest claims of [partnerId] (newest first).
  Stream<List<CouponClaim>> watchPartnerClaims(
    String partnerId, {
    int limit = 50,
  });

  // --- Admin (rules: isAdmin()) ---

  Future<void> saveChallenge(Challenge challenge);

  Future<void> setChallengeActive(String id, bool active);

  /// Empty [Coupon.id] creates a new offer.
  Future<void> saveCoupon(Coupon coupon);

  Future<void> setCouponActive(String id, bool active);

  Stream<List<LedgerEntry>> watchAllLedger({int limit = 100});

  Stream<List<CouponClaim>> watchAllClaims({int limit = 200});

  Future<void> adminSetClaimStatus(
    String claimId,
    ClaimStatus status, {
    String byUid = '',
  });
}

/// Random coupon code, e.g. `VV-7KQ2MZ4P` (no 0/O/1/I). The rules check the
/// format; uniqueness per user and offer comes from the claim document id.
abstract final class CouponCode {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final RegExp pattern = RegExp(r'^VV-[A-HJ-NP-Z2-9]{8}$');

  /// Typed / scanned input → `VV-XXXXXXXX` (upper case, no spaces, prefix
  /// optional). Returns null when it cannot be a coupon code.
  static String? normalize(String input) {
    var raw = input.toUpperCase().replaceAll(RegExp(r'[\s\-–_]'), '');
    if (raw.startsWith('VV')) raw = raw.substring(2);
    final code = 'VV-$raw';
    return pattern.hasMatch(code) ? code : null;
  }

  static String generate([Random? random]) {
    final rng = random ?? Random.secure();
    final buffer = StringBuffer('VV-');
    for (var i = 0; i < 8; i++) {
      buffer.write(_alphabet[rng.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }
}
