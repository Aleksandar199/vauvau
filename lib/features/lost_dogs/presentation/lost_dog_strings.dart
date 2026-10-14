import '../../../core/l10n/l10n.dart';

abstract final class LostDogStrings {
  static String get title => L10n.tr('Izgubljeni i pronađeni', 'Lost & found');
  static String get drawerItem => L10n.tr('🚨 Izgubljeni psi', '🚨 Lost dogs');
  static String get banner =>
      L10n.tr('🚨 Pomozi u potrazi za nestalim ljubimcima!', '🚨 Help find missing pets!');
  static String get foundBanner => L10n.tr(
        '🟢 Javi vlasniku ako si našao psa ili vidi ko je prijavio pronalazak.',
        '🟢 Tell the owner if you found a dog or see who reported a find.',
      );
  static String get addCta => L10n.tr('+ Prijavi slučaj', '+ Report a case');
  static String get chooseTitle => L10n.tr('Šta želiš da prijaviš?', 'What do you want to report?');
  static String get reportLost =>
      L10n.tr('🚨 Prijavi nestanak mog psa', '🚨 Report my dog missing');
  static String get reportFound =>
      L10n.tr('🟢 Našao sam tuđeg psa', '🟢 I found someone\'s dog');
  static String get addTitle => L10n.tr('Prijava nestanka', 'Missing report');
  static String get addFoundTitle => L10n.tr('Prijava pronađenog psa', 'Found dog report');
  static String get empty =>
      L10n.tr('Trenutno nema aktivnih prijava nestanka.', 'No active missing reports right now.');
  static String get emptyFound =>
      L10n.tr('Trenutno nema prijava pronađenih pasa.', 'No found-dog reports right now.');
  static String get emptyAll => L10n.tr('Još nema aktivnih prijava.', 'No active reports yet.');
  static String get emptySubtitle => L10n.tr(
        'Prijavite nestanak ili pronalazak da pomognete lokalnoj zajednici.',
        'Report a loss or find to help the local community.',
      );
  static String get loadError =>
      L10n.tr('Došlo je do greške. Pokušajte ponovo.', 'Something went wrong. Try again.');
  static String get retry => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get tabLost => L10n.tr('🚨 Izgubljeni', '🚨 Lost');
  static String get tabFound => L10n.tr('🟢 Pronađeni', '🟢 Found');
  static String get tabAll => L10n.tr('Svi', 'All');
  static String get dogName => L10n.tr('Ime psa', 'Dog name');
  static String get dogNameOptional => L10n.tr('Ime psa (ako znaš)', 'Dog name (if known)');
  static String get unknownName => L10n.tr('Nepoznat pas', 'Unknown dog');
  static String get dogNameRequired => L10n.tr('Unesite ime psa.', 'Enter dog name.');
  static String get breed => L10n.tr('Rasa', 'Breed');
  static String get breedRequired => L10n.tr('Izaberite rasu.', 'Select breed.');
  static String get customNeighborhood =>
      L10n.tr('Upiši kvart / naselje', 'Enter neighborhood');
  static String get customNeighborhoodHint =>
      L10n.tr('npr. Blok 45, Mirijevo 2...', 'e.g. Blok 45, Mirijevo 2...');
  static String get customNeighborhoodRequired =>
      L10n.tr('Unesite kvart.', 'Enter a neighborhood.');
  static String get breedOther => L10n.tr('Drugo', 'Other');
  static String get breedUnknown => L10n.tr('Nije sigurno', 'Not sure');
  static String get breedHint => L10n.tr('npr. Zlatni retriver', 'e.g. Golden retriever');
  static String get description => L10n.tr('Opis', 'Description');
  static String get descriptionHint => L10n.tr(
        'Boja, ogrlica, ponašanje, gde je poslednji put viđen...',
        'Color, collar, behavior, last seen...',
      );
  static String get foundDescriptionHint => L10n.tr(
        'Boja, ogrlica, gde je pronađen, kako se ponaša...',
        'Color, collar, where found, behavior...',
      );
  static String get descriptionRequired => L10n.tr('Unesite opis.', 'Enter description.');
  static String get phone => L10n.tr('Kontakt telefon', 'Contact phone');
  static String get phoneRequired => L10n.tr('Unesite kontakt telefon.', 'Enter contact phone.');
  static String get lostDate => L10n.tr('Datum nestanka', 'Date missing');
  static String get foundDate => L10n.tr('Datum pronalaska', 'Date found');
  static String get photo => L10n.tr('Fotografija', 'Photo');
  static String get addPhoto => L10n.tr('Dodaj fotografiju', 'Add photo');
  static String get photoRequired =>
      L10n.tr('Dodajte fotografiju pronađenog psa.', 'Add a photo of the found dog.');
  static String get publish => L10n.tr('Prijavi nestanak', 'Report missing');
  static String get publishFound => L10n.tr('Prijavi pronalazak', 'Report found');
  static String get publishing => L10n.tr('Slanje...', 'Sending...');
  static String get published =>
      L10n.tr('Prijava nestanka je objavljena. 🐾', 'Missing report published. 🐾');
  static String get publishedFound =>
      L10n.tr('Prijava pronađenog psa je objavljena. 🐾', 'Found report published. 🐾');
  static String get publishSuccessTitle => L10n.tr('Prijava objavljena', 'Report published');
  static String get publishSuccessBody => L10n.tr(
        'Vaša prijava je uspešno sačuvana i sada je vidljiva u zajednici.',
        'Your report was saved and is now visible in the community.',
      );
  static String get ok => L10n.tr('U redu', 'OK');
  static String get publishError =>
      L10n.tr('Prijava nije sačuvana. Pokušajte ponovo.', 'Report was not saved. Try again.');
  static String get sighting => L10n.tr('Prijavi da sam ga video', 'Report a sighting');
  static String get contactFinder => L10n.tr('Kontaktiraj pronalazača', 'Contact finder');
  static String get leaveComment => L10n.tr('Ostavi komentar', 'Leave a comment');
  static String get commentsTitle => L10n.tr('Komentari', 'Comments');
  static String get likeComment => L10n.tr('Lajk', 'Like');
  static String get likeFailed => L10n.tr(
        'Lajk nije sačuvan. Pokušajte ponovo.',
        'Like was not saved. Try again.',
      );
  static String get commentHint =>
      L10n.tr('Gde i kada si video psa...', 'Where and when you saw the dog...');
  static String get commentEmpty =>
      L10n.tr('Još nema komentara. Budi prvi!', 'No comments yet. Be the first!');
  static String get commentSent => L10n.tr('Komentar je sačuvan.', 'Comment saved.');
  static String get commentFailed =>
      L10n.tr('Komentar nije sačuvan. Pokušajte ponovo.', 'Comment was not saved. Try again.');
  static String get commentPermissionDenied => L10n.tr(
        'Nemate dozvolu za komentar. Proverite da ste ulogovani.',
        'You cannot comment. Make sure you are signed in.',
      );
  static String get found => L10n.tr('Pas je pronađen', 'Dog found');
  static String get markResolved => L10n.tr('Označi kao rešeno', 'Mark resolved');
  static String get deletePost => L10n.tr('Obriši prijavu', 'Delete report');
  static String get deleteConfirmTitle => L10n.tr('Obrisati prijavu?', 'Delete report?');
  static String get deleteConfirmBody => L10n.tr(
        'Prijava će biti uklonjena i više neće biti vidljiva drugima.',
        'The report will be removed and no longer visible to others.',
      );
  static String get foundConfirmTitle => L10n.tr('Označiti kao rešeno?', 'Mark as resolved?');
  static String get foundConfirmBody => L10n.tr(
        'Oglas će nestati iz aktivnih potražnji.',
        'The listing will leave active searches.',
      );
  static String get callOwner => L10n.tr('Pozovi vlasnika', 'Call owner');
  static String get callFinder => L10n.tr('Pozovi pronalazača', 'Call finder');
  static String get understand => L10n.tr('Razumem / Zatvori', 'Got it / Close');
  static String get emergencyTitle =>
      L10n.tr('🚨 HITNO: IZGUBLJEN PAS U TVOJEM GRADU!', '🚨 URGENT: LOST DOG IN YOUR CITY!');
  static String get callUnavailable =>
      L10n.tr('Broj telefona nije dostupan.', 'Phone number unavailable.');
  static String get sightingTitle => L10n.tr('Javi vlasniku', 'Notify owner');
  static String get sightingBody => L10n.tr(
        'Pozovi vlasnika ili pošalji poruku da si video psa.',
        'Call the owner or send a message that you saw the dog.',
      );
  static String get finderTitle => L10n.tr('Kontaktiraj pronalazača', 'Contact finder');
  static String get finderBody => L10n.tr(
        'Pozovi ili pošalji poruku osobi koja je prijavila pronađenog psa.',
        'Call or message the person who reported the found dog.',
      );
  static String get sendSms => L10n.tr('Pošalji poruku', 'Send message');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get urgentBadge => L10n.tr('HITNO', 'URGENT');
  static String get missingBadge => L10n.tr('IZGUBLJEN', 'LOST');
  static String get foundBadge => L10n.tr('PRONAĐEN', 'FOUND');
  static String get viewMatch => L10n.tr('🔍 Pogledaj profil', '🔍 View profile');
  static String get close => L10n.tr('Zatvori', 'Close');

