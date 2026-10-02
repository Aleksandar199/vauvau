abstract final class ModerationStrings {
  static const String reportAction = 'Prijavi neprikladan sadržaj';
  static const String reportUser = 'Prijavi korisnika';
  static const String blockUser = 'Blokiraj korisnika';
  static const String reportTitle = 'Prijava sadržaja';
  static const String reportIntro = 'Izaberite razlog prijave.';
  static const String reportDetails = 'Detalji (opciono)';
  static const String reportDetailsHint = 'Kratko opišite problem';
  static const String reportConfirm = 'Pošalji prijavu';
  static const String reportThanks =
      'Prijava je uspešno poslata administratoru na pregled.';
  static const String reportFailed = 'Prijava nije poslata. Pokušajte ponovo.';
  static const String cancel = 'Otkaži';

  static const List<String> reasons = [
    'Spam / Lažno predstavljanje',
    'Uvredljiv sadržaj / Govor mržnje',
    'Nezakonite aktivnosti',
    'Drugo',
  ];

  static const List<String> dogReasons = [
    'Netačne informacije',
    'Neprimerene slike/sadržaj',
    'Lažni profil',
    'Drugo',
  ];

  static const String blockTitle = 'Blokirati korisnika?';
  static const String blockBody =
      'Da li ste sigurni da želite da blokirate ovog korisnika? '
      'Nećete više videti njegove objave ni poruke.';
  static const String blockConfirm = 'Blokiraj';
  static const String blockDone = 'Korisnik je blokiran.';
  static const String blockFailed =
      'Blokiranje nije uspelo. Pokušajte ponovo.';
  static const String blockUnavailable =
      'Korisnik nije dostupan za blokiranje.';
}
