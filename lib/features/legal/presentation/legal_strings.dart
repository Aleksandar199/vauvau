import '../../../core/l10n/l10n.dart';

abstract final class LegalStrings {
  static String get sectionTitle =>
      L10n.tr('Privatnost i uslovi', 'Privacy & terms');

  static String get privacyPolicy =>
      L10n.tr('Politika privatnosti', 'Privacy Policy');

  static String get termsOfService =>
      L10n.tr('Uslovi korišćenja', 'Terms of Service');

  static String get privacySubtitle => L10n.tr(
        'Kako prikupljamo i štitimo vaše podatke',
        'How we collect and protect your data',
      );

  static String get termsSubtitle => L10n.tr(
        'Pravila korišćenja VauVau aplikacije',
        'Rules for using the VauVau app',
      );

  static String get openInBrowser =>
      L10n.tr('Otvori u pregledaču', 'Open in browser');

  static String get lastUpdated => L10n.tr(
        'Poslednje ažuriranje: 12. oktobar 2026.',
        'Last updated: October 12, 2026.',
      );

  static String get registerConsent => L10n.tr(
        'Kreiranjem naloga prihvatate Politiku privatnosti i Uslove korišćenja.',
        'By creating an account you accept the Privacy Policy and Terms of Service.',
      );

  static String get linkError => L10n.tr(
        'Link nije moguće otvoriti. Pokušajte ponovo.',
        'Could not open the link. Please try again.',
      );

  static String get contactUs => L10n.tr(
        'Pitanja o privatnosti: vauvau.app@gmail.com',
        'Privacy questions: vauvau.app@gmail.com',
      );
}
