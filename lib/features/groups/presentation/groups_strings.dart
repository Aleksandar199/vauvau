import '../../../core/l10n/l10n.dart';

abstract final class GroupsStrings {
  static String get drawerItem => L10n.tr('👥 Grupe', '👥 Groups');
  static String get title => L10n.tr('Grupe za šetnju i rase', 'Walk and breed groups');
  static String get subtitle => L10n.tr(
        'Pridruži se lokalnim grupama, dogovori šetnju i razmeni savete.',
        'Join local groups, plan walks, and share tips.',
      );
  static String get join => L10n.tr('+ Pridruži se', '+ Join');
  static String get openChat => L10n.tr('💬 Otvori chat', '💬 Open chat');
  static String get composeHint =>
      L10n.tr('Napiši poruku u grupi...', 'Write a message in the group...');
  static String get send => L10n.tr('Pošalji', 'Send');
  static String get addPhoto => L10n.tr('Fotografija', 'Photo');
  static String get gallery => L10n.tr('Galerija', 'Gallery');
  static String get camera => L10n.tr('Kamera', 'Camera');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get photoFailed =>
      L10n.tr('Fotografija nije poslata. Pokušajte ponovo.', 'Photo was not sent. Try again.');
  static String get emptyChat =>
      L10n.tr('Još nema poruka. Reci zdravo čoporu!', 'No messages yet. Say hi to the pack!');
  static String get members => L10n.tr('članova', 'members');
  static String get createGroup => L10n.tr('Napravi novu grupu', 'Create a new group');
  static String get createGroupTitle => L10n.tr('Nova grupa', 'New group');
  static String get groupName => L10n.tr('Naziv grupe', 'Group name');
  static String get groupDescription => L10n.tr('Opis (opciono)', 'Description (optional)');
  static String get submitGroup => L10n.tr('Pošalji na pregled', 'Submit for review');
  static String get nameRequired => L10n.tr('Unesite naziv grupe.', 'Enter a group name.');
  static String get pendingReview => L10n.tr(
        'Vaša grupa je poslata na pregled. Biće vidljiva nakon odobrenja administratora.',
        'Your group was submitted for review. It will be visible after admin approval.',
      );
  static String get createdApproved =>
      L10n.tr('Grupa je kreirana i odmah vidljiva.', 'Group created and visible immediately.');
  static String get createFailed =>
      L10n.tr('Grupa nije kreirana. Pokušajte ponovo.', 'Group was not created. Try again.');
  static String get requestSentTitle => L10n.tr('Zahtev poslat', 'Request sent');
  static String get requestSentBody => L10n.tr(
        'Vaša grupa je uspešno poslata na pregled. Biće vidljiva svim korisnicima nakon odobrenja administratora.',
        'Your group was submitted for review. It will be visible to everyone after admin approval.',
      );
  static String get createErrorTitle => L10n.tr('Greška', 'Error');
  static String get ok => L10n.tr('U redu', 'OK');
  static String get close => L10n.tr('Zatvori', 'Close');

  static String createErrorBody(String details) => L10n.tr(
        'Neuspešno kreiranje grupe: $details',
        'Failed to create group: $details',
      );

  static String memberCount(int count) {
    if (L10n.isEnglish) {
      return count == 1 ? '1 member' : '$count members';
    }
    return '$count $members';
  }
}
