import '../../../core/l10n/l10n.dart';

abstract final class AppUpdateStrings {
  static String get title =>
      L10n.tr('Nova verzija je dostupna', 'New version available');
  static String get requiredTitle =>
      L10n.tr('Potrebno je ažuriranje', 'Update required');
  static String get body => L10n.tr(
        'Ažurirajte VauVau u Google Play prodavnici da biste dobili najnovije funkcije i popravke.',
        'Update VauVau in Google Play to get the latest features and fixes.',
      );
  static String get requiredBody => L10n.tr(
        'Ova verzija aplikacije više nije podržana. Ažurirajte VauVau u Google Play prodavnici da biste nastavili.',
        'This version is no longer supported. Update VauVau in Google Play to continue.',
      );
  static String get update => L10n.tr('Ažuriraj', 'Update');
  static String get later => L10n.tr('Kasnije', 'Later');
}
