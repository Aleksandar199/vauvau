import '../../../core/l10n/l10n.dart';
import '../../moderation/domain/content_report.dart';
import '../../rewards/domain/rewards_models.dart';
import '../domain/admin_models.dart';

abstract final class AdminStrings {
  static String get panel => L10n.tr('Administracija', 'Administration');
  static String get title => L10n.tr('Administracija', 'Administration');
  static String get denied =>
      L10n.tr('Samo administratori mogu da otvore ovaj panel.', 'Only administrators can open this panel.');
  static String get statsTab => L10n.tr('Početna', 'Home');
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
  static String get statUsers => L10n.tr('Ukupno korisnika', 'Total users');
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

  static String groupCreatedAt(DateTime? value) {
    if (value == null) {
      return L10n.tr('Datum kreiranja nepoznat', 'Creation date unknown');
    }
    return L10n.tr('Kreirano: ${_date(value)}', 'Created: ${_date(value)}');
  }

  static String totalUsers(int count) =>
      L10n.tr('Ukupno registrovanih: $count', 'Total registered: $count');

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
  static String get birthdayTab => L10n.tr('Rođendanski poklon', 'Birthday gift');
  static String get birthdayIntro => L10n.tr(
        'Na rođendan psa (podsetnik „Rođendan“) korisnik dobija čestitku u 09:00. Kad uključiš poklon, čestitka dodaje: „🎁 Čeka te rođendanski poklon od {partner} u Nagradama.“',
        'On the dog\'s birthday (a "Birthday" reminder) the owner gets a greeting at 09:00. With the gift on, it adds: "🎁 A birthday gift from {partner} is waiting in Rewards."',
      );
  static String get birthdayEnabled =>
      L10n.tr('Rođendanski poklon uključen', 'Birthday gift on');
  static String get birthdayCoupon => L10n.tr('Kupon poklona', 'Gift coupon');
  static String get birthdayNoCoupon =>
      L10n.tr('Bez kupona', 'No coupon');
  static String get birthdayPartner =>
      L10n.tr('Ime partnera u čestitki', 'Partner name in the greeting');
  static String get birthdayNeedsCoupon => L10n.tr(
        'Izaberi kupon pre uključivanja poklona.',
        'Pick a coupon before turning the gift on.',
      );
  static String get birthdayPreview => L10n.tr('Pregled čestitke', 'Greeting preview');
  static String get birthdayNote => L10n.tr(
        'Izabrani kupon postaje rođendanski: besplatan (0 poena), ne vidi se u običnoj listi i može da ga preuzme samo vlasnik psa koji ima podsetnik „Rođendan“ – od dana rođendana do 30 dana posle, najviše jednom godišnje. Kupon mora biti i aktivan (tab Kuponi) i u roku važenja. Najava u čestitki važi za podsetnike sačuvane posle izmene.',
        'The chosen coupon becomes the birthday coupon: free (0 points), hidden from the normal list and only for an owner whose dog has a "Birthday" reminder – from the birthday until 30 days after, at most once a year. It must also be active (Coupons tab) and within its dates. The greeting mentions it for reminders saved after the change.',
      );
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
  static String rewardsRemaining(int remaining, int claimed) => L10n.tr(
        'Preostalo: $remaining (preuzeto $claimed)',
        'Remaining: $remaining (claimed $claimed)',
      );
  static String get rewardsChangeRemaining => L10n.tr('Promeni', 'Change');
  static String get rewardsRemainingTitle =>
      L10n.tr('Broj preostalih kupona', 'Coupons remaining');
  static String get rewardsRemainingField =>
      L10n.tr('Preostalo za preuzimanje', 'Still available');
  static String rewardsClaimedSoFar(int n) =>
      L10n.tr('Do sada preuzeto: $n', 'Claimed so far: $n');
  static String get rewardsRemainingHint => L10n.tr(
        'Može da se menja bilo kada. 0 = rasprodato. Već preuzeti kuponi '
            'ostaju važeći.',
        'Can be changed any time. 0 = sold out. Claimed coupons stay valid.',
      );
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

  // --- Imena umesto ID-jeva ---
  static String get unknownUserName =>
      L10n.tr('Nepoznat korisnik', 'Unknown user');
  static String get loadingName => L10n.tr('Učitava se…', 'Loading…');
  static String userName(AdminUserRef? user) {
    if (user == null || !user.exists) return unknownUserName;
    return user.name.isEmpty ? L10n.tr('Korisnik bez imena', 'Unnamed user') : user.name;
  }

