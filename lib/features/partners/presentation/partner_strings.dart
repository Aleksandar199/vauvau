import '../../../core/l10n/l10n.dart';
import '../../rewards/domain/rewards_models.dart';
import '../domain/partner_coupon_check.dart';

abstract final class PartnerStrings {
  static String get drawerItem => L10n.tr('Kuponi partnera', 'Partner coupons');
  static String get title => L10n.tr('Kuponi', 'Coupons');
  static String get profileTileSubtitle => L10n.tr(
        'Proveri i označi kupone kupaca',
        'Check and redeem customer coupons',
      );
  static String get denied => L10n.tr(
        'Ovaj ekran je samo za naloge partnera.',
        'This screen is for partner accounts only.',
      );
  static String get inactivePartner => L10n.tr(
        'Partner je deaktiviran – kuponi trenutno ne mogu da se označe. '
            'Javite se administratoru.',
        'This partner is deactivated – coupons cannot be redeemed now.',
      );
  static String get codeLabel => L10n.tr('Kod kupona', 'Coupon code');
  static String get codeHint => 'VV-XXXXXXXX';
  static String get check => L10n.tr('Proveri kod', 'Check code');
  static String get paste => L10n.tr('Nalepi', 'Paste');
  static String get scanTodo => L10n.tr(
        'Unesite kod koji kupac pokazuje u aplikaciji (velika/mala slova i '
            'razmaci nisu bitni).',
        'Type the code the customer shows in the app.',
      );
  static String get redeem => L10n.tr('Označi kao iskorišćen', 'Mark as used');
  static String redeemConfirm(String code) => L10n.tr(
        'Kupon $code označiti kao iskorišćen? Kupac ga posle toga ne može '
            'ponovo koristiti. Ovo ne može da se poništi.',
        'Mark coupon $code as used? This cannot be undone.',
      );
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get redeemed =>
      L10n.tr('Kupon je označen kao iskorišćen.', 'Coupon marked as used.');
  static String get redeemFailed => L10n.tr(
        'Kupon nije označen. Proverite vezu i pokušajte ponovo.',
        'Could not mark the coupon. Try again.',
      );
  static String get checkFailed => L10n.tr(
        'Provera nije uspela. Proverite vezu i pokušajte ponovo.',
        'Check failed. Try again.',
      );
  static String get recent => L10n.tr('Poslednji kuponi', 'Recent coupons');
  static String get noRecent =>
      L10n.tr('Još nema preuzetih kupona.', 'No claimed coupons yet.');
  static String get offers => L10n.tr('Vaše ponude', 'Your offers');
  static String get noOffers => L10n.tr(
        'Administrator još nije dodao ponude za vašu radnju.',
        'No offers for your shop yet.',
      );

  static String result(PartnerCheckStatus status) => switch (status) {
        PartnerCheckStatus.invalidFormat => L10n.tr(
            'Neispravan kod. Kod izgleda ovako: VV-7KQ2MZ4P.',
            'Invalid code. Format: VV-7KQ2MZ4P.',
          ),
        PartnerCheckStatus.notFound => L10n.tr(
            'Kod nije pronađen među kuponima vaše radnje.',
            'Code not found among your shop\'s coupons.',
          ),
        PartnerCheckStatus.valid =>
          L10n.tr('Kupon je važeći.', 'The coupon is valid.'),
        PartnerCheckStatus.alreadyRedeemed => L10n.tr(
            'Kupon je već iskorišćen.',
            'This coupon has already been used.',
          ),
        PartnerCheckStatus.expired =>
          L10n.tr('Kupon je istekao.', 'This coupon has expired.'),
        PartnerCheckStatus.cancelled =>
          L10n.tr('Kupon je otkazan.', 'This coupon was cancelled.'),
      };

  static String status(ClaimStatus status) => switch (status) {
        ClaimStatus.claimed => L10n.tr('Važeći', 'Valid'),
        ClaimStatus.redeemed => L10n.tr('Iskorišćen', 'Used'),
        ClaimStatus.expired => L10n.tr('Istekao', 'Expired'),
        ClaimStatus.cancelled => L10n.tr('Otkazan', 'Cancelled'),
      };

  static String validUntil(String date) =>
      L10n.tr('Važi do: $date', 'Valid until: $date');
  static String redeemedAt(String date) =>
      L10n.tr('Iskorišćen: $date', 'Used: $date');
}
