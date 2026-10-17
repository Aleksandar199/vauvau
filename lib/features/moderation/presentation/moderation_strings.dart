import '../../../core/l10n/l10n.dart';

abstract final class ModerationStrings {
  static String get reportAction =>
      L10n.tr('Prijavi neprikladan sadržaj', 'Report inappropriate content');
  static String get reportUser => L10n.tr('Prijavi korisnika', 'Report user');
  static String get blockUser => L10n.tr('Blokiraj korisnika', 'Block user');
  static String get reportTitle => L10n.tr('Prijava sadržaja', 'Report content');
  static String get reportIntro => L10n.tr('Izaberite razlog prijave.', 'Choose a reason for your report.');
  static String get reportDetails => L10n.tr('Detalji (opciono)', 'Details (optional)');
  static String get reportDetailsHint => L10n.tr('Kratko opišite problem', 'Briefly describe the issue');
  static String get reportConfirm => L10n.tr('Pošalji prijavu', 'Submit report');
  static String get reportThanks => L10n.tr(
        'Prijava je uspešno poslata administratoru na pregled.',
        'Your report was sent to the admin for review.',
      );
  static String get reportFailed =>
      L10n.tr('Prijava nije poslata. Pokušajte ponovo.', 'Report was not sent. Try again.');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');

  static List<String> get reasons => [
        L10n.tr('Spam / Lažno predstavljanje', 'Spam / Impersonation'),
        L10n.tr('Uvredljiv sadržaj / Govor mržnje', 'Offensive content / Hate speech'),
        L10n.tr('Nezakonite aktivnosti', 'Illegal activity'),
        L10n.tr('Drugo', 'Other'),
      ];

  static List<String> get dogReasons => [
        L10n.tr('Netačne informacije', 'Inaccurate information'),
        L10n.tr('Neprimerene slike/sadržaj', 'Inappropriate photos/content'),
        L10n.tr('Lažni profil', 'Fake profile'),
        L10n.tr('Drugo', 'Other'),
      ];

  static String get blockTitle => L10n.tr('Blokirati korisnika?', 'Block this user?');
  static String get blockBody => L10n.tr(
        'Da li ste sigurni da želite da blokirate ovog korisnika? '
        'Nećete više videti njegove objave ni poruke.',
        'Are you sure you want to block this user? '
        'You will no longer see their posts or messages.',
      );
  static String get blockConfirm => L10n.tr('Blokiraj', 'Block');
  static String get blockDone => L10n.tr('Korisnik je blokiran.', 'User blocked.');
  static String get blockFailed =>
      L10n.tr('Blokiranje nije uspelo. Pokušajte ponovo.', 'Blocking failed. Try again.');
  static String get blockUnavailable =>
      L10n.tr('Korisnik nije dostupan za blokiranje.', 'User is not available to block.');

  // Blocked users screen
  static String get blockedUsers => L10n.tr('Blokirani korisnici', 'Blocked users');
  static String get blockedUsersHint => L10n.tr(
        'Pogledajte koga ste blokirali i odblokirajte ga.',
        'See who you blocked and unblock them.',
      );
  static String get blockedEmpty =>
      L10n.tr('Niste blokirali nijednog korisnika.', 'You have not blocked anyone.');
  static String get unblock => L10n.tr('Odblokiraj', 'Unblock');
  static String get unblockTitle =>
      L10n.tr('Odblokirati korisnika?', 'Unblock this user?');
  static String unblockBody(String name) => L10n.tr(
        '$name će ponovo moći da vidi vaše objave i da vam piše. '
            'Praćenje se ne vraća automatski.',
        '$name will be able to see your posts and message you again. '
            'Following is not restored automatically.',
      );
  static String get unblockDone =>
      L10n.tr('Korisnik je odblokiran.', 'User unblocked.');
  static String get unblockFailed => L10n.tr(
        'Odblokiranje nije uspelo. Pokušajte ponovo.',
        'Unblocking failed. Try again.',
      );
  static String get unknownUser => L10n.tr('Korisnik', 'User');
}
