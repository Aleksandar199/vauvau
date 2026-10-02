abstract final class MomentsStrings {
  static const String drawerItem = '📸 VauVau Moments';
  static const String title = 'VauVau Moments';
  static const String share = 'Dodaj priču';
  static const String yourStory = 'Tvoja priča';
  static const String activeStories = 'Priče iz poslednja 24h';
  static const String storiesHint =
      'Priče nestaju posle 24h. Sačuvaj ih u Istaknuto i ostaće na profilu psa koliko god želiš.';
  static const String noStories = 'Nema aktivnih priča';
  static const String noStoriesSubtitle =
      'Budi prvi danas — podeli šetnju, park ili smešan trenutak.';
  static const String highlights = 'Istaknute priče';
  static const String newHighlight = 'Novo';
  static const String newHighlightTitle = 'Novo istaknuto';
  static const String editHighlightTitle = 'Uredi istaknuto';
  static const String highlightName = 'Naziv (npr. Šetnje, Park, Plaža)';
  static const String highlightNameRequired = 'Unesi naziv.';
  static const String highlightPickStories = 'Izaberi priče';
  static const String highlightPickRequired = 'Izaberi bar jednu priču.';
  static const String highlightCover = 'Naslovna slika';
  static const String highlightArchiveEmpty =
      'Još nemaš priča za ovog psa. Dodaj priču u Momentima pa je istakni ovde.';
  static const String highlightSave = 'Sačuvaj';
  static const String highlightDelete = 'Obriši istaknuto';
  static const String highlightDeleteBody =
      'Istaknuto će biti uklonjeno sa profila. Priče ostaju u tvojoj arhivi.';
  static const String highlightSaved = 'Istaknuto je sačuvano.';
  static const String highlightsEmpty = 'Još nema istaknutih priča.';
  static const String arrangeHighlights = 'Rasporedi';
  static const String arrangeTitle = 'Rasporedi istaknuto';
  static const String arrangeHint = 'Prevuci kartice da promeniš redosled.';
  static const String addToHighlight = 'Dodaj u istaknuto';
  static const String addedToHighlight = 'Dodato u istaknuto.';
  static const String removedFromHighlight = 'Uklonjeno iz istaknutog.';
  static const String deleteStory = 'Obriši priču';
  static const String deleteStoryBody =
      'Priča će biti obrisana i uklonjena iz svih istaknutih.';
  static const String delete = 'Obriši';
  static const String cancel = 'Otkaži';
  static const String edit = 'Uredi';
  static const String story = 'Priča';
  static String storyCount(int count) =>
      count == 1 ? '1 priča' : '$count priča';
  static const String like = 'Lajk';
  static const String comment = 'Komentar';
  static const String viewDog = 'Pogledaj psa';
  static const String shareAction = 'Podeli';
  static const String shareCopied = 'Tekst momenta je kopiran.';
  static const String commentsTitle = 'Komentari';
  static const String commentHint = 'Napiši komentar...';
  static const String send = 'Pošalji';
  static const String empty = 'Još nema momenata. Budi prvi!';
  static const String emptySubtitle =
      'Podeli šetnju, park ili smešan trenutak sa čoporom.';
  static const String loadError = 'Došlo je do greške. Pokušajte ponovo.';
  static const String retry = 'Pokušaj ponovo';
  static const String caption = 'Opis (opciono)';
  static const String location = 'Park / lokacija';
  static const String dog = 'Pas';
  static const String photo = 'Fotografija';
  static const String addPhoto = 'Dodaj fotografiju';
  static const String publish = 'Objavi';
  static const String publishError = 'Moment nije sačuvan. Pokušajte ponovo.';
  static const String dogRequired = 'Izaberite psa.';
  static const String photoRequired = 'Dodajte fotografiju.';
  static const String noDogs = 'Prvo dodajte profil psa.';
  static const String uploading = 'Otpremanje trenutka...';
  static const String successTitle = 'Uspešno objavljeno';
  static const String successBody =
      'Priča je objavljena i biće vidljiva 24h. Ako želiš da ostane duže, dodaj je u Istaknuto na profilu psa.';
  static const String errorTitle = 'Greška';
  static const String ok = 'U redu';
  static const String close = 'Zatvori';

  static String createErrorBody(String details) =>
      'Neuspešno objavljivanje momenta: $details';

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
