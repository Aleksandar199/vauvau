abstract final class AdminStrings {
  static const String panel = 'Administracija';
  static const String title = 'Administracija';
  static const String denied = 'Samo administratori mogu da otvore ovaj panel.';
  static const String statsTab = 'Statistika';
  static const String usersTab = 'Korisnici';
  static const String reportsTab = 'Prijave';
  static const String contentTab = 'Sadržaj';
  static const String pendingTab = 'Na čekanju (POIs)';
  static const String reportDeleteContent = 'Obriši';
  static const String reportMarkReviewed = 'Rešeno';
  static const String reportDismiss = 'Odbaci';
  static const String reportStatusPending = 'Na čekanju';
  static const String reportReason = 'Razlog';
  static const String reportReviewed = 'Prijava je označena kao rešena.';
  static const String confirmDeleteReported =
      'Prijavljeni sadržaj će biti uklonjen iz aplikacije.';
  static const String searchTab = 'Pretraga Korisnika & Pasa';
  static const String approve = '✓ Odobri';
  static const String edit = '✏️ Izmeni';
  static const String reject = '🗑️ Odbij';
  static const String block = '🚫 Blokiraj / Obriši Sadržaj';
  static const String dismiss = '✓ Odbaci Prijavu';
  static const String emptyPending = 'Nema POI predloga na čekanju.';
  static const String emptyReports = 'Nema aktivnih prijava.';
  static const String searchHint = 'Pretraži korisnike ili pse...';
  static const String noSearch = 'Nema rezultata.';
  static const String users = 'Korisnici';
  static const String dogs = 'Psi';
  static const String saved = 'Izmena je sačuvana.';
  static const String approved = 'Mesto je odobreno.';
  static const String rejected = 'Predlog je odbijen.';
  static const String blocked = 'Sadržaj je uklonjen.';
  static const String dismissed = 'Prijava je odbačena.';
  static const String editTitle = 'Izmeni mesto';
  static const String editAndResolve = 'Izmeni i reši';
  static const String saveAndResolve = 'Sačuvaj i označi rešeno';
  static const String saveOnly = 'Samo sačuvaj izmene';
  static const String reportContextTitle = 'Šta je prijavljeno';
  static const String name = 'Naziv';
  static const String address = 'Adresa';
  static const String openingHours = 'Radno vreme';
  static const String openingHoursHint = 'Npr. Pon–Pet 09–20, Sub 10–14';
  static const String pricePerNight = 'Cena po noći (RSD)';
  static const String pricePerNightHint = 'Ostavi prazno ako nema';
  static const String phone = 'Telefon';
  static const String website = 'Website';
  static const String latitude = 'Geografska širina';
  static const String longitude = 'Geografska dužina';
  static const String verificationStatus = 'Status provere';
  static const String statusVerified = '✓ Potvrđeno';
  static const String statusPending = 'Na čekanju';
  static const String statusSubmitted = 'Predloženo';
  static const String statusReported = 'Prijavljeno';
  static const String statusRejected = 'Odbijeno';
  static const String statusUnknown = 'Nije provereno';
  static const String flag24h = 'Dostupno 00–24h';
  static const String flagEmergency = 'Dežurna služba';
  static const String flagOvernight = 'Prenoćište';
  static const String flagDayCare = 'Dnevni boravak';
  static const String flagYard = 'Dvorište';
  static const String flagPetFriendly = 'Pet-friendly';
  static const String invalidCoords = 'Unesite ispravne koordinate.';
  static const String invalidPrice = 'Unesite ispravnu cenu ili ostavite prazno.';
  static const String poiNotFound =
      'Mesto nije pronađeno. Proverite ID ili dodajte ga kao novi POI.';
  static const String poiUpdatedAndResolved =
      'Mesto je izmenjeno i prijava je rešena.';

  static const String drawerItem = 'Admin Panel';
  static const String feedbackTab = '📩 Poruke & Feedback';
  static const String momentsTab = '📸 Moderacija Momenata';
  static const String emptyFeedback = 'Nema poruka od korisnika.';
  static const String emptyMoments = 'Nema objavljenih momenata.';
  static const String emptyUsers = 'Nema registrovanih korisnika.';
  static const String resolve = '✓ Označi kao rešeno';
  static const String resolved = 'Rešeno';
  static const String isNew = 'Novo';
  static const String delete = '🗑️ Obriši';
  static const String deleteMoment = '🗑️ Obriši momenat';
  static const String feedbackResolved = 'Poruka je označena kao rešena.';
  static const String feedbackDeleted = 'Poruka je obrisana.';
  static const String momentDeleted = 'Momenat je obrisan.';
  static const String actionFailed = 'Radnja nije uspela. Pokušajte ponovo.';
  static const String confirmDeleteTitle = 'Obrisati?';
  static const String confirmDeleteFeedback =
      'Poruka će biti trajno obrisana iz baze.';
  static const String confirmDeleteMoment =
      'Momenat će biti trajno obrisan za sve korisnike.';
  static const String cancel = 'Otkaži';
  static const String confirm = 'Obriši';
  static const String loadError = 'Podaci nisu dostupni.';
  static const String noEmail = 'Bez email adrese';
  static const String adminBadge = 'ADMIN';
  static const String statUsers = 'Korisnici';
  static const String statDogs = 'Aktivni psi';
  static const String statReports = 'Prijave';
  static const String statPending = 'POI na čekanju';
  static const String contentMoments = 'Momenti';
  static const String contentPending = 'Predlozi mesta';
  static const String groupsTab = 'Grupe na čekanju';
  static const String emptyPendingGroups =
      'Nema grupa koje čekaju na odobrenje';
  static const String groupApproved = 'Grupa je odobrena.';
  static const String groupDeleted = 'Grupa je obrisana.';
  static const String approveGroup = '✓ Odobri';
  static const String rejectGroup = '✗ Odbij';

  static String groupCreatedBy(String userId) {
    return 'Predložio: ${userId.isEmpty ? unknownUser : userId}';
  }

  static String groupCreatedAt(DateTime? value) {
    if (value == null) {
      return 'Datum kreiranja nepoznat';
    }
    return 'Kreirano: ${_date(value)}';
  }

  static String totalUsers(int count) => 'Ukupno registrovanih: $count';

  static String reportedBy(String userId) {
    return 'Prijavio: ${userId.isEmpty ? unknownUser : userId}';
  }

  static String reportedUser(String userId) {
    return 'Prijavljen: ${userId.isEmpty ? unknownUser : userId}';
  }

  static const String unknownUser = 'nepoznat korisnik';

  static String joinedOn(DateTime? value) {
    if (value == null) {
      return 'Datum pristupanja nepoznat';
    }
    return 'Pridružen/a ${_date(value)}';
  }

  static String timestamp(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${_date(value)} u $hour:$minute';
  }

  static String _date(DateTime value) {
    return '${value.day}.${value.month}.${value.year}.';
  }
}
