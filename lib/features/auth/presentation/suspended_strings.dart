import '../../../core/l10n/l10n.dart';

abstract final class SuspendedStrings {
  static String get title =>
      L10n.tr('Nalog je suspendovan', 'Account suspended');
  static String get body => L10n.tr(
        'Administrator je privremeno suspendovao vaš nalog zbog kršenja '
            'pravila zajednice. Ako mislite da je ovo greška, pišite nam na '
            'zvanične kontakte iz pravila aplikacije.',
        'An administrator suspended your account for breaking the community '
            'rules. If you think this is a mistake, contact us.',
      );
  static String get signOut => L10n.tr('Odjavi se', 'Sign out');
}
