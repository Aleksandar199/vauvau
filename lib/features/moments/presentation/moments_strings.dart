import '../../../core/l10n/l10n.dart';

abstract final class MomentsStrings {
  static String get drawerItem => L10n.tr('📸 VauVau Moments', '📸 VauVau Moments');
  static String get title => L10n.tr('VauVau Moments', 'VauVau Moments');

  // --- Feed ------------------------------------------------------------------
  static String get tabForYou => L10n.tr('Za tebe', 'For you');
  static String get tabFollowing => L10n.tr('Pratim', 'Following');
  static String get tabNearby => L10n.tr('U blizini', 'Nearby');
  static String get newPost => L10n.tr('Nova objava', 'New post');
  static String get feedLoading => L10n.tr('Učitavanje objava...', 'Loading posts...');
  static String get emptyForYou => L10n.tr('Još nema objava', 'No posts yet');
  static String get emptyForYouSubtitle => L10n.tr(
        'Podeli šetnju, park ili smešan trenutak sa zajednicom. Objava ostaje dok je ne obrišeš.',
        'Share a walk, a park or a funny moment with the community. Posts stay until you delete them.',
      );
  static String get emptyFollowingNone => L10n.tr('Još nikog ne pratiš', 'You don\'t follow anyone yet');
  static String get emptyFollowingNoneSubtitle => L10n.tr(
        'Zaprati vlasnike u Otkrij ili sa njihovog profila i ovde ćeš videti njihove objave. Praćenje ne pravi meč.',
        'Follow owners in Discover or from their profile to see their posts here. Following is not a match.',
      );
  static String get emptyFollowing => L10n.tr('Nema novih objava', 'No posts yet');
  static String get emptyFollowingSubtitle => L10n.tr(
        'Osobe koje pratiš još nisu ništa objavile.',
        'People you follow haven\'t posted anything yet.',
      );
  static String get emptyNearbyNoCity => L10n.tr('Grad nije podešen', 'City not set');
  static String get emptyNearbyNoCitySubtitle => L10n.tr(
        'Izaberi svoj grad u Izmeni profil da bi video objave iz okoline.',
        'Pick your city in Edit profile to see posts from your area.',
      );
  static String emptyNearby(String city) =>
      L10n.tr('Još nema objava iz grada $city', 'No posts from $city yet');
  static String get emptyNearbySubtitle => L10n.tr(
        'Ovde su objave čiji je autor izabrao tvoj grad. Starije objave bez grada se ne prikazuju.',
        'Posts whose author picked your city show here. Older posts without a city are not listed.',
      );
  static String nearbyHeader(String city) =>
      L10n.tr('Objave iz grada $city', 'Posts from $city');
  static String get offline => L10n.tr(
        'Nema veze sa internetom – prikazane su sačuvane objave.',
        'No connection – showing saved posts.',
      );
  static String get feedError =>
      L10n.tr('Objave nisu učitane', 'Posts could not be loaded');
  static String get feedErrorSubtitle => L10n.tr(
        'Proveri vezu sa internetom i pokušaj ponovo.',
        'Check your connection and try again.',
      );
  static String get loadMoreError =>
      L10n.tr('Starije objave nisu učitane.', 'Older posts did not load.');
  static String get endOfFeed => L10n.tr('To je sve za sada 🐾', 'That\'s all for now 🐾');
  static String get signInRequired => L10n.tr('Morate biti prijavljeni.', 'You need to sign in.');
  static String get actionFailed => L10n.tr(
        'Radnja nije uspela. Pokušajte ponovo.',
        'That didn\'t work. Try again.',
      );

  // --- Post card -------------------------------------------------------------
  static String get like => L10n.tr('Lajk', 'Like');
  static String get unlike => L10n.tr('Ukloni lajk', 'Unlike');
  static String get comment => L10n.tr('Komentar', 'Comment');
  static String get viewDog => L10n.tr('Pogledaj psa', 'View dog');
  static String get openAuthor => L10n.tr('Profil autora', 'Author profile');
  static String get postOptions => L10n.tr('Opcije objave', 'Post options');
  static String get shareAction => L10n.tr('Podeli', 'Share');
  static String get shareCopied => L10n.tr(
        'Tekst objave je kopiran – nalepi ga gde želiš.',
        'Post text copied – paste it anywhere.',
      );
  static String shareText(String author, String caption) {
    final body = caption.trim().isEmpty ? '' : '„${caption.trim()}“ – ';
    return L10n.tr(
      '$body$author na VauVau Moments 🐾',
      '$body$author on VauVau Moments 🐾',
    );
  }