  static List<String> get breedOptions => [
        breedUnknown,
        L10n.tr('Mešanac', 'Mixed breed'),
        L10n.tr('Zlatni retriver', 'Golden retriever'),
        L10n.tr('Labrador', 'Labrador'),
        L10n.tr('Nemački ovčar', 'German shepherd'),
        L10n.tr('Maltezer', 'Maltese'),
        L10n.tr('Pudla', 'Poodle'),
        L10n.tr('Mops', 'Pug'),
        L10n.tr('Husky', 'Husky'),
        L10n.tr('Beagle', 'Beagle'),
        breedOther,
      ];

  static String missingHeadline(String name) =>
      L10n.tr('$name je nestao', '$name is missing');

  static String foundHeadline(String name) =>
      L10n.tr('$name je pronađen', '$name was found');

  static String lostOn(String date) => L10n.tr('🕐 Nestao: $date.', '🕐 Missing: $date.');

  static String foundOn(String date) => L10n.tr('🕐 Pronađen: $date.', '🕐 Found: $date.');

  static String place(String city, String neighborhood) {
    if (city.isEmpty) {
      return neighborhood;
    }
    if (neighborhood.isEmpty) {
      return city;
    }
    return '$city – $neighborhood';
  }

  static String breedLine(String breedValue) {
    if (breedValue.trim().isEmpty) {
      return L10n.tr('Rasa: $breedUnknown', 'Breed: $breedUnknown');
    }
    return L10n.tr('Rasa: $breedValue', 'Breed: $breedValue');
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String timeAgo(DateTime value, [DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(value);
    if (diff.inMinutes < 1) {
      return L10n.tr('sada', 'now');
    }
    if (diff.inMinutes < 60) {
      return L10n.tr('pre ${diff.inMinutes} min', '${diff.inMinutes} min ago');
    }
    if (diff.inHours < 24) {
      return L10n.tr('pre ${diff.inHours} č', '${diff.inHours} h ago');
    }
    if (diff.inDays < 7) {
      return L10n.tr('pre ${diff.inDays} d', '${diff.inDays} d ago');
    }
    return formatDate(value);
  }

  static String smsBody(String dogName) => L10n.tr(
        'Zdravo, video/la sam vašeg psa $dogName. Javljam se preko VauVau aplikacije.',
        'Hi, I saw your dog $dogName. Contacting you via the VauVau app.',
      );

  static String finderSmsBody() => L10n.tr(
        'Zdravo, javljam se zbog pronađenog psa preko VauVau aplikacije.',
        'Hi, I\'m reaching out about a found dog via the VauVau app.',
      );

  static String matchBanner(LostDogMatchCopy match) => L10n.tr(
        '⚠️ MOGUĆE POKLAPANJE: "${match.name}" (${match.breed}) je prijavljen kao nestao u naselju ${match.neighborhood}!',
        '⚠️ POSSIBLE MATCH: "${match.name}" (${match.breed}) was reported missing in ${match.neighborhood}!',
      );

  static String viewMatchProfile(String name) =>
      L10n.tr('Pogledaj profil "$name"', 'View profile "$name"');
}

class LostDogMatchCopy {
  const LostDogMatchCopy({
    required this.name,
    required this.breed,
    required this.neighborhood,
  });

  final String name;
  final String breed;
  final String neighborhood;
}
