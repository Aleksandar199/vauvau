import '../../../core/l10n/l10n.dart';

abstract final class ProfileStrings {
  static String get tabLabel => L10n.tr('Profil', 'Profile');
  static String get title => L10n.tr('Profil', 'Profile');
  static String get editProfile => L10n.tr('Izmeni profil', 'Edit profile');
  static String get ownerDogs => L10n.tr('Psi', 'Dogs');
  static String get ownerUnknown => L10n.tr('Korisnik', 'User');
  static String get editDog => L10n.tr('Izmeni psa', 'Edit dog');
  static String get deleteDog => L10n.tr('Obriši psa', 'Delete dog');
  static String get deleteDogTitle =>
      L10n.tr('Obrisati psa?', 'Delete dog?');
  static String get deleteDogBody => L10n.tr(
        'Profil psa će biti trajno uklonjen. Ova radnja se ne može opozvati.',
        'The dog profile will be permanently removed. This cannot be undone.',
      );
  static String get dogDeleted => L10n.tr('Pas je obrisan.', 'Dog deleted.');
  static String get deleteDogFailed => L10n.tr(
        'Brisanje nije uspelo. Pokušajte ponovo.',
        'Delete failed. Try again.',
      );
  static String get addDog => L10n.tr('Dodaj psa', 'Add dog');
  static String get addDogHint =>
      L10n.tr('Još nemate sačuvanog psa.', 'You have not saved a dog yet.');
  static String get settings => L10n.tr('Podešavanja', 'Settings');
  static String get adminPanel => L10n.tr('Administracija', 'Administration');
  static String get adminBadge => L10n.tr('ADMIN', 'ADMIN');
  static String get moreActions => L10n.tr('Više opcija', 'More options');
  static String get searchFilters =>
      L10n.tr('Filteri za pretragu', 'Search filters');
  static String get signOut => L10n.tr('Odjavi se', 'Sign out');
  static String get signOutTitle =>
      L10n.tr('Odjava iz naloga', 'Sign out');
  static String get signOutBody => L10n.tr(
        'Bićete odjavljeni sa ovog uređaja. Možete se ponovo prijaviti u bilo kom trenutku.',
        'You will be signed out on this device. You can sign in again anytime.',
      );
  static String get signingOut =>
      L10n.tr('Odjavljivanje...', 'Signing out...');
  static String get signOutFailed => L10n.tr(
        'Odjava nije uspela. Pokušajte ponovo.',
        'Sign out failed. Try again.',
      );
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get ownerSection => L10n.tr('Vlasnik', 'Owner');
  static String get dogName => L10n.tr('Ime psa', 'Dog name');
  static String get breed => L10n.tr('Rasa', 'Breed');
  static String get ageYears => L10n.tr('Starost (godine)', 'Age (years)');
  static String get ageMonths => L10n.tr('Starost (meseci)', 'Age (months)');
  static String get gender => L10n.tr('Pol', 'Gender');
  static String get genderRequired =>
      L10n.tr('Izaberi pol psa.', 'Select the dog\'s gender.');
  static String get bio => L10n.tr('Opis psa', 'Dog bio');
  static String get bioHint => L10n.tr(
        'Kratko opišite karakter, navike i kako pas voli da se druži...',
        'Briefly describe temperament, habits, and how your dog likes to socialize...',
      );
  static String get ownerBioHint => L10n.tr(
        'Npr. Šetačica sa Limana, volim jutarnje šetnje uz Dunav.',
        'e.g. Walker from Liman, I love morning walks along the Danube.',
      );
  static String get ownerNameHint => L10n.tr('npr. Ana', 'e.g. Ana');
  static String get dogNameHint => L10n.tr('npr. Luna', 'e.g. Luna');
  static String get breedHint =>
      L10n.tr('npr. Zlatni retriver', 'e.g. Golden Retriever');
  static String get ownerName => L10n.tr('Ime vlasnika', 'Owner name');
  static String get ownerBio =>
      L10n.tr('Kratak opis vlasnika', 'Short owner bio');
  static String get ownerLocation => L10n.tr('Lokacija', 'Location');
  static String get phone => L10n.tr('Telefon', 'Phone');
  static String get joined => L10n.tr('Član od', 'Member since');
  static String get personality => L10n.tr('Temperament', 'Personality');
  static String get likesTitle => L10n.tr('🐕 Voli', '🐕 Likes');
  static String get dislikesTitle => L10n.tr('❌ Ne voli', '❌ Dislikes');
  static String get city => L10n.tr('Grad', 'City');
  static String get neighborhood => L10n.tr('Naselje', 'Neighborhood');
  static String get photos => L10n.tr('Galerija', 'Gallery');
  static String get addPhoto => L10n.tr('Dodaj', 'Add');
  static String get removePhoto => L10n.tr('Ukloni', 'Remove');
  static String get saveChanges =>
      L10n.tr('Sačuvaj izmene', 'Save changes');
  static String get saved =>
      L10n.tr('Profil uspešno ažuriran!', 'Profile updated successfully!');
  static String get validation =>
      L10n.tr('Unesite ime i rasu psa.', 'Enter the dog name and breed.');
  static String get sizeLabel => L10n.tr('Veličina', 'Size');
  static String get filtersTitle =>
      L10n.tr('Filteri za pretragu', 'Search filters');
  static String get sizeFilter => L10n.tr('Veličina psa', 'Dog size');
  static String get genderFilter => L10n.tr('Pol', 'Gender');
  static String get cityFilter => L10n.tr('Grad', 'City');
  static String get sizeSmall => L10n.tr('Mali', 'Small');
  static String get sizeMedium => L10n.tr('Srednji', 'Medium');
  static String get sizeLarge => L10n.tr('Veliki', 'Large');
  static String get genderMale => L10n.tr('Mužjak', 'Male');
  static String get genderFemale => L10n.tr('Ženka', 'Female');
  static String get genderAny => L10n.tr('Svejedno', 'Any');
  static String get cityNoviSad => L10n.tr('Novi Sad', 'Novi Sad');
  static String get cityBeograd => L10n.tr('Beograd', 'Belgrade');
  static String get cityNis => L10n.tr('Niš', 'Nis');
  static String get cityKragujevac => L10n.tr('Kragujevac', 'Kragujevac');
  static String get cityAll => L10n.tr('Moj grad', 'My city');
  static String get applyFilters =>
      L10n.tr('Primeni filtere', 'Apply filters');
  static String get photoPlaceholder =>
      L10n.tr('Nova fotografija', 'New photo');
  static String get radiusFilter =>
      L10n.tr('Radius pretrage', 'Search radius');
  static String get weight => L10n.tr('Težina', 'Weight');
  static String get vaccines => L10n.tr('Vakcinisan', 'Vaccinated');
  static String get chipStatus => L10n.tr('Čipovan', 'Microchipped');
  static String get sterilized =>
      L10n.tr('Kastriran / Sterilisan', 'Neutered / Spayed');
  static String get badgeChipped =>
      L10n.tr('Čipovan ✓', 'Microchipped ✓');
  static String get badgeVaccinated =>
      L10n.tr('Vakcinisan ✓', 'Vaccinated ✓');
  static String get badgeSterilized =>
      L10n.tr('Sterilisan ✓', 'Sterilized ✓');
  static String get contact => L10n.tr('Kontakt', 'Contact');
  static String get myDogs => L10n.tr('Moji psi', 'My dogs');
  static String get momentsGallery => L10n.tr('Momenti', 'Moments');
  static String get momentsEmpty => L10n.tr(
        'Još nema momenata za ovog psa.',
        'No moments for this dog yet.',
      );
  static String get metricDogs => L10n.tr('Psi', 'Dogs');
  static String get metricMoments => L10n.tr('Momenti', 'Moments');
  static String get metricAge => L10n.tr('Starost', 'Age');
  static String get notifications =>
      L10n.tr('Notifikacije', 'Notifications');
  static String get enableNotifications =>
      L10n.tr('Omogući obaveštenja', 'Enable notifications');
  static String get notifyWalks =>
      L10n.tr('Zahtevi za šetnju', 'Walk requests');
  static String get notifyMessages => L10n.tr('Poruke', 'Messages');
  static String get notifyMatches =>
      L10n.tr('Novi mečevi', 'New matches');
  static String get showLocation => L10n.tr(
        'Prikaži moju lokaciju na mapi',
        'Show my location on the map',
      );
  static String get showLocationHint => L10n.tr(
        'Drugi vlasnici vide tvog psa na mapi dok šetaš.',
        'Other owners see your dog on the map while you walk.',
      );
  static String get enableNotificationsHint => L10n.tr(
        'Traži dozvolu telefona ako još nije data.',
        'Request phone permission if not granted yet.',
      );
  static String get notifyWalksHint => L10n.tr(
        'Isključi ako ne želiš push za pozive u šetnju.',
        'Turn off if you do not want push for walk invites.',
      );
  static String get notifyMessagesHint => L10n.tr(
        'Isključi ako ne želiš push za nove poruke.',
        'Turn off if you do not want push for new messages.',
      );
  static String get notifyMatchesHint => L10n.tr(
        'Isključi ako ne želiš push za nove mečeve.',
        'Turn off if you do not want push for new matches.',
      );
  static String get notificationsGranted => L10n.tr(
        'Obaveštenja su uključena.',
        'Notifications are enabled.',
      );
  static String get notificationsDenied => L10n.tr(
        'Dozvola nije data. Uključi obaveštenja u podešavanjima telefona.',
        'Permission not granted. Enable notifications in phone settings.',
      );
  static String get notificationsUnsupported => L10n.tr(
        'Push obaveštenja nisu dostupna na ovom uređaju.',
        'Push notifications are not available on this device.',
      );
  static String get searchAndMap =>
      L10n.tr('Pretraga i mapa', 'Search and map');
  static String get radiusHint => L10n.tr(
        'Koliko daleko tražimo pse za šetnju i druženje.',
        'How far we look for dogs to walk and socialize.',
      );
  static String get searchFiltersHint =>
      L10n.tr('Veličina, pol i grad', 'Size, gender, and city');
  static String get account => L10n.tr('Nalog', 'Account');
  static String get deleteAccount =>
      L10n.tr('Obriši nalog', 'Delete account');
  static String get deleteAccountTitle =>
      L10n.tr('Brisanje naloga', 'Delete account');
  static String get deleteAccountBody => L10n.tr(
        'Ovo trajno briše nalog i vaš sadržaj: profile pasa, fotografije, momente, chat poruke, mečeve, oglase, događaje koje ste organizovali i podešavanja. Radnja se ne može opozvati.',
        'This permanently deletes your account and your content: dog profiles, photos, moments, chat messages, matches, listings, events you organized, and settings. This cannot be undone.',
      );
  static String get deleteConfirm => L10n.tr('Obriši', 'Delete');
  static String get deleteAccountPasswordHint => L10n.tr(
        'Radi bezbednosti unesite lozinku.',
        'For your security, enter your password.',
      );
  static String get deleteAccountFailed => L10n.tr(
        'Nalog nije obrisan. Pokušajte ponovo.',
        'Account was not deleted. Try again.',
      );
  static String get appVersion => L10n.tr('VauVau v1.0.0', 'VauVau v1.0.0');
  static String get closePhoto => L10n.tr('Zatvori', 'Close');
  static String get setOwnerPhoto =>
      L10n.tr('Postavi sliku', 'Set photo');
  static String get changeOwnerPhoto =>
      L10n.tr('Izmeni sliku', 'Change photo');
  static String get ownerPhotoCamera => L10n.tr('Kamera', 'Camera');
  static String get ownerPhotoUploadFailed => L10n.tr(
        'Greška prilikom dodavanja slike. Pokušajte ponovo.',
        'Failed to add photo. Try again.',
      );
  static String get appearance => L10n.tr('Izgled', 'Appearance');
  static String get appearanceHint => L10n.tr(
        'Izaberite svetlu ili tamnu pozadinu aplikacije.',
        'Choose a light or dark app background.',
      );
  static String get themeDark =>
      L10n.tr('Tamno plava', 'Dark blue');
  static String get themeLight => L10n.tr('Svetla', 'Light');
  static String get language => L10n.tr('Jezik', 'Language');
  static String get languageHint => L10n.tr(
        'Izaberite jezik aplikacije.',
        'Choose the app language.',
      );
  static String get languageSerbian => L10n.tr('Srpski', 'Serbian');
  static String get languageEnglish => L10n.tr('English', 'English');

