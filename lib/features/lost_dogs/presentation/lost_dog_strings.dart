abstract final class LostDogStrings {
  static const String title = 'Izgubljeni i pronađeni';
  static const String drawerItem = '🚨 Izgubljeni psi';
  static const String banner = '🚨 Pomozi u potrazi za nestalim ljubimcima!';
  static const String foundBanner =
      '🟢 Javi vlasniku ako si našao psa ili vidi ko je prijavio pronalazak.';
  static const String addCta = '+ Prijavi slučaj';
  static const String chooseTitle = 'Šta želiš da prijaviš?';
  static const String reportLost = '🚨 Prijavi nestanak mog psa';
  static const String reportFound = '🟢 Našao sam tuđeg psa';
  static const String addTitle = 'Prijava nestanka';
  static const String addFoundTitle = 'Prijava pronađenog psa';
  static const String empty = 'Trenutno nema aktivnih prijava nestanka.';
  static const String emptyFound = 'Trenutno nema prijava pronađenih pasa.';
  static const String emptyAll = 'Još nema aktivnih prijava.';
  static const String tabLost = '🚨 Izgubljeni';
  static const String tabFound = '🟢 Pronađeni';
  static const String tabAll = 'Svi';
  static const String dogName = 'Ime psa';
  static const String dogNameOptional = 'Ime psa (ako znaš)';
  static const String unknownName = 'Nepoznat pas';
  static const String dogNameRequired = 'Unesite ime psa.';
  static const String breed = 'Rasa';
  static const String breedRequired = 'Izaberite rasu.';
  static const String breedOther = 'Drugo';
  static const String breedUnknown = 'Nije sigurno';
  static const String breedHint = 'npr. Zlatni retriver';
  static const String description = 'Opis';
  static const String descriptionHint =
      'Boja, ogrlica, ponašanje, gde je poslednji put viđen...';
  static const String foundDescriptionHint =
      'Boja, ogrlica, gde je pronađen, kako se ponaša...';
  static const String descriptionRequired = 'Unesite opis.';
  static const String phone = 'Kontakt telefon';
  static const String phoneRequired = 'Unesite kontakt telefon.';
  static const String lostDate = 'Datum nestanka';
  static const String foundDate = 'Datum pronalaska';
  static const String photo = 'Fotografija';
  static const String addPhoto = 'Dodaj fotografiju';
  static const String photoRequired = 'Dodajte fotografiju pronađenog psa.';
  static const String publish = 'Prijavi nestanak';
  static const String publishFound = 'Prijavi pronalazak';
  static const String publishing = 'Slanje...';
  static const String published = 'Prijava nestanka je objavljena. 🐾';
  static const String publishedFound = 'Prijava pronađenog psa je objavljena. 🐾';
  static const String publishError = 'Prijava nije sačuvana. Pokušajte ponovo.';
  static const String sighting = '👁️ Prijavi da sam ga video';
  static const String contactFinder = '📞 Kontaktiraj poštenog pronalazača';
  static const String found = '✅ Pas je pronađen';
  static const String markResolved = 'Označi kao rešeno';
  static const String deletePost = 'Obriši prijavu';
  static const String deleteConfirmTitle = 'Obrisati prijavu?';
  static const String deleteConfirmBody =
      'Prijava će biti uklonjena i više neće biti vidljiva drugima.';
  static const String foundConfirmTitle = 'Označiti kao rešeno?';
  static const String foundConfirmBody =
      'Oglas će nestati iz aktivnih potražnji.';
  static const String callOwner = '📞 Pozovi vlasnika';
  static const String callFinder = '📞 Pozovi pronalazača';
  static const String understand = 'Razumem / Zatvori';
  static const String emergencyTitle = '🚨 HITNO: IZGUBLJEN PAS U TVOJEM GRADU!';
  static const String callUnavailable = 'Broj telefona nije dostupan.';
  static const String sightingTitle = 'Javi vlasniku';
  static const String sightingBody =
      'Pozovi vlasnika ili pošalji poruku da si video psa.';
  static const String finderTitle = 'Kontaktiraj pronalazača';
  static const String finderBody =
      'Pozovi ili pošalji poruku osobi koja je prijavila pronađenog psa.';
  static const String sendSms = 'Pošalji poruku';
  static const String cancel = 'Otkaži';
  static const String missingBadge = '🚨 IZGUBLJEN PAS';
  static const String foundBadge = '🟢 PRONAĐEN PAS';
  static const String viewMatch = '🔍 Pogledaj profil';
  static const String close = 'Zatvori';

  static const List<String> breedOptions = [
    breedUnknown,
    'Mešanac',
    'Zlatni retriver',
    'Labrador',
    'Nemački ovčar',
    'Maltezer',
    'Pudla',
    'Mops',
    'Husky',
    'Beagle',
    breedOther,
  ];

  static String missingHeadline(String name) => '$name je nestao';

  static String foundHeadline(String name) => '$name je pronađen';

  static String lostOn(String date) => '🕐 Nestao: $date.';

  static String foundOn(String date) => '🕐 Pronađen: $date.';

  static String place(String city, String neighborhood) =>
      '📍 $city – $neighborhood';

  static String breedLine(String breed) =>
      breed.trim().isEmpty ? 'Rasa: $breedUnknown' : 'Rasa: $breed';

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String smsBody(String dogName) =>
      'Zdravo, video/la sam vašeg psa $dogName. Javljam se preko VauVau aplikacije.';

  static String finderSmsBody() =>
      'Zdravo, javljam se zbog pronađenog psa preko VauVau aplikacije.';

  static String matchBanner(LostDogMatchCopy match) {
    return '⚠️ MOGUĆE POKLAPANJE: "${match.name}" (${match.breed}) je prijavljen kao nestao u naselju ${match.neighborhood}!';
  }

  static String viewMatchProfile(String name) => '🔍 Pogledaj profil "$name"';
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
