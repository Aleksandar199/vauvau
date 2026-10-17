import '../../../core/l10n/l10n.dart';
import '../../rewards/domain/rewards_models.dart';

abstract final class AdminStrings {
  static String get panel => L10n.tr('Administracija', 'Administration');
  static String get title => L10n.tr('Administracija', 'Administration');
  static String get denied =>
      L10n.tr('Samo administratori mogu da otvore ovaj panel.', 'Only administrators can open this panel.');
  static String get statsTab => L10n.tr('Statistika', 'Statistics');
  static String get usersTab => L10n.tr('Korisnici', 'Users');
  static String get reportsTab => L10n.tr('Prijave', 'Reports');
  static String get contentTab => L10n.tr('Sadržaj', 'Content');
  static String get pendingTab => L10n.tr('Na čekanju (POIs)', 'Pending (POIs)');
  static String get reportDeleteContent => L10n.tr('Obriši', 'Delete');
  static String get reportMarkReviewed => L10n.tr('Rešeno', 'Resolved');
  static String get reportDismiss => L10n.tr('Odbaci', 'Dismiss');
  static String get reportStatusPending => L10n.tr('Na čekanju', 'Pending');
  static String get reportReason => L10n.tr('Razlog', 'Reason');
  static String get reportReviewed =>
      L10n.tr('Prijava je označena kao rešena.', 'Report marked as resolved.');
  static String get confirmDeleteReported => L10n.tr(
        'Prijavljeni sadržaj će biti uklonjen iz aplikacije.',
        'Reported content will be removed from the app.',
      );
  static String get searchTab => L10n.tr('Pretraga Korisnika & Pasa', 'Search users & dogs');
  static String get approve => L10n.tr('✓ Odobri', '✓ Approve');
  static String get edit => L10n.tr('✏️ Izmeni', '✏️ Edit');
  static String get reject => L10n.tr('🗑️ Odbij', '🗑️ Reject');
  static String get block => L10n.tr('🚫 Blokiraj / Obriši Sadržaj', '🚫 Block / remove content');
  static String get dismiss => L10n.tr('✓ Odbaci Prijavu', '✓ Dismiss report');
  static String get emptyPending => L10n.tr('Nema POI predloga na čekanju.', 'No pending POI suggestions.');
  static String get emptyReports => L10n.tr('Nema aktivnih prijava.', 'No active reports.');
  static String get searchHint => L10n.tr('Pretraži korisnike ili pse...', 'Search users or dogs...');
  static String get noSearch => L10n.tr('Nema rezultata.', 'No results.');
  static String get users => L10n.tr('Korisnici', 'Users');
  static String get dogs => L10n.tr('Psi', 'Dogs');
  static String get saved => L10n.tr('Izmena je sačuvana.', 'Changes saved.');
  static String get approved => L10n.tr('Mesto je odobreno.', 'Place approved.');
  static String get rejected => L10n.tr('Predlog je odbijen.', 'Suggestion rejected.');
  static String get blocked => L10n.tr('Sadržaj je uklonjen.', 'Content removed.');
  static String get dismissed => L10n.tr('Prijava je odbačena.', 'Report dismissed.');
  static String get editTitle => L10n.tr('Izmeni mesto', 'Edit place');
  static String get editAndResolve => L10n.tr('Izmeni i reši', 'Edit and resolve');
  static String get saveAndResolve => L10n.tr('Sačuvaj i označi rešeno', 'Save and mark resolved');
  static String get saveOnly => L10n.tr('Samo sačuvaj izmene', 'Save changes only');
  static String get reportContextTitle => L10n.tr('Šta je prijavljeno', 'What was reported');
  static String get name => L10n.tr('Naziv', 'Name');
  static String get address => L10n.tr('Adresa', 'Address');
  static String get openingHours => L10n.tr('Radno vreme', 'Opening hours');
  static String get openingHoursHint =>
      L10n.tr('Npr. Pon–Pet 09–20, Sub 10–14', 'E.g. Mon–Fri 09–20, Sat 10–14');
  static String get pricePerNight => L10n.tr('Cena po noći (RSD)', 'Price per night (RSD)');
  static String get pricePerNightHint =>
      L10n.tr('Ostavi prazno ako nema', 'Leave empty if none');
  static String get phone => L10n.tr('Telefon', 'Phone');
  static String get website => L10n.tr('Website', 'Website');
  static String get latitude => L10n.tr('Geografska širina', 'Latitude');
  static String get longitude => L10n.tr('Geografska dužina', 'Longitude');
  static String get verificationStatus => L10n.tr('Status provere', 'Verification status');
  static String get statusVerified => L10n.tr('✓ Potvrđeno', '✓ Verified');
  static String get statusPending => L10n.tr('Na čekanju', 'Pending');
  static String get statusSubmitted => L10n.tr('Predloženo', 'Submitted');
  static String get statusReported => L10n.tr('Prijavljeno', 'Reported');
  static String get statusRejected => L10n.tr('Odbijeno', 'Rejected');
  static String get statusUnknown => L10n.tr('Nije provereno', 'Not verified');
  static String get flag24h => L10n.tr('Dostupno 00–24h', 'Open 24/7');
  static String get flagEmergency => L10n.tr('Dežurna služba', 'Emergency service');
  static String get flagOvernight => L10n.tr('Prenoćište', 'Overnight stay');
  static String get flagDayCare => L10n.tr('Dnevni boravak', 'Day care');
  static String get flagYard => L10n.tr('Dvorište', 'Yard');
  static String get flagPetFriendly => L10n.tr('Pet-friendly', 'Pet-friendly');
  static String get flagDogPark =>
      L10n.tr('Zvanični park za pse', 'Official dog park');
  static String get invalidCoords => L10n.tr('Unesite ispravne koordinate.', 'Enter valid coordinates.');
  static String get invalidPrice =>
      L10n.tr('Unesite ispravnu cenu ili ostavite prazno.', 'Enter a valid price or leave empty.');
  static String get poiNotFound => L10n.tr(
        'Mesto nije pronađeno. Proverite ID ili dodajte ga kao novi POI.',
        'Place not found. Check the ID or add it as a new POI.',
      );
  static String get poiUpdatedAndResolved => L10n.tr(
        'Mesto je izmenjeno i prijava je rešena.',
        'Place updated and report resolved.',
      );

