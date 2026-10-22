/// Future birthday gift from a partner pet shop, configured by the admin in
/// `app_config/birthday` {enabled, couponId, partnerName}. Until a partner
/// exists the document is missing (or `enabled: false`) and the birthday
/// greeting is only a message.
///
/// Not done yet (needs a partner + approval): giving the coupon itself.
/// Today a claim costs points (`coupon_claims` rules), so a free birthday
/// coupon needs either a 0-point coupon limited to the birthday week or a
/// Cloud Function that issues the claim on the birthday.
class BirthdayRewardConfig {
  const BirthdayRewardConfig({
    this.enabled = false,
    this.couponId = '',
    this.partnerName = '',
  });

  static const String docPath = 'app_config/birthday';
  static const BirthdayRewardConfig disabled = BirthdayRewardConfig();

  final bool enabled;
  final String couponId;
  final String partnerName;

  /// A gift is announced only when it is switched on AND points to a coupon.
  bool get isActive => enabled && couponId.trim().isNotEmpty;

  Map<String, Object> toMap() => {
    'enabled': enabled,
    'couponId': couponId.trim(),
    'partnerName': partnerName.trim(),
  };

  factory BirthdayRewardConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return disabled;
    }
    String text(Object? value) => value is String ? value.trim() : '';
    return BirthdayRewardConfig(
      enabled: data['enabled'] == true,
      couponId: text(data['couponId']),
      partnerName: text(data['partnerName']),
    );
  }
}
