import '../l10n/l10n.dart';

abstract final class NetworkStrings {
  static String get offlineTitle =>
      L10n.tr('Nema internet veze', 'No internet connection');
  static String get offlineBody => L10n.tr(
        'VauVau treba internet da bi radio. Uključi Wi-Fi ili mobilne '
            'podatke pa pokušaj ponovo.',
        'VauVau needs the internet to work. Turn on Wi-Fi or mobile data '
            'and try again.',
      );
  static String get offlineAuto => L10n.tr(
        'Čim se veza vrati, aplikacija se otvara sama.',
        'The app opens by itself as soon as you are back online.',
      );
  static String get retry => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get checking => L10n.tr('Proveravam…', 'Checking…');
  static String get walkOffline => L10n.tr(
        'Nema interneta – šetnja se i dalje meri i sačuvaće se kad se vratite online.',
        'No internet – the walk is still measured and is saved once you are back online.',
      );
}