  static String get drawerItem => L10n.tr('Admin Panel', 'Admin Panel');
  static String get feedbackTab => L10n.tr('📩 Poruke & Feedback', '📩 Messages & feedback');
  static String get momentsTab => L10n.tr('📸 Moderacija Momenata', '📸 Moment moderation');
  static String get emptyFeedback => L10n.tr('Nema poruka od korisnika.', 'No user messages.');
  static String get emptyMoments => L10n.tr('Nema objavljenih momenata.', 'No published moments.');
  static String get emptyUsers => L10n.tr('Nema registrovanih korisnika.', 'No registered users.');
  static String get resolve => L10n.tr('✓ Označi kao rešeno', '✓ Mark resolved');
  static String get resolved => L10n.tr('Rešeno', 'Resolved');
  static String get isNew => L10n.tr('Novo', 'New');
  static String get delete => L10n.tr('🗑️ Obriši', '🗑️ Delete');
  static String get deleteMoment => L10n.tr('🗑️ Obriši momenat', '🗑️ Delete moment');
  static String get feedbackResolved =>
      L10n.tr('Poruka je označena kao rešena.', 'Message marked as resolved.');
  static String get feedbackDeleted => L10n.tr('Poruka je obrisana.', 'Message deleted.');
  static String get momentDeleted => L10n.tr('Momenat je obrisan.', 'Moment deleted.');
  static String get actionFailed =>
      L10n.tr('Radnja nije uspela. Pokušajte ponovo.', 'Action failed. Try again.');
  static String get confirmDeleteTitle => L10n.tr('Obrisati?', 'Delete?');
  static String get confirmDeleteFeedback => L10n.tr(
        'Poruka će biti trajno obrisana iz baze.',
        'The message will be permanently deleted.',
      );
  static String get confirmDeleteMoment => L10n.tr(
        'Momenat će biti trajno obrisan za sve korisnike.',
        'The moment will be permanently deleted for all users.',
      );
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get confirm => L10n.tr('Obriši', 'Delete');
  static String get loadError => L10n.tr('Podaci nisu dostupni.', 'Data unavailable.');
  static String get noEmail => L10n.tr('Bez email adrese', 'No email address');
  static String get adminBadge => L10n.tr('ADMIN', 'ADMIN');
  static String get statUsers => L10n.tr('Korisnici', 'Users');
  static String get statDogs => L10n.tr('Aktivni psi', 'Active dogs');
  static String get statReports => L10n.tr('Prijave', 'Reports');
  static String get statPending => L10n.tr('POI na čekanju', 'POIs pending');
  static String get contentMoments => L10n.tr('Momenti', 'Moments');
  static String get contentPending => L10n.tr('Predlozi mesta', 'Place suggestions');
  static String get groupsTab => L10n.tr('Grupe na čekanju', 'Groups pending');
  static String get emptyPendingGroups =>
      L10n.tr('Nema grupa koje čekaju na odobrenje', 'No groups awaiting approval');
  static String get groupApproved => L10n.tr('Grupa je odobrena.', 'Group approved.');
  static String get groupDeleted => L10n.tr('Grupa je obrisana.', 'Group deleted.');
  static String get approveGroup => L10n.tr('✓ Odobri', '✓ Approve');
  static String get rejectGroup => L10n.tr('✗ Odbij', '✗ Reject');

