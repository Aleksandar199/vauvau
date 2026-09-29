abstract final class AdminStrings {
  static const String panel = 'Administracija';
  static const String title = 'Administracija';
  static const String denied = 'Samo administratori mogu da otvore ovaj panel.';
  static const String pendingTab = 'Na čekanju (POIs)';
  static const String reportsTab = 'Prijave (Reports)';
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
  static const String name = 'Naziv';
  static const String address = 'Adresa';

  static const String drawerItem = 'Admin Panel';
  static const String feedbackTab = '📩 Poruke & Feedback';
  static const String momentsTab = '📸 Moderacija Momenata';
  static const String usersTab = '👤 Korisnici';
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

  static String totalUsers(int count) => 'Ukupno registrovanih: $count';

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