  static String get reporterLabel => L10n.tr('Prijavio', 'Reported by');
  static String get reportedUserLabel => L10n.tr('Prijavljen', 'Reported user');
  static String get createdByLabel => L10n.tr('Predložio', 'Suggested by');
  static String get organizerLabel => L10n.tr('Organizator', 'Organizer');
  static String get uploaderLabel => L10n.tr('Objavio', 'Posted by');
  static String get userLabel => L10n.tr('Korisnik', 'User');
  static String get partnerBadge => L10n.tr('PARTNER', 'PARTNER');
  static String get userBadge => L10n.tr('KORISNIK', 'USER');
  static String get suspendedBadge => L10n.tr('SUSPENDOVAN', 'SUSPENDED');

  static String targetKind(ReportContentType type) => switch (type) {
        ReportContentType.user => L10n.tr('Profil korisnika', 'User profile'),
        ReportContentType.moment => L10n.tr('Momenat', 'Moment'),
        ReportContentType.message => L10n.tr('Poruka u četu', 'Chat message'),
        ReportContentType.dog => L10n.tr('Profil psa', 'Dog profile'),
        ReportContentType.poi => L10n.tr('Mesto na mapi', 'Map place'),
        ReportContentType.chat => L10n.tr('Razgovor', 'Conversation'),
      };
  static String get missingDog =>
      L10n.tr('Pas je obrisan ili ne postoji', 'Dog deleted or missing');
  static String get missingMoment =>
      L10n.tr('Momenat je obrisan ili ne postoji', 'Moment deleted or missing');
  static String get missingMessage => L10n.tr(
        'Poruka nije dostupna (obrisana ili stara prijava bez četa)',
        'Message unavailable',
      );
  static String get imageMessage => L10n.tr('📷 Slika', '📷 Photo');
  static String reportSnapshot(String text) =>
      L10n.tr('Tekst u trenutku prijave: „$text“', 'Text when reported: "$text"');

  // --- Akcije moderacije ---
  static String get deleteDog => L10n.tr('Obriši psa', 'Delete dog');
  static String get deleteMessage => L10n.tr('Obriši poruku', 'Delete message');
  static String get deleteMomentShort =>
      L10n.tr('Obriši momenat', 'Delete moment');
  static String get rejectPlace => L10n.tr('Odbij mesto', 'Reject place');
  static String get suspendUser => L10n.tr('Suspenduj korisnika', 'Suspend user');
  static String get unsuspendUser =>
      L10n.tr('Ukini suspenziju', 'Lift suspension');
  static String get openUser => L10n.tr('Otvori korisnika', 'Open user');
  static String get confirmDeleteDog => L10n.tr(
        'Profil psa će biti trajno obrisan za sve korisnike.',
        'The dog profile will be permanently deleted.',
      );
  static String get confirmDeleteMessage => L10n.tr(
        'Poruka će biti trajno obrisana iz razgovora.',
        'The message will be permanently deleted.',
      );
  static String get suspendTitle => L10n.tr('Suspenzija naloga', 'Suspend account');
  static String get suspendBody => L10n.tr(
        'Korisnik neće moći da koristi aplikaciju niti da objavljuje sadržaj '
            'dok ne ukinete suspenziju.',
        'The user cannot use the app or post until you lift it.',
      );
  static String get suspendReason =>
      L10n.tr('Razlog (vidi ga samo admin)', 'Reason (admin only)');
  static String get suspendConfirm => L10n.tr('Suspenduj', 'Suspend');
  static String get suspended => L10n.tr('Korisnik je suspendovan.', 'User suspended.');
  static String get unsuspended =>
      L10n.tr('Suspenzija je ukinuta.', 'Suspension lifted.');
  static String get dogDeleted => L10n.tr('Pas je obrisan.', 'Dog deleted.');
  static String get messageDeleted =>
      L10n.tr('Poruka je obrisana.', 'Message deleted.');

