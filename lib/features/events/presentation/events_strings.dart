import '../../../core/l10n/l10n.dart';

abstract final class EventsStrings {
  static String get drawerItem => L10n.tr('📅 Događaji i šetnje', '📅 Events & walks');
  static String get title => L10n.tr('VauVau Događaji', 'VauVau Events');
  static String get banner => L10n.tr(
        '📅 Pridruži se lokalnim grupnim šetnjama i druženjima!',
        '📅 Join local group walks and meetups!',
      );
  static String get organize => L10n.tr('📅 Organizuj šetnju', '📅 Organize a walk');
  static String get badge => L10n.tr('GRUPNA ŠETNJA', 'GROUP WALK');
  static String get filterAll => L10n.tr('Svi', 'All');
  static String get filterUpcoming => L10n.tr('Predstojeći', 'Upcoming');
  static String get filterJoined => L10n.tr('Moje', 'Mine');
  static String get join => L10n.tr('Pridruži se', 'Join');
  static String get openChat => L10n.tr('Otvori chat', 'Open chat');
  static String get createTitle => L10n.tr('Organizuj šetnju', 'Organize a walk');
  static String get fieldTitle => L10n.tr('Naslov', 'Title');
  static String get fieldLocation => L10n.tr('Lokacija', 'Location');
  static String get fieldCity => L10n.tr('Grad', 'City');
  static String get filterAllCities => L10n.tr('Svi gradovi', 'All cities');
  static String get emptyAll =>
      L10n.tr('Nema događaja za ovaj filter.', 'No events match this filter.');
  static String emptyCity(String city) => L10n.tr(
        'Još nema događaja u gradu $city. Organizuj prvu šetnju!',
        'No events in $city yet. Organize the first walk!',
      );
  static String get customLocationHint =>
      L10n.tr('Unesi lokaciju po želji...', 'Enter a custom location...');
  static String get customLocationRequired => L10n.tr('Unesite lokaciju.', 'Enter a location.');
  static String get fieldWhen => L10n.tr('Datum i vreme šetnje', 'Walk date and time');
  static String get fieldDate => L10n.tr('Datum šetnje', 'Walk date');
  static String get fieldTime => L10n.tr('Vreme šetnje', 'Walk time');
  static String get pickDate => L10n.tr('Izaberi datum', 'Pick date');
  static String get pickTime => L10n.tr('Izaberi vreme', 'Pick time');
  static String get fieldDescription => L10n.tr('Opis', 'Description');
  static String get fieldPhoto => L10n.tr('Fotografija (opciono)', 'Photo (optional)');
  static String get save => L10n.tr('Objavi šetnju', 'Publish walk');
  static String get titleRequired => L10n.tr('Unesite naslov.', 'Enter a title.');
  static String get descriptionRequired => L10n.tr('Unesite opis.', 'Enter a description.');
  static String get pastDateError => L10n.tr(
        'Ne možeš da zakažeš šetnju za prošlo vreme.',
        'You cannot schedule a walk in the past.',
      );
  static String get publishError =>
      L10n.tr('Šetnja nije sačuvana. Pokušajte ponovo.', 'Walk was not saved. Try again.');
  static String get addPhoto => L10n.tr('Dodaj fotografiju', 'Add photo');
  static String get mapBanner => L10n.tr('📅 Događaji i šetnje', '📅 Events & walks');
  static String get successTitle => L10n.tr('Uspešno kreirano', 'Created successfully');
  static String get successBody => L10n.tr(
        'Vaš događaj/šetnja je uspešno kreiran i objavljen u zajednici!',
        'Your event/walk was created and published to the community!',
      );
  static String get errorTitle => L10n.tr('Greška', 'Error');
  static String get ok => L10n.tr('U redu', 'OK');
  static String get close => L10n.tr('Zatvori', 'Close');

  static String createErrorBody(String details) => L10n.tr(
        'Neuspešno kreiranje događaja: $details',
        'Failed to create event: $details',
      );

  static List<String> get weekdays => L10n.isEnglish
      ? [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ]
      : [
          'Ponedeljak',
          'Utorak',
          'Sreda',
          'Četvrtak',
          'Petak',
          'Subota',
          'Nedelja',
        ];

  static String dateOnly(DateTime value) =>
      '${value.day}.${value.month}.${value.year}.';

  static String timeOnly(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  /// Full walk stamp, e.g. "Ponedeljak, 9.10.2026. · 17:00".
  static String when(DateTime value) {
    final day = weekdays[value.weekday - 1];
    return '$day, ${dateOnly(value)} · ${timeOnly(value)}';
  }

  static String cardMeta(DateTime dateTime, String location) =>
      '${when(dateTime)} · $location';

  static String interested(int count) => L10n.isEnglish
      ? '$count owners interested'
      : '$count vlasnika zainteresovano';

  static String timeAgo(DateTime value, [DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(value);
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
    return when(value);
  }
}
