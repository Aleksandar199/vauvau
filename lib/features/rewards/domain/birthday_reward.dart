import 'rewards_models.dart';

/// Future birthday gift from a partner pet shop, configured by the admin in
/// `app_config/birthday` {enabled, couponId, partnerName}. Until a partner
/// exists the document is missing (or `enabled: false`) and the birthday
/// greeting is only a message.
///
/// The coupon itself ([Coupon.isBirthday]) is free and only for the owner of
/// a dog with a birthday in the last 30 days, once per year – checked by the
/// rules (`birthdayMarkerOk` in firestore.rules) and by [BirthdayEligibility].
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

/// One "Rođendan" reminder of my dog: the candidate source of a birthday.
class BirthdayReminderRef {
  const BirthdayReminderRef({
    required this.dogId,
    required this.reminderId,
    required this.date,
    this.dogName = '',
  });

  final String dogId;
  final String reminderId;

  /// Stored reminder date (a yearly reminder moves to next year after the
  /// birthday has passed).
  final DateTime date;
  final String dogName;
}

/// The birthday that currently gives the right to the gift: from the
/// birthday until 30 days after. Mirrors `birthdayMarkerOk` in
/// firestore.rules (the birthday is the reminder date or that date minus
/// 365/366 days; the year is the UTC year of that instant).
class BirthdayEligibility {
  const BirthdayEligibility({
    required this.dogId,
    required this.reminderId,
    required this.birthday,
    this.dogName = '',
  });

  static const Duration window = Duration(days: 30);

  final String dogId;
  final String reminderId;
  final DateTime birthday;
  final String dogName;

  /// Key of the yearly limit (`birthday_claims/{uid}_{year}`).
  int get year => birthday.toUtc().year;

  /// Last moment the gift can be claimed.
  DateTime get deadline => birthday.add(window);

  static String markerId(String uid, int year) => '${uid}_$year';

  /// The most recent birthday with an open window, or null.
  static BirthdayEligibility? find(
    Iterable<BirthdayReminderRef> reminders,
    DateTime now,
  ) {
    BirthdayEligibility? best;
    for (final r in reminders) {
      for (final days in const [0, 365, 366]) {
        final birthday = r.date.subtract(Duration(days: days));
        final open =
            !now.isBefore(birthday) && now.isBefore(birthday.add(window));
        if (!open) continue;
        if (best == null || birthday.isAfter(best.birthday)) {
          best = BirthdayEligibility(
            dogId: r.dogId,
            reminderId: r.reminderId,
            birthday: birthday,
            dogName: r.dogName,
          );
        }
      }
    }
    return best;
  }
}

/// A birthday gift the user can claim right now.
class BirthdayGift {
  const BirthdayGift({required this.coupon, required this.eligibility});

  final Coupon coupon;
  final BirthdayEligibility eligibility;
}