  // --- Početna (statistika) ---
  static String get attention => L10n.tr('Zahteva pažnju', 'Needs attention');
  static String get sectionCommunity => L10n.tr('Zajednica', 'Community');
  static String get sectionActivity => L10n.tr('Aktivnost', 'Activity');
  static String get sectionHelp => L10n.tr('Pomoć psima', 'Help dogs');
  static String get sectionRewards => L10n.tr('Šetnje i nagrade', 'Walks & rewards');
  static String get statNew7 => L10n.tr('Novi (7 dana)', 'New (7 days)');
  static String get statNew30 => L10n.tr('Novi (30 dana)', 'New (30 days)');
  static String get statSuspended => L10n.tr('Suspendovani', 'Suspended');
  static String get statAllDogs => L10n.tr('Psi', 'Dogs');
  static String get statMatches => L10n.tr('Mečevi', 'Matches');
  static String get statChats => L10n.tr('Aktivni četovi (7 d)', 'Active chats (7 d)');
  static String get statStories => L10n.tr('Aktivne priče', 'Active stories');
  static String get statMoments => L10n.tr('Momenti', 'Moments');
  static String get statEvents => L10n.tr('Predstojeći događaji', 'Upcoming events');
  static String get statLost => L10n.tr('Izgubljeni (aktivni)', 'Lost (active)');
  static String get statAdoption => L10n.tr('Za udomljavanje', 'For adoption');
  static String get statWalks => L10n.tr('Nagrađene šetnje', 'Rewarded walks');
  static String get statKm => L10n.tr('Km (nagrađeni)', 'Km (rewarded)');
  static String get statClaimed => L10n.tr('Kuponi neiskorišćeni', 'Coupons unused');
  static String get statRedeemed => L10n.tr('Kuponi iskorišćeni', 'Coupons used');
  static String get statPartners => L10n.tr('Partneri', 'Partners');
  static String get statOpenReports => L10n.tr('Otvorene prijave', 'Open reports');
  static String get statNewFeedback => L10n.tr('Nove poruke', 'New messages');
  static String get statGroupsPending =>
      L10n.tr('Grupe na čekanju', 'Groups pending');
  static String get statUnavailable => L10n.tr(
        '– = podatak trenutno nije dostupan (veza, pravila ili indeks još '
            'nisu objavljeni).',
        '– = not available right now (connection, rules or index).',
      );
  static String get refresh => L10n.tr('Osveži', 'Refresh');
  static String get homeTab => L10n.tr('Početna', 'Home');

  // --- app_config ---
  static String get appConfigTitle =>
      L10n.tr('Verzija aplikacije (Android)', 'App version (Android)');
  static String appConfigSummary(int min, int latest) => L10n.tr(
        'Najnovija: $latest · minimalna (obavezno ažuriranje): $min',
        'Latest: $latest · minimum (forced): $min',
      );
  static String get appConfigMissing => L10n.tr(
        'Nije podešeno – korisnici ne dobijaju poruku za ažuriranje.',
        'Not set – no update prompt.',
      );
  static String get appConfigLatest =>
      L10n.tr('Najnoviji build (poruka „Ažuriraj“)', 'Latest build');
  static String get appConfigMin =>
      L10n.tr('Minimalni build (obavezno)', 'Minimum build (forced)');
  static String get appConfigInvalid => L10n.tr(
        'Minimalni build ne može biti veći od najnovijeg.',
        'Minimum cannot exceed latest.',
      );
  static String get edit2 => L10n.tr('Izmeni', 'Edit');
  static String appConfigThisBuild(int build) => L10n.tr(
        'Ova aplikacija: build $build (iz pubspec.yaml)',
        'This app: build $build (from pubspec.yaml)',
      );
  static String appConfigPublish(int build) => L10n.tr(
        'Objavi build $build kao najnoviji',
        'Publish build $build as latest',
      );
  static String get appConfigPublishHint => L10n.tr(
        'Pritisni tek kad je ova verzija dostupna na Google Play-u – '
            'korisnici starijih verzija će dobiti poruku „Ažuriraj“.',
        'Only once this version is live on Google Play.',
      );

  // --- Korisnici ---
  static String get searchUsers =>
      L10n.tr('Pretraga: ime, email, grad ili ID', 'Search: name, email, city, ID');
  static String get filterAll => L10n.tr('Svi', 'All');
  static String get filterAdmins => L10n.tr('Admini', 'Admins');
  static String get filterPartners => L10n.tr('Partneri', 'Partners');
  static String get filterSuspended => L10n.tr('Suspendovani', 'Suspended');
  static String shownUsers(int shown, int total) =>
      L10n.tr('Prikazano $shown od $total', 'Showing $shown of $total');
  static String get userDetail => L10n.tr('Korisnik', 'User');
  static String get userNotFound =>
      L10n.tr('Korisnik nije pronađen.', 'User not found.');
  static String get copyId => L10n.tr('Kopiraj ID', 'Copy ID');
  static String get idCopied => L10n.tr('ID je kopiran.', 'ID copied.');
  static String get roleSection => L10n.tr('Uloga', 'Role');
  static String get roleUser => L10n.tr('Korisnik', 'User');
  static String get roleAdmin => L10n.tr('Administrator', 'Administrator');
  static String roleCurrentPartner(String name) =>
      L10n.tr('Partner: $name', 'Partner: $name');
  static String get rolePartnerUnknown =>
      L10n.tr('Partner (nepoznat partner)', 'Partner (unknown)');
  static String get makePartner => L10n.tr('Dodeli ulogu partnera', 'Make partner');
  static String get removePartner =>
      L10n.tr('Ukloni ulogu partnera', 'Remove partner role');
  static String get choosePartner => L10n.tr('Izaberi partnera', 'Choose partner');
  static String get noPartners => L10n.tr(
        'Prvo dodajte partnera u Nagrade → Partneri.',
        'Add a partner first in Rewards → Partners.',
      );
  static String get adminRoleNote => L10n.tr(
        'Ulogu administratora menjajte samo u Firebase Console.',
        'Change the admin role only in Firebase Console.',
      );
  static String get roleSaved => L10n.tr('Uloga je sačuvana.', 'Role saved.');
  static String get userDogs => L10n.tr('Psi', 'Dogs');
  static String get noDogs => L10n.tr('Nema pasa.', 'No dogs.');
  static String get reportsAgainst =>
      L10n.tr('Prijave protiv korisnika', 'Reports against user');
  static String get noReportsAgainst =>
      L10n.tr('Nema prijava protiv ovog korisnika.', 'No reports against this user.');
  static String get moderationSection => L10n.tr('Moderacija', 'Moderation');
  static String suspendedSince(String reason) => reason.isEmpty
      ? L10n.tr('Nalog je suspendovan.', 'Account suspended.')
      : L10n.tr('Nalog je suspendovan: $reason', 'Account suspended: $reason');
  static String reportStatus(ReportStatus status) => switch (status) {
        ReportStatus.pending => L10n.tr('Na čekanju', 'Pending'),
        ReportStatus.reviewed => L10n.tr('Rešeno', 'Resolved'),
        ReportStatus.actionTaken => L10n.tr('Uklonjeno', 'Removed'),
        ReportStatus.dismissed => L10n.tr('Odbačeno', 'Dismissed'),
      };

