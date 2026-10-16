import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/belgrade_calendar.dart';
import '../domain/reward_rules.dart';
import '../domain/rewards_models.dart';

abstract final class RewardsStrings {
  static String get hubTitle =>
      L10n.tr('Dnevni VauVau izazov', 'Daily VauVau challenge');
  static String get tabChallenges => L10n.tr('Izazovi', 'Challenges');
  static String get tabHistory => L10n.tr('Istorija', 'History');
  static String get tabRewards => L10n.tr('Nagrade', 'Rewards');
  static String get entrySubtitle => L10n.tr(
    'Šetaj, skupljaj XP i poene za kupone',
    'Walk, earn XP and points for coupons',
  );
  static String get dailySection =>
      L10n.tr('Dnevni izazovi', 'Daily challenges');
  static String get weeklySection =>
      L10n.tr('Nedeljni izazovi', 'Weekly challenges');
  static String get noChallenges => L10n.tr(
    'Trenutno nema aktivnih izazova.',
    'No active challenges right now.',
  );
  static String get noChallengesBody => L10n.tr(
    'Izazove dodaje VauVau tim. Šetnje se i dalje boduju po kilometru.',
    'Challenges are added by the VauVau team. Walks still earn per km.',
  );
  static String get loadError =>
      L10n.tr('Podaci se trenutno ne mogu učitati.', 'Could not load data.');
  static String get retry => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get completed => L10n.tr('Završeno ✓', 'Completed ✓');
  static String get inProgress => L10n.tr('U toku', 'In progress');
  static String dailyReset(DateTime at) => L10n.tr(
    'Dnevni izazovi se resetuju u ponoć (Beograd) – još ${_left(at)}.',
    'Daily challenges reset at midnight (Belgrade) – ${_left(at)} left.',
  );
  static String weeklyReset(DateTime at) => L10n.tr(
    'Nedeljni izazovi traju od ponedeljka do nedelje – još ${_left(at)}.',
    'Weekly challenges run Monday to Sunday – ${_left(at)} left.',
  );

