abstract final class ProfileStrings {
  static const String tabLabel = 'Profil';
  static const String title = 'Profil';
  static const String editProfile = 'Izmeni profil';
  static const String editDog = 'Izmeni psa';
  static const String addDog = 'Dodaj psa';
  static const String addDogHint = 'Još nemate sačuvanog psa.';
  static const String settings = 'Podešavanja';
  static const String adminPanel = 'Administracija';
  static const String adminBadge = 'ADMIN';
  static const String moreActions = 'Više opcija';
  static const String searchFilters = 'Filteri za pretragu';
  static const String signOut = 'Odjavi se';
  static const String signOutTitle = 'Odjava iz naloga';
  static const String signOutBody =
      'Bićete odjavljeni sa ovog uređaja. Možete se ponovo prijaviti u bilo kom trenutku.';
  static const String signingOut = 'Odjavljivanje...';
  static const String signOutFailed = 'Odjava nije uspela. Pokušajte ponovo.';
  static const String cancel = 'Otkaži';
  static const String ownerSection = 'Vlasnik';
  static const String dogName = 'Ime psa';
  static const String breed = 'Rasa';
  static const String ageYears = 'Starost (godine)';
  static const String ageMonths = 'Starost (meseci)';
  static const String gender = 'Pol';
  static const String bio = 'Opis psa';
  static const String bioHint =
      'Kratko opišite karakter, navike i kako pas voli da se druži...';
  static const String ownerBioHint =
      'Npr. Šetačica sa Limana, volim jutarnje šetnje uz Dunav.';
  static const String ownerNameHint = 'npr. Ana';
  static const String dogNameHint = 'npr. Luna';
  static const String breedHint = 'npr. Zlatni retriver';
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
  static const String momentsGallery = 'Momenti';
  static const String momentsEmpty = 'Još nema momenata za ovog psa.';
  static const String metricDogs = 'Psi';
  static const String metricMoments = 'Momenti';
  static const String metricAge = 'Starost';
  static const String notifications = 'Notifikacije';
  static const String enableNotifications = 'Omogući obaveštenja';
  static const String notifyWalks = 'Zahtevi za šetnju';
  static const String notifyMessages = 'Poruke';
  static const String notifyMatches = 'Novi mečevi';
  static const String showLocation = 'Prikaži moju lokaciju na mapi';
  static const String showLocationHint =
      'Drugi vlasnici vide tvog psa na mapi dok šetaš.';
  static const String enableNotificationsHint =
      'Dozvoli VauVau-u da ti šalje obaveštenja na telefon.';
  static const String notifyWalksHint = 'Kada te neko pozove u šetnju';
  static const String notifyMessagesHint = 'Nove poruke u četu';
  static const String notifyMatchesHint = 'Kada se tvoj pas spoji sa drugim';
  static const String notificationsGranted = 'Obaveštenja su uključena.';
  static const String notificationsDenied =
      'Dozvola nije data. Uključi obaveštenja u podešavanjima telefona.';
  static const String notificationsUnsupported =
      'Push obaveštenja nisu dostupna na ovom uređaju.';
  static const String searchAndMap = 'Pretraga i mapa';
  static const String radiusHint =
      'Koliko daleko tražimo pse za šetnju i druženje.';
  static const String searchFiltersHint = 'Veličina, pol i grad';
  static const String account = 'Nalog';
  static const String deleteAccount = 'Obriši nalog';
  static const String deleteAccountTitle = 'Brisanje naloga';
  static const String deleteAccountBody =
      'Ovo trajno briše nalog, profile pasa, oglase za udomljavanje i prijave nestanka. Radnja se ne može opozvati.';
  static const String deleteConfirm = 'Obriši';
  static const String deleteAccountFailed =
      'Nalog nije obrisan. Pokušajte ponovo.';
  static const String appVersion = 'VauVau v1.0.0';
  static const String closePhoto = 'Zatvori';
  static const String setOwnerPhoto = 'Postavi sliku';
  static const String changeOwnerPhoto = 'Izmeni sliku';
  static const String ownerPhotoCamera = 'Kamera';
  static const String ownerPhotoUploadFailed =
      'Greška prilikom dodavanja slike. Pokušajte ponovo.';

  static String radiusValue(double km) => '${km.round()} km';

  static String kg(double value) => '${value.toStringAsFixed(0)} kg';

  static String joinedLabel(DateTime date) =>
      '${date.day}.${date.month}.${date.year}.';

  static const List<String> personalityOptions = [
    'Energičan',
    'Druželjubiv',
    'Miran',
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