  // --- Sadržaj (oglasi) ---
  static String get contentLost => L10n.tr('Izgubljeni psi', 'Lost dogs');
  static String get contentAdoption => L10n.tr('Udomljavanje', 'Adoption');
  static String get contentEvents => L10n.tr('Događaji', 'Events');
  static String get groupsPendingTab => L10n.tr('Na čekanju', 'Pending');
  static String get groupsAllTab => L10n.tr('Sve grupe', 'All groups');
  static String get groupsTabShort => L10n.tr('Grupe', 'Groups');
  static String get emptyContent => L10n.tr('Nema stavki.', 'No items.');
  static String closeAction(AdminContentKind kind) => switch (kind) {
        AdminContentKind.lostDog => L10n.tr('Označi rešeno', 'Mark resolved'),
        AdminContentKind.adoption => L10n.tr('Označi udomljen', 'Mark adopted'),
        AdminContentKind.group => L10n.tr('Odobri', 'Approve'),
        AdminContentKind.event => '',
      };
  static String contentStatus(String status) => switch (status) {
        'active' => L10n.tr('Aktivan', 'Active'),
        'resolved' => L10n.tr('Rešeno', 'Resolved'),
        'available' => L10n.tr('Dostupan', 'Available'),
        'adopted' => L10n.tr('Udomljen', 'Adopted'),
        'upcoming' => L10n.tr('Predstoji', 'Upcoming'),
        'past' => L10n.tr('Prošao', 'Past'),
        'pending' => L10n.tr('Na čekanju', 'Pending'),
        'approved' => L10n.tr('Odobrena', 'Approved'),
        _ => status,
      };
  static String get confirmDeleteContent => L10n.tr(
        'Stavka će biti trajno obrisana za sve korisnike.',
        'The item will be permanently deleted for everyone.',
      );
  static String get contentDeleted => L10n.tr('Obrisano.', 'Deleted.');
  static String get contentClosed => L10n.tr('Sačuvano.', 'Saved.');

  // --- Partneri ---
  static String get rewardsPartners => L10n.tr('Partneri', 'Partners');
  static String get partnerInactive => L10n.tr('neaktivan', 'inactive');
  static String get newPartner => L10n.tr('Novi partner', 'New partner');
  static String get editPartner => L10n.tr('Izmeni partnera', 'Edit partner');
  static String get partnerName => L10n.tr('Naziv radnje', 'Shop name');
  static String get partnerCity => L10n.tr('Grad', 'City');
  static String get partnerAddress => L10n.tr('Adresa', 'Address');
  static String get noPartnersYet => L10n.tr(
        'Nema partnera. Dodajte radnju koja prihvata VauVau kupone, pa joj u '
            'Korisnici dodelite nalog.',
        'No partners yet.',
      );
  static String partnerAccounts(int n) =>
      L10n.tr('Nalozi: $n', 'Accounts: $n');
  static String get couponPartner =>
      L10n.tr('Partner koji prihvata kupon', 'Partner that accepts the coupon');
  static String get couponNoPartner => L10n.tr(
        'Bez partnera (kupon označava samo admin)',
        'No partner (admin redeems)',
      );
  static String get redeemedByLabel => L10n.tr('Označio', 'Redeemed by');

  static String _date(DateTime value) {
    return '${value.day}.${value.month}.${value.year}.';
  }
}
