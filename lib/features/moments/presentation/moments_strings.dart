import '../../../core/l10n/l10n.dart';

abstract final class MomentsStrings {
  static String get drawerItem => L10n.tr('📸 VauVau Moments', '📸 VauVau Moments');
  static String get title => L10n.tr('VauVau Moments', 'VauVau Moments');
  static String get share => L10n.tr('Dodaj priču', 'Add story');
  static String get city => L10n.tr('Grad', 'City');
  static String get yourStory => L10n.tr('Tvoja priča', 'Your story');
  static String get activeStories => L10n.tr('Priče iz poslednja 24h', 'Stories from the last 24h');
  static String get storiesHint => L10n.tr(
        'Priče nestaju posle 24h. Sačuvaj ih u Istaknuto i ostaće na profilu psa koliko god želiš.',
        'Stories disappear after 24h. Save them to Highlights to keep them on your dog\'s profile as long as you want.',
      );
  static String get noStories => L10n.tr('Nema aktivnih priča', 'No active stories');
  static String get noStoriesSubtitle => L10n.tr(
        'Budi prvi danas — podeli šetnju, park ili smešan trenutak.',
        'Be the first today — share a walk, park, or funny moment.',
      );
  static String get highlights => L10n.tr('Istaknute priče', 'Highlights');
  static String get newHighlight => L10n.tr('Novo', 'New');
  static String get newHighlightTitle => L10n.tr('Novo istaknuto', 'New highlight');
  static String get editHighlightTitle => L10n.tr('Uredi istaknuto', 'Edit highlight');
  static String get highlightName =>
      L10n.tr('Naziv (npr. Šetnje, Park, Plaža)', 'Name (e.g. Walks, Park, Beach)');
  static String get highlightNameRequired => L10n.tr('Unesi naziv.', 'Enter a name.');
  static String get highlightPickStories => L10n.tr('Izaberi priče', 'Choose stories');
  static String get highlightPickRequired => L10n.tr('Izaberi bar jednu priču.', 'Pick at least one story.');
  static String get highlightCover => L10n.tr('Naslovna slika', 'Cover image');
  static String get highlightArchiveEmpty => L10n.tr(
        'Još nemaš priča za ovog psa. Dodaj priču u Momentima pa je istakni ovde.',
        'No stories for this dog yet. Add a story in Moments, then highlight it here.',
      );
  static String get highlightSave => L10n.tr('Sačuvaj', 'Save');
  static String get highlightDelete => L10n.tr('Obriši istaknuto', 'Delete highlight');
  static String get highlightDeleteBody => L10n.tr(
        'Istaknuto će biti uklonjeno sa profila. Priče ostaju u tvojoj arhivi.',
        'The highlight will be removed from the profile. Stories stay in your archive.',
      );
  static String get highlightSaved => L10n.tr('Istaknuto je sačuvano.', 'Highlight saved.');
  static String get highlightsEmpty => L10n.tr('Još nema istaknutih priča.', 'No highlights yet.');
  static String get arrangeHighlights => L10n.tr('Rasporedi', 'Arrange');
  static String get arrangeTitle => L10n.tr('Rasporedi istaknuto', 'Arrange highlights');
  static String get arrangeHint => L10n.tr('Prevuci kartice da promeniš redosled.', 'Drag cards to reorder.');
  static String get addToHighlight => L10n.tr('Dodaj u istaknuto', 'Add to highlight');
  static String get addedToHighlight => L10n.tr('Dodato u istaknuto.', 'Added to highlight.');
  static String get removedFromHighlight => L10n.tr('Uklonjeno iz istaknutog.', 'Removed from highlight.');
  static String get deleteStory => L10n.tr('Obriši priču', 'Delete story');
  static String get deleteStoryBody => L10n.tr(
        'Priča će biti obrisana i uklonjena iz svih istaknutih.',
        'The story will be deleted and removed from all highlights.',
      );
  static String get delete => L10n.tr('Obriši', 'Delete');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get edit => L10n.tr('Uredi', 'Edit');
  static String get story => L10n.tr('Priča', 'Story');

  static String storyCount(int count) {
    if (L10n.isEnglish) {
      return count == 1 ? '1 story' : '$count stories';
    }
    return count == 1 ? '1 priča' : '$count priča';
  }

  static String get like => L10n.tr('Lajk', 'Like');
  static String get comment => L10n.tr('Komentar', 'Comment');
  static String get viewDog => L10n.tr('Pogledaj psa', 'View dog');
  static String get shareAction => L10n.tr('Podeli', 'Share');
  static String get shareCopied => L10n.tr('Tekst momenta je kopiran.', 'Moment text copied.');
  static String get commentsTitle => L10n.tr('Komentari', 'Comments');
  static String get commentHint => L10n.tr('Napiši komentar...', 'Write a comment...');
  static String get send => L10n.tr('Pošalji', 'Send');
  static String get empty => L10n.tr('Još nema momenata. Budi prvi!', 'No moments yet. Be the first!');
  static String get emptySubtitle => L10n.tr(
        'Podeli šetnju, park ili smešan trenutak sa čoporom.',
        'Share a walk, park, or funny moment with the pack.',
      );
  static String get loadError =>
      L10n.tr('Došlo je do greške. Pokušajte ponovo.', 'Something went wrong. Try again.');
  static String get retry => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get caption => L10n.tr('Opis (opciono)', 'Caption (optional)');
  static String get location => L10n.tr('Park / lokacija', 'Park / location');
  static String get customLocationHint =>
      L10n.tr('Unesi lokaciju po želji...', 'Enter a custom location...');
  static String get customLocationRequired => L10n.tr('Unesite lokaciju.', 'Enter a location.');
  static String get dog => L10n.tr('Pas', 'Dog');
  static String get photo => L10n.tr('Fotografija', 'Photo');
  static String get addPhoto => L10n.tr('Dodaj fotografiju', 'Add photo');
  static String get publish => L10n.tr('Objavi', 'Publish');
  static String get publishError =>
      L10n.tr('Moment nije sačuvan. Pokušajte ponovo.', 'Moment was not saved. Try again.');
  static String get dogRequired => L10n.tr('Izaberite psa.', 'Select a dog.');
  static String get photoRequired => L10n.tr('Dodajte fotografiju.', 'Add a photo.');
  static String get noDogs => L10n.tr('Prvo dodajte profil psa.', 'Add a dog profile first.');
  static String get uploading => L10n.tr('Otpremanje trenutka...', 'Uploading moment...');
  static String get successTitle => L10n.tr('Uspešno objavljeno', 'Published successfully');
  static String get successBody => L10n.tr(
        'Priča je objavljena i biće vidljiva 24h. Ako želiš da ostane duže, dodaj je u Istaknuto na profilu psa.',
        'Your story is live for 24h. To keep it longer, add it to Highlights on your dog\'s profile.',
      );
  static String get errorTitle => L10n.tr('Greška', 'Error');
  static String get ok => L10n.tr('U redu', 'OK');
  static String get close => L10n.tr('Zatvori', 'Close');

  static String createErrorBody(String details) => L10n.tr(
        'Neuspešno objavljivanje momenta: $details',
        'Failed to publish moment: $details',
      );

  static String locationPin(String name) => '📍 $name';

  static String timeAgo(DateTime value, DateTime now) {
    final diff = now.difference(value);
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
    return '${value.day}.${value.month}.';
  }
}
