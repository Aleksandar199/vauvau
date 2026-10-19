import '../../../core/l10n/l10n.dart';

abstract final class ChatStrings {
  /// Chat message sent by "Pridruži se šetnji" on the map.
  static String joinWalkRequest(String myDog, String walkerDog) {
    final me = myDog.isEmpty ? '' : ' sa psom $myDog';
    final meEn = myDog.isEmpty ? '' : ' with $myDog';
    final target = walkerDog.isEmpty ? '' : ' sa psom $walkerDog';
    final targetEn = walkerDog.isEmpty ? '' : ' with $walkerDog';
    return L10n.tr(
      '🐾 Zdravo! Na mapi vidim da ste u šetnji$target. Mogu li da vam se '
          'pridružim$me? Gde ste trenutno?',
      "🐾 Hi! I see on the map that you're out walking$targetEn. Can I join "
          'you$meEn? Where are you now?',
    );
  }

  static String get tabLabel => L10n.tr('Poruke', 'Messages');
  static String get title => L10n.tr('Poruke', 'Messages');
  static String get newMatches => L10n.tr('Novi mečevi', 'New matches');
  static String get newLikes => L10n.tr('Novi lajkovi 🐾', 'New likes 🐾');
  static String get conversations =>
      L10n.tr('Aktivna ćaskanja', 'Active chats');
  static String get groupBadge => L10n.tr('👥 Grupa', '👥 Group');
  static String get eventBadge => L10n.tr('📅 Šetnja', '📅 Walk');
  static String get composeHint =>
      L10n.tr('Napiši poruku...', 'Write a message...');
  static String get send => L10n.tr('Pošalji', 'Send');
  static String get emptyTitle =>
      L10n.tr('Nemate aktivnih poruka.', 'You have no active messages.');
  static String get emptySubtitle => L10n.tr(
        'Započnite swipe i pronađite druga!',
        'Start swiping and find new friends!',
      );
  static String get findFriends =>
      L10n.tr('Pronađi društvo', 'Find friends');
  static String get missingChat =>
      L10n.tr('Razgovor nije pronađen.', 'Conversation not found.');
  /// App bar subtitle under the dog/owner name — real profile info, not a fake
  /// “on a walk nearby” default.
  static String peerSubtitle({
    required String breed,
    required String location,
    bool walking = false,
    bool isNewMatch = false,
  }) {
    if (walking) {
      return L10n.tr('U šetnji', 'On a walk');
    }
    final parts = <String>[
      if (breed.trim().isNotEmpty) breed.trim(),
      if (location.trim().isNotEmpty) location.trim(),
    ];
    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }
    if (isNewMatch) {
      return L10n.tr('Novi meč', 'New match');
    }
    return L10n.tr('Razgovor', 'Conversation');
  }
  static String get searchHint => L10n.tr(
        'Pretraži po psu ili vlasniku...',
        'Search by dog or owner...',
      );
  static String get noSearchResults => L10n.tr(
        'Nema razgovora za tu pretragu.',
        'No conversations match that search.',
      );
  static String get attach => L10n.tr('Dodatne opcije', 'More options');
  static String get scheduleWalk =>
      L10n.tr('Zakaži šetnju 🐕', 'Schedule a walk 🐕');
  static String get sendLocation =>
      L10n.tr('Pošalji lokaciju 📍', 'Send location 📍');
  static String get addPhoto => L10n.tr('Fotografija', 'Photo');
  static String get gallery => L10n.tr('Galerija', 'Gallery');
  static String get camera => L10n.tr('Kamera', 'Camera');
  static String get photoFailed => L10n.tr(
        'Fotografija nije poslata. Pokušajte ponovo.',
        'Photo was not sent. Try again.',
      );
  static String get sendFailed => L10n.tr(
        'Poruka nije poslata. Pokušajte ponovo.',
        'Message was not sent. Try again.',
      );
  static String get walkInviteFailed => L10n.tr(
        'Poziv na šetnju nije poslat. Pokušajte ponovo.',
        'Walk invite was not sent. Try again.',
      );
  static String get locationFailed => L10n.tr(
        'Lokacija nije poslata. Pokušajte ponovo.',
        'Location was not sent. Try again.',
      );
  static String get walkRespondFailed => L10n.tr(
        'Odgovor nije sačuvan. Pokušajte ponovo.',
        'Reply was not saved. Try again.',
      );
  static String get walkSheetTitle => L10n.tr(
        'Zakaži zajedničku šetnju',
        'Schedule a group walk',
      );
  static String get walkDate => L10n.tr('Datum', 'Date');
  static String get walkTime => L10n.tr('Vreme', 'Time');
  static String get walkLocation => L10n.tr('Lokacija', 'Location');
  static String get walkCustomLocationHint => L10n.tr(
        'Ili unesi svoju lokaciju...',
        'Or enter your own location...',
      );
  static String get sendInvite => L10n.tr('Pošalji poziv', 'Send invite');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get accept => L10n.tr('Prihvati', 'Accept');
  static String get decline => L10n.tr('Odbij', 'Decline');
  static String get walkPending => L10n.tr('Čeka odgovor', 'Awaiting reply');
  static String get walkAccepted => L10n.tr('Dogovoreno', 'Confirmed');
  static String get walkDeclined => L10n.tr('Odbijeno', 'Declined');
  static String get walkInviteTitle =>
      L10n.tr('Poziv na šetnju', 'Walk invite');

  static String walkAcceptedCount(int count) {
    if (L10n.isEnglish) {
      if (count <= 0) {
        return 'No one has accepted yet';
      }
      if (count == 1) {
        return 'Accepted: 1';
      }
      return 'Accepted: $count';
    }
    if (count <= 0) {
      return 'Još niko nije prihvatio';
    }
    if (count == 1) {
      return 'Prihvatilo: 1';
    }
    return 'Prihvatilo: $count';
  }

  static String get locationPinTitle => L10n.tr('Lokacija', 'Location');
  static String get scheduledWalks =>
      L10n.tr('Zakazane šetnje', 'Scheduled walks');
  static String get pickDate => L10n.tr('Izaberi datum', 'Pick date');
  static String get pickTime => L10n.tr('Izaberi vreme', 'Pick time');
  static String get walkTimeInPast => L10n.tr(
        'Ne možeš da zakažeš šetnju za prošlo vreme.',
        'You cannot schedule a walk in the past.',
      );
}