  static String groupCreatedBy(String userId) {
    final who = userId.isEmpty ? unknownUser : userId;
    return L10n.tr('Predložio: $who', 'Suggested by: $who');
  }

  static String groupCreatedAt(DateTime? value) {
    if (value == null) {
      return L10n.tr('Datum kreiranja nepoznat', 'Creation date unknown');
    }
    return L10n.tr('Kreirano: ${_date(value)}', 'Created: ${_date(value)}');
  }

  static String totalUsers(int count) =>
      L10n.tr('Ukupno registrovanih: $count', 'Total registered: $count');

  static String reportedBy(String userId) {
    final who = userId.isEmpty ? unknownUser : userId;
    return L10n.tr('Prijavio: $who', 'Reported by: $who');
  }

  static String reportedUser(String userId) {
    final who = userId.isEmpty ? unknownUser : userId;
    return L10n.tr('Prijavljen: $who', 'Reported user: $who');
  }

  static String get unknownUser => L10n.tr('nepoznat korisnik', 'unknown user');

  static String joinedOn(DateTime? value) {
    if (value == null) {
      return L10n.tr('Datum pristupanja nepoznat', 'Join date unknown');
    }
    return L10n.tr('Pridružen/a ${_date(value)}', 'Joined ${_date(value)}');
  }

  static String timestamp(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return L10n.tr(
      '${_date(value)} u $hour:$minute',
      '${_date(value)} at $hour:$minute',
    );
  }

