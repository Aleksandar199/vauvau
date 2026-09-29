abstract final class MomentsStrings {
  static const String drawerItem = '📸 VauVau Moments';
  static const String title = 'VauVau Moments';
  static const String share = '+ Podeli moment';
  static const String like = '❤️ Lajk';
  static const String comment = '💬 Komentar';
  static const String viewDog = '🐕 Pogledaj psa';
  static const String commentsTitle = 'Komentari';
  static const String commentHint = 'Napiši komentar...';
  static const String send = 'Pošalji';
  static const String empty = 'Još nema momenata. Budi prvi!';
  static const String loadError =
      'Momenti trenutno nisu dostupni. Proverite internet i pokušajte ponovo.';
  static const String retry = 'Pokušaj ponovo';
  static const String caption = 'Opis';
  static const String location = 'Park / lokacija';
  static const String dog = 'Pas';
  static const String photo = 'Fotografija';
  static const String addPhoto = 'Dodaj fotografiju';
  static const String publish = 'Objavi';
  static const String publishError = 'Moment nije sačuvan. Pokušajte ponovo.';
  static const String captionRequired = 'Unesite opis.';
  static const String dogRequired = 'Izaberite psa.';
  static const String noDogs = 'Prvo dodajte profil psa.';

  static String locationPin(String name) => '📍 $name';

  static String timeAgo(DateTime value, DateTime now) {
    final diff = now.difference(value);
    if (diff.inMinutes < 1) {
      return 'sada';
    }
    if (diff.inMinutes < 60) {
      return 'pre ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'pre ${diff.inHours} č';
    }
    if (diff.inDays < 7) {
      return 'pre ${diff.inDays} d';
    }
    return '${value.day}.${value.month}.';
  }
}