  static String radiusValue(double km) => '${km.round()} km';

  static String kg(double value) => '${value.toStringAsFixed(0)} kg';

  static String joinedLabel(DateTime date) =>
      '${date.day}.${date.month}.${date.year}.';

  static List<String> get personalityOptions => L10n.isEnglish
      ? [
          'Energetic',
          'Friendly',
          'Calm',
          'Protective',
          'Shy',
          'Loves balls',
        ]
      : [
          'Energičan',
          'Druželjubiv',
          'Miran',
          'Zaštitnički',
          'Sramežljiv',
          'Voli loptice',
        ];

  static String sizeBadge(String size) {
    switch (size.trim().toLowerCase()) {
      case 'mali':
      case 'small':
        return sizeSmall;
      case 'srednji':
      case 'medium':
        return sizeMedium;
      case 'veliki':
      case 'large':
      case 'xlarge':
        return sizeLarge;
      default:
        return size.isEmpty ? sizeMedium : size;
    }
  }

  static String ageLabel(int years, [int months = 0]) {
    if (L10n.isEnglish) {
      if (months <= 0) {
        return '$years yr.';
      }
      return '$years yr. $months mo.';
    }
    if (months <= 0) {
      return '$years god.';
    }
    return '$years god. $months mes.';
  }

  static String genderValue(String gender) {
    switch (gender.trim().toLowerCase()) {
      case 'mužjak':
      case 'muzjak':
      case 'male':
        return genderMale;
      case 'ženka':
      case 'zenka':
      case 'female':
        return genderFemale;
      default:
        return gender.isEmpty ? '—' : gender;
    }
  }
}
