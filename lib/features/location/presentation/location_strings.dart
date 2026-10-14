import '../../../core/l10n/l10n.dart';

abstract final class LocationStrings {
  static String get disclosureTitle => L10n.tr(
        'Upotreba lokacije',
        'Location use',
      );

  static String get disclosureBody => L10n.tr(
        'Tokom aktivne šetnje VauVau prati rutu preko GPS-a i prikazuje trajno obaveštenje da praćenje ostane pouzdano dok traje šetnja.',
        'During an active walk, VauVau tracks your route with GPS and shows a persistent notification so tracking stays reliable for the walk.',
      );

  static String get disclosureForegroundNote => L10n.tr(
        'Lokaciju koristimo i dok je aplikacija otvorena, da prikažemo pse u blizini i status „U šetnji“ na mapi. Ne tražimo „uvek dozvoli“ pristup u pozadini.',
        'We also use location while the app is open to show nearby dogs and “On a walk” status on the map. We do not request “Allow all the time” background access.',
      );

  static String get disclosureContinue =>
      L10n.tr('Nastavi', 'Continue');

  static String get disclosureDecline =>
      L10n.tr('Ne sada', 'Not now');
}