  static String get reportPost => L10n.tr('Prijavi objavu', 'Report post');
  static String get blockAuthor => L10n.tr('Blokiraj autora', 'Block author');
  static String get deletePost => L10n.tr('Obriši objavu', 'Delete post');
  static String get deletePostBody => L10n.tr(
        'Objava, njeni komentari i lajkovi biće trajno obrisani.',
        'The post, its comments and likes will be deleted permanently.',
      );
  static String get postDeleted => L10n.tr('Objava je obrisana.', 'Post deleted.');
  static String likesCount(int count) {
    if (L10n.isEnglish) {
      return count == 1 ? '1 like' : '$count likes';
    }
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return '$count sviđanje';
    }
    return '$count sviđanja';
  }

  static String viewAllComments(int count) => L10n.tr(
        'Pogledaj sve komentare ($count)',
        'View all comments ($count)',
      );
  static String withDog(String dog) => L10n.tr('sa psom $dog', 'with $dog');

  // --- Comments --------------------------------------------------------------
  static String get commentsTitle => L10n.tr('Komentari', 'Comments');
  static String get commentHint => L10n.tr('Napiši komentar...', 'Write a comment...');
  static String get noComments => L10n.tr(
        'Još nema komentara. Napiši prvi!',
        'No comments yet. Be the first!',
      );
  static String get reply => L10n.tr('Odgovori', 'Reply');
  static String replyingTo(String name) =>
      L10n.tr('Odgovaraš korisniku $name', 'Replying to $name');
  static String replyTo(String name) => L10n.tr('↪ $name', '↪ $name');
  static String get olderComments =>
      L10n.tr('Prikaži starije komentare', 'Show older comments');
  static String get deleteComment => L10n.tr('Obriši komentar', 'Delete comment');
  static String get commentNotSent => L10n.tr(
        'Komentar nije poslat. Pokušajte ponovo.',
        'Comment not sent. Try again.',
      );
  static String get send => L10n.tr('Pošalji', 'Send');

  // --- New post --------------------------------------------------------------
  static String get share => L10n.tr('Nova objava', 'New post');
  static String get newPostHint => L10n.tr(
        'Objava ostaje u Momentima dok je ne obrišeš. Za priču koja traje 24h koristi traku priča u Otkrij.',
        'Posts stay in Moments until you delete them. For a 24h story use the stories bar in Discover.',
      );
  static String get pickFromGallery => L10n.tr('Galerija', 'Gallery');
  static String get takePhoto => L10n.tr('Kamera', 'Camera');
  static String get changePhoto => L10n.tr('Promeni fotografiju', 'Change photo');
  static String get noDogOption => L10n.tr('Bez psa', 'No dog');
  static String get dogOptional => L10n.tr('Pas na objavi (opciono)', 'Dog in the post (optional)');
  static String get city => L10n.tr('Grad', 'City');
  static String get caption => L10n.tr('Opis (opciono)', 'Caption (optional)');
  static String get location => L10n.tr('Park / lokacija', 'Park / location');
  static String get customLocationHint =>
      L10n.tr('Unesi lokaciju po želji...', 'Enter a custom location...');
  static String get customLocationRequired => L10n.tr('Unesite lokaciju.', 'Enter a location.');
  static String get dog => L10n.tr('Pas', 'Dog');
  static String get photo => L10n.tr('Fotografija', 'Photo');
  static String get addPhoto => L10n.tr('Dodaj fotografiju', 'Add photo');
  static String get publish => L10n.tr('Objavi', 'Publish');
  static String get retryPublish => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get publishError =>
      L10n.tr('Objava nije sačuvana. Pokušajte ponovo.', 'Post was not saved. Try again.');
  static String get dogRequired => L10n.tr('Izaberite psa.', 'Select a dog.');
  static String get photoRequired => L10n.tr('Dodajte fotografiju.', 'Add a photo.');
  static String get noDogs => L10n.tr('Prvo dodajte profil psa.', 'Add a dog profile first.');
  static String get uploading => L10n.tr('Otpremanje fotografije...', 'Uploading photo...');
  static String get publishing => L10n.tr('Objavljivanje...', 'Publishing...');
  static String get published => L10n.tr('Objava je podeljena 🐾', 'Post shared 🐾');
  static String get successTitle => L10n.tr('Uspešno objavljeno', 'Published successfully');
  static String get successBody => L10n.tr(
        'Objava je u Momentima i ostaje dok je ne obrišeš.',
        'Your post is in Moments and stays until you delete it.',
      );
  static String get errorTitle => L10n.tr('Greška', 'Error');
  static String get ok => L10n.tr('U redu', 'OK');
  static String get close => L10n.tr('Zatvori', 'Close');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get delete => L10n.tr('Obriši', 'Delete');
  static String get edit => L10n.tr('Uredi', 'Edit');
  static String get retry => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get loadError =>
      L10n.tr('Došlo je do greške. Pokušajte ponovo.', 'Something went wrong. Try again.');

  static String createErrorBody(String details) => L10n.tr(
        'Neuspešno objavljivanje: $details',
        'Failed to publish: $details',
      );

  // --- Legacy story highlights (dog profile) --------------------------------
  // Old moments were shown as 24h stories; highlights still play them.
  static String get yourStory => L10n.tr('Tvoja priča', 'Your story');
  static String get activeStories => L10n.tr('Priče iz poslednja 24h', 'Stories from the last 24h');
  static String get storiesHint => L10n.tr(
        'Istakni svoje priče i objave na profilu psa – ostaju koliko god želiš.',
        'Highlight your stories and posts on your dog\'s profile – they stay as long as you want.',
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
  static String get highlightPickStories => L10n.tr('Izaberi priče i objave', 'Choose stories and posts');
  static String get highlightPickRequired => L10n.tr('Izaberi bar jednu priču ili objavu.', 'Pick at least one story or post.');
  static String get highlightCover => L10n.tr('Naslovna slika', 'Cover image');
  static String get highlightArchiveEmpty => L10n.tr(
        'Još nemaš priča ni objava sa ovim psom. Otvori svoju priču u Otkrij i izaberi „Dodaj u istaknuto“.',
        'No stories or posts with this dog yet. Open your story in Discover and tap “Add to highlight”.',
      );
  static String get highlightSave => L10n.tr('Sačuvaj', 'Save');
  static String get highlightDelete => L10n.tr('Obriši istaknuto', 'Delete highlight');
  static String get highlightDeleteBody => L10n.tr(
        'Istaknuto će biti uklonjeno sa profila. Priče i objave ostaju u tvojoj arhivi.',
        'The highlight will be removed from the profile. Stories and posts stay in your archive.',
      );
  static String get highlightSaved => L10n.tr('Istaknuto je sačuvano.', 'Highlight saved.');
  static String get highlightsEmpty => L10n.tr('Još nema istaknutih priča.', 'No highlights yet.');
  static String get arrangeHighlights => L10n.tr('Rasporedi', 'Arrange');
  static String get arrangeTitle => L10n.tr('Rasporedi istaknuto', 'Arrange highlights');
  static String get arrangeHint => L10n.tr('Prevuci kartice da promeniš redosled.', 'Drag cards to reorder.');
  static String get addToHighlight => L10n.tr('Dodaj u istaknuto', 'Add to highlight');
  static String get addedToHighlight => L10n.tr('Dodato u istaknuto.', 'Added to highlight.');
  static String get removedFromHighlight => L10n.tr('Uklonjeno iz istaknutog.', 'Removed from highlight.');
  static String get deleteStory => L10n.tr('Obriši momenat', 'Delete moment');
  static String get deleteStoryBody => L10n.tr(
        'Momenat će biti obrisan i uklonjen iz svih istaknutih.',
        'The moment will be deleted and removed from all highlights.',
      );
  static String get story => L10n.tr('Priča', 'Story');

  static String storyCount(int count) {
    if (L10n.isEnglish) {
      return count == 1 ? '1 story' : '$count stories';
    }
    return count == 1 ? '1 priča' : '$count priča';
  }

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
    return '${value.day}.${value.month}.${value.year == now.year ? '' : '${value.year}.'}';
  }
}
