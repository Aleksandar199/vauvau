import '../../../core/l10n/l10n.dart';
import '../domain/story.dart';

abstract final class StoriesStrings {
  static String get barTitle => L10n.tr('Priče', 'Stories');
  static String get yourStory => L10n.tr('Vaša priča', 'Your story');
  static String get addStory => L10n.tr('Dodaj priču', 'Add story');
  static String get emptyNoFollows => L10n.tr(
        'Zapratite vlasnike pasa da biste ovde videli njihove priče.',
        'Follow dog owners to see their stories here.',
      );
  static String get emptyNoStories => L10n.tr(
        'Osobe koje pratite trenutno nemaju aktivnih priča.',
        'People you follow have no active stories right now.',
      );
  static String storiesCount(int count) =>
      L10n.tr('$count priče', '$count stories');

  // Audience (exact labels required by the product spec).
  static String audienceLabel(StoryAudience audience) => switch (audience) {
        StoryAudience.everyone => 'Svi korisnici',
        StoryAudience.followers => 'Moji pratioci',
        StoryAudience.following => 'Osobe koje ja pratim',
      };
  static String audienceHint(StoryAudience audience) => switch (audience) {
        StoryAudience.everyone => L10n.tr(
            'Svi prijavljeni korisnici VauVau-a (osim onih koje ste blokirali).',
            'Every signed-in VauVau user (except people you blocked).',
          ),
        StoryAudience.followers => L10n.tr(
            'Samo korisnici koji prate vas.',
            'Only people who follow you.',
          ),
        StoryAudience.following => L10n.tr(
            'Samo korisnici koje vi pratite.',
            'Only people you follow.',
          ),
      };
  static String get audienceTitle => L10n.tr('Ko može da vidi', 'Who can see');

  // Create
  static String get createTitle => L10n.tr('Nova priča', 'New story');
  static String get pickGallery => L10n.tr('Galerija', 'Gallery');
  static String get pickCamera => L10n.tr('Kamera', 'Camera');
  static String get pickPhoto =>
      L10n.tr('Izaberite fotografiju za priču', 'Choose a photo for your story');
  static String get captionHint =>
      L10n.tr('Dodajte opis (nije obavezno)', 'Add a caption (optional)');
  static String get publish => L10n.tr('Objavi priču', 'Publish story');
  static String get publishing => L10n.tr('Objavljivanje…', 'Publishing…');
  static String get retry => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get published => L10n.tr('Priča je objavljena.', 'Story published.');
  static String get publishFailed => L10n.tr(
        'Objavljivanje nije uspelo. Proverite internet i pokušajte ponovo.',
        'Publishing failed. Check your connection and try again.',
      );
  static String get expiresHint => L10n.tr(
        'Priča nestaje posle 24 sata.',
        'The story disappears after 24 hours.',
      );
  static String get videoNotSupported => L10n.tr(
        'Za sada priče podržavaju samo fotografije.',
        'Stories support photos only for now.',
      );

  // Viewer
  static String get close => L10n.tr('Zatvori', 'Close');
  static String get like => L10n.tr('Sviđa mi se', 'Like');
  static String get unlike => L10n.tr('Ukloni sviđanje', 'Unlike');
  static String get replyHint => L10n.tr('Odgovori na priču…', 'Reply to story…');
  static String get send => L10n.tr('Pošalji', 'Send');
  static String get replySent => L10n.tr(
        'Odgovor je poslat u Poruke.',
        'Reply sent to Messages.',
      );
  static String get replyFailed => L10n.tr(
        'Odgovor nije poslat. Pokušajte ponovo.',
        'Reply not sent. Try again.',
      );
  static String get unavailable =>
      L10n.tr('Priča više nije dostupna.', 'This story is no longer available.');
  static String get loadFailed =>
      L10n.tr('Fotografija nije učitana.', 'Photo did not load.');
  static String get delete => L10n.tr('Obriši priču', 'Delete story');
  static String get deleteBody => L10n.tr(
        'Priča, pregledi i sviđanja biće trajno obrisani.',
        'The story, its views and likes will be deleted.',
      );
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get confirmDelete => L10n.tr('Obriši', 'Delete');
  static String get viewers => L10n.tr('Pregledi', 'Viewers');
  static String get noViewers =>
      L10n.tr('Još niko nije pogledao priču.', 'Nobody has viewed it yet.');
  static String get viewersFailed =>
      L10n.tr('Pregledi nisu učitani.', 'Could not load viewers.');
  static String audienceBadge(StoryAudience audience) =>
      '${L10n.tr('Vidljivo', 'Visible to')}: ${audienceLabel(audience)}';

  // Highlights
  static String get addToHighlight =>
      L10n.tr('Dodaj u istaknuto', 'Add to highlight');
  static String get highlightPreparing =>
      L10n.tr('Pripremam priču…', 'Preparing story…');
  static String get highlightNeedsDog => L10n.tr(
        'Istaknute priče su na profilu psa – prvo dodajte psa.',
        'Highlights live on a dog profile – add a dog first.',
      );
  static String get highlightFailed => L10n.tr(
        'Priča nije sačuvana u istaknuto. Pokušajte ponovo.',
        'Could not save the story to a highlight. Try again.',
      );

  // Chat
  static String get replyToStory =>
      L10n.tr('Odgovor na priču', 'Replied to a story');

  // Notifications
  static String get storyLikeTitle =>
      L10n.tr('Novo sviđanje priče', 'Story like');
  static String storyLikeBody(String name) => L10n.tr(
        '$name: ❤️ vaša priča',
        '$name liked your story.',
      );
  static String get storyReplyTitle =>
      L10n.tr('Odgovor na priču', 'Story reply');
  static String storyReplyBody(String name, String text) =>
      '$name: $text';

  static String timeAgo(DateTime then, DateTime now) {
    final diff = now.difference(then);
    if (diff.inMinutes < 1) {
      return L10n.tr('upravo', 'just now');
    }
    if (diff.inHours < 1) {
      return L10n.tr('pre ${diff.inMinutes} min', '${diff.inMinutes} min ago');
    }
    return L10n.tr('pre ${diff.inHours} h', '${diff.inHours} h ago');
  }
}
