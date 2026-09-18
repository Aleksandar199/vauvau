abstract final class ProfileStrings {
  static const String tabLabel = 'Profil';
  static const String title = 'Profil';
  static const String editProfile = 'Izmeni profil';
  static const String settings = 'Podešavanja';
  static const String searchFilters = 'Filteri za pretragu';
  static const String signOut = 'Odjavi se';
  static const String signOutTitle = 'Odjava';
  static const String signOutBody =
      'Da li ste sigurni da želite da se odjavite?';
  static const String cancel = 'Otkaži';
  static const String ownerSection = 'Vlasnik';
  static const String dogName = 'Ime psa';
  static const String breed = 'Rasa';
  static const String ageYears = 'Starost (godine)';
  static const String ageMonths = 'Starost (meseci)';
  static const String gender = 'Pol';
  static const String bio = 'Opis psa';
  static const String ownerName = 'Ime vlasnika';
  static const String ownerBio = 'Kratak opis vlasnika';
  static const String ownerLocation = 'Lokacija';
  static const String phone = 'Telefon';
  static const String joined = 'Član od';
  static const String personality = 'Temperament';
  static const String city = 'Grad';
  static const String neighborhood = 'Naselje';
  static const String photos = 'Galerija';
  static const String addPhoto = 'Dodaj';
  static const String removePhoto = 'Ukloni';
  static const String saveChanges = 'Sačuvaj izmene';
  static const String saved = 'Profil uspešno ažuriran!';
  static const String validation = 'Unesite ime i rasu psa.';
  static const String sizeLabel = 'Veličina';
  static const String filtersTitle = 'Filteri za pretragu';
  static const String sizeFilter = 'Veličina psa';
  static const String genderFilter = 'Pol';
  static const String cityFilter = 'Grad';
  static const String sizeSmall = 'Mali';
  static const String sizeMedium = 'Srednji';
  static const String sizeLarge = 'Veliki';
  static const String genderMale = 'Mužjak';
  static const String genderFemale = 'Ženka';
  static const String genderAny = 'Svejedno';
  static const String cityNoviSad = 'Novi Sad';
  static const String cityBeograd = 'Beograd';
  static const String cityAll = 'Svi gradovi';
  static const String applyFilters = 'Primeni filtere';
  static const String photoPlaceholder = 'Nova fotografija';
  static const String radiusFilter = 'Radius pretrage';
  static const String weight = 'Težina';
  static const String vaccines = 'Vakcinisan';
  static const String chipStatus = 'Čipovan';
  static const String sterilized = 'Kastriran / Sterilisan';
  static const String badgeChipped = 'Čipovan ✓';
  static const String badgeVaccinated = 'Vakcinisan ✓';
  static const String badgeSterilized = 'Sterilisan ✓';
  static const String contact = 'Kontakt';
  static const String myDogs = 'Moji psi';
  static const String notifications = 'Notifikacije';
  static const String notifyWalks = 'Zahtevi za šetnju';
  static const String notifyMessages = 'Poruke';
  static const String notifyMatches = 'Novi mečevi';
  static const String showLocation = 'Prikaži moju lokaciju na mapi';
  static const String account = 'Nalog';
  static const String deleteAccount = 'Obriši nalog';
  static const String deleteAccountTitle = 'Brisanje naloga';
  static const String deleteAccountBody =
      'Nalog će biti uklonjen sa ovog uređaja. Ova radnja je lokalna i ne može se opozvati.';
  static const String deleteConfirm = 'Obriši';
  static const String appVersion = 'VauVau v1.0.0';
  static const String closePhoto = 'Zatvori';

  static String radiusValue(double km) => '${km.round()} km';

  static String kg(double value) => '${value.toStringAsFixed(0)} kg';

  static String joinedLabel(DateTime date) =>
      '${date.day}.${date.month}.${date.year}.';

  static const List<String> personalityOptions = [
    'Energičan',
    'Druželjubiv',
    'Mirna',
    'Igračka',
    'Zaštitnički',
    'Sramežljiv',
    'Voli loptice',
  ];

  static String sizeBadge(String size) {
    switch (size) {
      case 'mali':
        return sizeSmall;
      case 'srednji':
        return sizeMedium;
      case 'veliki':
        return sizeLarge;
      default:
        return size;
    }
  }

  static String ageLabel(int years, [int months = 0]) {
    if (months <= 0) {
      return '$years god.';
    }
    return '$years god. $months mes.';
  }

  static String genderValue(String gender) {
    switch (gender) {
      case 'mužjak':
        return genderMale;
      case 'ženka':
        return genderFemale;
      default:
        return gender;
    }
  }
}
