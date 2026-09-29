abstract final class EventsStrings {
  static const String drawerItem = '📅 Događaji i šetnje';
  static const String title = 'VauVau Događaji';
  static const String banner =
      '📅 Pridruži se lokalnim grupnim šetnjama i druženjima!';
  static const String organize = '📅 Organizuj šetnju';
  static const String badge = '🐕 Grupna šetnja';
  static const String join = '+ Pridruži se';
  static const String openChat = '💬 Otvori chat šetnje';
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
      '📅 ${when(dateTime)} | 📍 $location';

  static String interested(int count) => '👥 $count vlasnika zainteresovano';
}
