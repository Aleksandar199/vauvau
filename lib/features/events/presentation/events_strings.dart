abstract final class EventsStrings {
  static const String drawerItem = '📅 Događaji i šetnje';
  static const String title = 'VauVau Događaji';
  static const String banner =
      '📅 Pridruži se lokalnim grupnim šetnjama i druženjima!';
  static const String organize = '📅 Organizuj šetnju';
  static const String badge = 'GRUPNA ŠETNJA';
  static const String filterAll = 'Svi';
  static const String filterUpcoming = 'Predstojeći';
  static const String filterJoined = 'Moje';
  static const String join = 'Pridruži se';
  static const String openChat = 'Otvori chat';
  static const String createTitle = 'Organizuj šetnju';
  static const String fieldTitle = 'Naslov';
  static const String fieldLocation = 'Lokacija';
  static const String customLocationHint = 'Unesi lokaciju po želji...';
  static const String customLocationRequired = 'Unesite lokaciju.';
  static const String fieldWhen = 'Datum i vreme';
  static const String fieldDescription = 'Opis';
  static const String fieldPhoto = 'Fotografija (opciono)';
  static const String save = 'Objavi šetnju';
  static const String titleRequired = 'Unesite naslov.';
  static const String descriptionRequired = 'Unesite opis.';
  static const String publishError = 'Šetnja nije sačuvana. Pokušajte ponovo.';
  static const String addPhoto = 'Dodaj fotografiju';
  static const String mapBanner = '📅 Događaji i šetnje';
  static const String successTitle = 'Uspešno kreirano';
  static const String successBody =
      'Vaš događaj/šetnja je uspešno kreiran i objavljen u zajednici!';
  static const String errorTitle = 'Greška';
  static const String ok = 'U redu';
  static const String close = 'Zatvori';

  static String createErrorBody(String details) =>
      'Neuspešno kreiranje događaja: $details';

  static const List<String> weekdays = [
    'Ponedeljak',
    'Utorak',
    'Sreda',
    'Četvrtak',
    'Petak',
    'Subota',
    'Nedelja',
  ];

  static String when(DateTime value) {
    final day = weekdays[value.weekday - 1];
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$day $time';
  }

  static String cardMeta(DateTime dateTime, String location) =>
      '${when(dateTime)} · $location';

  static String interested(int count) => '$count vlasnika zainteresovano';

  static String timeAgo(DateTime value, [DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(value);
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
    return when(value);
  }
}