  static String _left(DateTime at) {
    final d = at.difference(DateTime.now());
    if (d.inHours >= 24) return '${d.inDays} d ${d.inHours % 24} h';
    if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes % 60} min';
    return '${d.inMinutes.clamp(0, 59)} min';
  }

  static String levelLabel(RewardLevel level) =>
      L10n.tr('Nivo: ${level.name}', 'Level: ${level.name}');
  static String xpTotal(int xp) => '$xp XP';
  static String xpToNext(int xp, RewardLevel next) =>
      L10n.tr('Još $xp XP do nivoa ${next.name}', '$xp XP to ${next.name}');
  static String get topLevel =>
      L10n.tr('Najviši nivo – bravo!', 'Top level – well done!');
  static String points(int p) => L10n.tr('$p poena', '$p points');
  static String get pointsBalance =>
      L10n.tr('Poeni za nagrade', 'Reward points');
  static String get xpExplain => L10n.tr(
    'XP određuje nivo i ne troši se. Poeni se troše na kupone.',
    'XP sets your level and is never spent. Points buy coupons.',
  );
  static String reward(int xp, int points) =>
      '+$xp XP · +$points ${L10n.tr('poena', 'pts')}';
  static String progressKm(double current, double target) =>
      '${current.toStringAsFixed(1)} / ${target.toStringAsFixed(target % 1 == 0 ? 0 : 1)} km';
  static String progressWalks(int current, int target) =>
      L10n.tr('$current / $target šetnje', '$current / $target walks');

  static String get howItWorks =>
      L10n.tr('Kako se boduje', 'How scoring works');
  static List<String> get rulesLines => [
    L10n.tr(
      'Priznata šetnja od 1 km: +${RewardRules.xpPerKm} XP i '
          '+${RewardRules.pointsPerKm} poena, svaki sledeći ceo km isto toliko.',
      'Recognized 1 km walk: +${RewardRules.xpPerKm} XP and '
          '+${RewardRules.pointsPerKm} points, same for each further whole km.',
    ),
    L10n.tr(
      'Dnevni limit za kilometre: ${RewardRules.dailyKmPointsCap} XP / '
          '${RewardRules.dailyKmPointsCap} poena (oko '
          '${RewardRules.dailyKmPointsCap ~/ RewardRules.pointsPerKm} km).',
      'Daily km limit: ${RewardRules.dailyKmPointsCap} XP / '
          '${RewardRules.dailyKmPointsCap} points.',
    ),
    L10n.tr(
      'Računaju se samo celi kilometri koje GPS prizna kao hod; vožnja, '
          'skokovi signala i lažna lokacija se ne računaju.',
      'Only whole km recognized as walking count; driving, signal jumps '
          'and fake location do not.',
    ),
    L10n.tr(
      'Izazov se nagrađuje jednom po danu odnosno nedelji.',
      'A challenge pays once per day or week.',
    ),
    L10n.tr(
      'Prekinuta ili nezavršena šetnja ne donosi poene.',
      'Interrupted or unfinished walks earn nothing.',
    ),
    L10n.tr(
      'Grupne šetnje se još ne boduju (učešće ne može pouzdano da se potvrdi).',
      'Group walks are not scored yet (attendance cannot be verified).',
    ),
  ];

  // History
  static String get walksSection =>
      L10n.tr('Šetnje (7 dana)', 'Walks (7 days)');
  static String get ledgerSection =>
      L10n.tr('Evidencija XP i poena', 'XP and points log');
  static String get noWalks => L10n.tr(
    'Još nema šetnji. Započnite šetnju na mapi.',
    'No walks yet. Start one on the map.',
  );
  static String get noLedger =>
      L10n.tr('Još nema dodeljenih poena.', 'No points awarded yet.');
  static String ledgerAmount(LedgerEntry e) {
    final parts = <String>[
      if (e.xp != 0) '${e.xp > 0 ? '+' : ''}${e.xp} XP',
      if (e.points != 0)
        '${e.points > 0 ? '+' : ''}${e.points} ${L10n.tr('p', 'pts')}',
    ];
    return parts.isEmpty ? '0' : parts.join(' · ');
  }

  // Rewards / coupons
  static String get couponsSection =>
      L10n.tr('Kuponi partnera', 'Partner coupons');
  static String get myCoupons => L10n.tr('Moji kuponi', 'My coupons');
  static String get noCoupons =>
      L10n.tr('Trenutno nema aktivnih kupona.', 'No active coupons right now.');
  static String get noCouponsBody => L10n.tr(
    'Ponude partnerskih pet shop-ova unosi VauVau tim. Skupljajte poene!',
    'Partner pet shop offers are added by the VauVau team.',
  );
  static String get noMyCoupons =>
      L10n.tr('Još niste preuzeli kupon.', 'No coupons claimed yet.');
  static String cost(int p) => L10n.tr('$p poena', '$p points');
  static String validUntil(DateTime d) =>
      L10n.tr('Važi do ${_date(d)}', 'Valid until ${_date(d)}');
  static String startsOn(DateTime d) =>
      L10n.tr('Počinje ${_date(d)}', 'Starts ${_date(d)}');
  static String remaining(int n) => L10n.tr('Preostalo: $n', 'Left: $n');
  static String get claim => L10n.tr('Preuzmi', 'Claim');
  static String claimConfirmTitle(Coupon c) =>
      L10n.tr('Preuzeti kupon?', 'Claim coupon?');
  static String claimConfirmBody(Coupon c) => L10n.tr(
    '${c.partnerName}: ${c.discountLabel}. Biće oduzeto ${c.pointsCost} '
        'poena. Kupon se preuzima jednom.',
    '${c.partnerName}: ${c.discountLabel}. ${c.pointsCost} points will be '
        'spent. One per person.',
  );
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String claimed(String code) =>
      L10n.tr('Kupon preuzet: $code', 'Coupon claimed: $code');
  static String get showAtShop => L10n.tr(
    'Pokažite kod na kasi partnera. Posle kupovine označite ga kao iskorišćen.',
    'Show the code at the partner shop, then mark it used.',
  );
  static String get markUsed =>
      L10n.tr('Označi kao iskorišćen', 'Mark as used');
  static String get markUsedConfirm => L10n.tr(
    'Označiti kupon kao iskorišćen? Ovo ne može da se poništi.',
    'Mark the coupon as used? This cannot be undone.',
  );
  static String get terms => L10n.tr('Uslovi', 'Terms');
  static String availability(CouponAvailability a) => switch (a) {
    CouponAvailability.available => L10n.tr('Dostupno', 'Available'),
    CouponAvailability.notStarted => L10n.tr('Uskoro', 'Soon'),
    CouponAvailability.expired => L10n.tr('Isteklo', 'Expired'),
    CouponAvailability.soldOut => L10n.tr('Rasprodato', 'Sold out'),
    CouponAvailability.inactive => L10n.tr('Neaktivno', 'Inactive'),
  };
  static String claimStatus(ClaimStatus s) => switch (s) {
    ClaimStatus.claimed => L10n.tr('Preuzet', 'Claimed'),
    ClaimStatus.redeemed => L10n.tr('Iskorišćen', 'Used'),
    ClaimStatus.expired => L10n.tr('Istekao', 'Expired'),
    ClaimStatus.cancelled => L10n.tr('Otkazan', 'Cancelled'),
  };
  static String error(RewardsErrorCode code) => switch (code) {
    RewardsErrorCode.insufficientPoints => L10n.tr(
      'Nemate dovoljno poena.',
      'Not enough points.',
    ),
    RewardsErrorCode.soldOut => L10n.tr(
      'Kuponi su rasprodati.',
      'Coupons are sold out.',
    ),
    RewardsErrorCode.expired => L10n.tr(
      'Ponuda je istekla.',
      'The offer has expired.',
    ),
    RewardsErrorCode.notStarted => L10n.tr(
      'Ponuda još nije počela.',
      'The offer has not started.',
    ),
    RewardsErrorCode.inactive => L10n.tr(
      'Ponuda nije aktivna.',
      'The offer is not active.',
    ),
    RewardsErrorCode.alreadyClaimed => L10n.tr(
      'Ovaj kupon ste već preuzeli.',
      'Already claimed.',
    ),
    RewardsErrorCode.denied => L10n.tr(
      'Zahtev je odbijen. Nagrade možda još nisu aktivirane na serveru.',
      'Request refused. Rewards may not be enabled on the server yet.',
    ),
    RewardsErrorCode.offline => L10n.tr(
      'Nema interneta – pokušajte kad se povežete.',
      'No internet – try again when online.',
    ),
    RewardsErrorCode.signedOut => L10n.tr(
      'Prijavite se da biste skupljali poene.',
      'Sign in first.',
    ),
    RewardsErrorCode.unknown => L10n.tr(
      'Nešto nije u redu. Pokušajte ponovo.',
      'Something went wrong.',
    ),
  };

  // Walk result
  static String get walkResultTitle =>
      L10n.tr('Šetnja završena', 'Walk finished');
  static String recognized(double km) => L10n.tr(
    'Priznato: ${km.toStringAsFixed(2)} km',
    'Recognized: ${km.toStringAsFixed(2)} km',
  );
  static String get cappedNote => L10n.tr(
    'Dostignut je dnevni limit poena za kilometre.',
    'Daily km points limit reached.',
  );
  static String get alreadyRewarded => L10n.tr(
    'Ova šetnja je već nagrađena.',
    'This walk was already rewarded.',
  );
  static String get pendingSync => L10n.tr(
    'Šetnja je sačuvana bez interneta. Nagrada će biti obračunata kad se '
        'povežete (najkasnije 48 h posle šetnje).',
    'Saved offline. The reward is calculated when you are back online '
        '(within 48 h).',
  );
  static String get rewardDenied => L10n.tr(
    'Šetnja je sačuvana, ali server još ne prihvata nagrade.',
    'Walk saved, but the server does not accept rewards yet.',
  );
  static String ineligible(WalkIneligibleReason r) => switch (r) {
    WalkIneligibleReason.notSignedIn => L10n.tr(
      'Prijavite se da biste dobijali poene.',
      'Sign in to earn points.',
    ),
    WalkIneligibleReason.tooShort => L10n.tr(
      'Poeni se dobijaju od 1 priznatog km.',
      'Points start at 1 recognized km.',
    ),
    WalkIneligibleReason.tooLong => L10n.tr(
      'Šetnja duža od 4 h se ne boduje.',
      'Walks longer than 4 h are not scored.',
    ),
    WalkIneligibleReason.mockLocation => L10n.tr(
      'Otkrivena je lažna lokacija – šetnja se ne boduje.',
      'Fake location detected – walk not scored.',
    ),
    WalkIneligibleReason.tooFastAverage => L10n.tr(
      'Prosečna brzina nije brzina hoda – šetnja se ne boduje.',
      'Average speed is not walking speed – walk not scored.',
    ),
    WalkIneligibleReason.recoveredWithoutTracking => L10n.tr(
      'Šetnja je prekinuta i ne boduje se.',
      'Walk was interrupted and is not scored.',
    ),
  };
  static String challengeDone(String title) =>
      L10n.tr('Izazov završen: $title', 'Challenge done: $title');
  static String get levelUpTitle =>
      L10n.tr('Novi nivo otključan! 🎉', 'New level unlocked! 🎉');
  static String levelUpBody(RewardLevel level) => L10n.tr(
    'Sada ste ${level.name}. Samo nastavite sa šetnjama!',
    'You are now ${level.name}. Keep walking!',
  );
  static String get ok => L10n.tr('Super', 'Great');
  static String synced(int n) => L10n.tr(
    'Obračunate su nagrade na čekanju ($n).',
    'Pending rewards credited ($n).',
  );

  static String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.day}.${l.month}.${l.year}.';
  }

  static String dayKeyLabel(int key) => BelgradeCalendar.formatDayKey(key);
}

/// Cream / brown / amber look of the challenge screens (dark mode falls
/// back to the theme surfaces with amber accents).
class RewardsPalette {
  const RewardsPalette._({
    required this.background,
    required this.card,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentSoft,
  });

  final Color background;
  final Color card;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentSoft;

  static RewardsPalette of(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return RewardsPalette._(
        background: theme.scaffoldBackgroundColor,
        card: theme.colorScheme.surfaceContainerHighest,
        text: theme.colorScheme.onSurface,
        muted: theme.colorScheme.onSurfaceVariant,
        accent: const Color(0xFFF59E0B),
        accentSoft: const Color(0x33F59E0B),
      );
    }
    return const RewardsPalette._(
      background: Color(0xFFFFF8F0),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF4E342E),
      muted: Color(0xFF8D6E63),
      accent: Color(0xFFD97706),
      accentSoft: Color(0xFFFEF3C7),
    );
  }
}