  // --- Nagrade (izazovi, kuponi, evidencija) ---
  static String get rewardsTab => L10n.tr('Nagrade', 'Rewards');
  static String get rewardsChallenges => L10n.tr('Izazovi', 'Challenges');
  static String get rewardsCoupons => L10n.tr('Kuponi', 'Coupons');
  static String get rewardsLedger => L10n.tr('Evidencija poena', 'Points log');
  static String get rewardsClaims => L10n.tr('Preuzeti kuponi', 'Claimed coupons');
  static String get save => L10n.tr('Sačuvaj', 'Save');
  static String get rewardsSaved => L10n.tr('Sačuvano.', 'Saved.');
  static String get rewardsSaveFailed =>
      L10n.tr('Čuvanje nije uspelo', 'Save failed');
  static String get rewardsNewChallenge => L10n.tr('Novi izazov', 'New challenge');
  static String get rewardsEditChallenge =>
      L10n.tr('Izmeni izazov', 'Edit challenge');
  static String get rewardsSeedChallenges => L10n.tr(
        'Dodaj podrazumevane izazove (neaktivne)',
        'Add default challenges (inactive)',
      );
  static String get rewardsNoChallenges =>
      L10n.tr('Nema izazova.', 'No challenges.');
  static String get rewardsDaily => L10n.tr('Dnevni', 'Daily');
  static String get rewardsWeekly => L10n.tr('Nedeljni', 'Weekly');
  static String get rewardsWalksUnit => L10n.tr('šetnje', 'walks');
  static String get rewardsTitleField => L10n.tr('Naziv', 'Title');
  static String get rewardsDescriptionField => L10n.tr('Opis', 'Description');
  static String get rewardsPeriod => L10n.tr('Period', 'Period');
  static String get rewardsMetric => L10n.tr('Cilj', 'Goal');
  static String get rewardsMetricKm => L10n.tr('Kilometri', 'Kilometres');
  static String get rewardsMetricWalks =>
      L10n.tr('Broj šetnji (≥ 1 km)', 'Walks (≥ 1 km)');
  static String get rewardsTarget => L10n.tr('Ciljna vrednost', 'Target');
  static String get rewardsPointsField => L10n.tr('Poeni', 'Points');
  static String get rewardsSort => L10n.tr('Redosled', 'Order');
  static String get rewardsActive => L10n.tr('Aktivno', 'Active');
  static String get rewardsRequired => L10n.tr('Obavezno polje', 'Required');
  static String get rewardsNumber => L10n.tr('Unesite broj', 'Enter a number');
  static String rewardsRange(int max) =>
      L10n.tr('Dozvoljeno: 1–$max', 'Allowed: 1–$max');
  static String get rewardsNewCoupon => L10n.tr('Novi kupon', 'New coupon');
  static String get rewardsSeedCoupons => L10n.tr(
        'Dodaj predefinisane kupone (neaktivne šablone)',
        'Add predefined coupons (inactive templates)',
      );
  static String get rewardsTemplatesExist => L10n.tr(
        'Svi predefinisani kuponi su već dodati.',
        'All predefined coupons are already added.',
      );
  static String get rewardsNeedPartner => L10n.tr(
        'Pre aktivacije upiši naziv pravog partnera (pet shop-a).',
        'Enter the real partner (pet shop) before activating.',
      );
  static String get rewardsEditCoupon => L10n.tr('Izmeni kupon', 'Edit coupon');
  static String get rewardsNoCoupons => L10n.tr(
        'Nema kupona. Unesite samo stvarne, dogovorene partnerske ponude.',
        'No coupons. Enter only real, agreed partner offers.',
      );
  static String get rewardsPartner => L10n.tr('Partner (pet shop)', 'Partner');
  static String get rewardsDiscount =>
      L10n.tr('Popust (npr. 15% popusta)', 'Discount (e.g. 15% off)');
  static String get rewardsCost => L10n.tr('Cena u poenima', 'Price in points');
  static String get rewardsQuantity =>
      L10n.tr('Maksimalna količina', 'Max quantity');
  static String rewardsBelowClaimed(int n) => L10n.tr(
        'Već je preuzeto $n – količina ne može biti manja.',
        '$n already claimed – cannot be lower.',
      );
  static String get rewardsTerms => L10n.tr('Uslovi', 'Terms');
  static String get rewardsStart => L10n.tr('Početak', 'Start');
  static String get rewardsEnd => L10n.tr('Istek', 'Expiry');
  static String get rewardsDates =>
      L10n.tr('Istek mora biti posle početka.', 'Expiry must be after start.');
  static String get rewardsNoLedger =>
      L10n.tr('Još nema dodeljenih poena.', 'No points awarded yet.');
  static String get rewardsSearchCode =>
      L10n.tr('Pretraga po kodu (VV-…)', 'Search by code (VV-…)');
  static String get rewardsNoClaims =>
      L10n.tr('Još nema preuzetih kupona.', 'No claimed coupons yet.');
  static String get rewardsNoMatch =>
      L10n.tr('Nema kupona za ovaj filter.', 'No coupons for this filter.');
  static String get rewardsFilterActive =>
      L10n.tr('Neiskorišćeni', 'Unused');
  static String get rewardsFilterAll => L10n.tr('Svi', 'All');
  static String get rewardsMarkRedeemed =>
      L10n.tr('Označi kao iskorišćen', 'Mark as used');
  static String get rewardsCancelClaim => L10n.tr('Otkaži kupon', 'Cancel');
  static String rewardsClaimUser(String name) =>
      L10n.tr('Korisnik: $name', 'User: $name');
  static String rewardsClaimDates(String claimed, String expires) => L10n.tr(
        'Preuzet: $claimed · važi do: $expires',
        'Claimed: $claimed · valid until: $expires',
      );
  static String rewardsRedeemedAt(String at) =>
      L10n.tr('Iskorišćen: $at', 'Used: $at');
  static String rewardsConfirmRedeem(CouponClaim c) => L10n.tr(
        'Kupon ${c.code} (${c.partnerName}, ${c.discountLabel}) označiti kao '
            'iskorišćen? Korisnik ga više neće moći da koristi. Ovo ne može da '
            'se poništi.',
        'Mark coupon ${c.code} as used? This cannot be undone.',
      );
  static String rewardsConfirmCancel(CouponClaim c) => L10n.tr(
        'Otkazati kupon ${c.code}? Poeni se NE vraćaju korisniku.',
        'Cancel coupon ${c.code}? Points are NOT refunded.',
      );

  static String _date(DateTime value) {
    return '${value.day}.${value.month}.${value.year}.';
  }
}
