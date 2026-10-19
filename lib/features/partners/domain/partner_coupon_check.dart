import '../../rewards/domain/rewards_models.dart';
import '../../rewards/domain/rewards_repository.dart';

enum PartnerCheckStatus {
  /// Not a `VV-XXXXXXXX` code.
  invalidFormat,

  /// No such code among this partner's claims (wrong code or another shop's).
  notFound,
  valid,
  alreadyRedeemed,
  expired,
  cancelled,
}

class PartnerCheckResult {
  const PartnerCheckResult(this.status, {this.code = '', this.claim});

  final PartnerCheckStatus status;
  final String code;
  final CouponClaim? claim;

  bool get canRedeem => status == PartnerCheckStatus.valid && claim != null;
}

/// What the shop sees after typing a code. Partners can only read their own
/// claims (rules), so "another shop's code" looks the same as "unknown code".
Future<PartnerCheckResult> checkPartnerCoupon({
  required RewardsRepository repository,
  required String partnerId,
  required String input,
  required DateTime now,
}) async {
  final code = CouponCode.normalize(input);
  if (code == null) {
    return const PartnerCheckResult(PartnerCheckStatus.invalidFormat);
  }
  final claim = await repository.findPartnerClaim(partnerId, code);
  if (claim == null || claim.partnerId != partnerId) {
    return PartnerCheckResult(PartnerCheckStatus.notFound, code: code);
  }
  final status = switch (claim.effectiveStatus(now)) {
    ClaimStatus.claimed => PartnerCheckStatus.valid,
    ClaimStatus.redeemed => PartnerCheckStatus.alreadyRedeemed,
    ClaimStatus.expired => PartnerCheckStatus.expired,
    ClaimStatus.cancelled => PartnerCheckStatus.cancelled,
  };
  return PartnerCheckResult(status, code: code, claim: claim);
}
