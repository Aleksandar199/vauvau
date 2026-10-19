import '../../../core/l10n/l10n.dart';
import '../domain/groups_models.dart';

abstract final class GroupsStrings {
  static String get drawerItem => L10n.tr('👥 Grupe', '👥 Groups');
  static String get title =>
      L10n.tr('Grupe za šetnju i rase', 'Walk and breed groups');
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
  static String get photoFailed => L10n.tr(
    'Fotografija nije poslata. Pokušajte ponovo.',
    'Photo was not sent. Try again.',
  );
  static String get emptyChat => L10n.tr(
    'Još nema poruka. Reci zdravo čoporu!',
    'No messages yet. Say hi to the pack!',
  );
  static String get members => L10n.tr('članova', 'members');
  static String get createGroup =>
      L10n.tr('Napravi novu grupu', 'Create a new group');
  static String get createGroupTitle => L10n.tr('Nova grupa', 'New group');
  static String get groupName => L10n.tr('Naziv grupe', 'Group name');
  static String get groupDescription =>
      L10n.tr('Opis (opciono)', 'Description (optional)');
  static String get submitGroup =>
      L10n.tr('Pošalji na pregled', 'Submit for review');
  static String get nameRequired =>
      L10n.tr('Unesite naziv grupe.', 'Enter a group name.');
  static String get pendingReview => L10n.tr(
    'Vaša grupa je poslata na pregled. Biće vidljiva nakon odobrenja administratora.',
    'Your group was submitted for review. It will be visible after admin approval.',
  );
  static String get createdApproved => L10n.tr(
    'Grupa je kreirana i odmah vidljiva.',
    'Group created and visible immediately.',
  );
  static String get createFailed => L10n.tr(
    'Grupa nije kreirana. Pokušajte ponovo.',
    'Group was not created. Try again.',
  );
  static String get requestSentTitle =>
      L10n.tr('Zahtev poslat', 'Request sent');
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

  static String get tabWalks => L10n.tr('Za šetnju', 'For walks');
  static String get tabBreeds => L10n.tr('Po rasama', 'By breed');
  static String get allSerbia => L10n.tr('Cela Srbija', 'All of Serbia');
  static String get allTypes => L10n.tr('Sve', 'All');
  static String get cityLabel => L10n.tr('Grad', 'City');
  static String get typeLabel => L10n.tr('Tip grupe', 'Group type');
  static String get loading => L10n.tr('Učitavanje grupa…', 'Loading groups…');
  static String get loadError => L10n.tr(
        'Grupe trenutno nisu dostupne.',
        'Groups are not available right now.',
      );
  static String get retry => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get noGroupsTitle =>
      L10n.tr('Nema grupa za ovaj izbor', 'No groups for this selection');
  static String noGroupsInCity(String city) => L10n.tr(
        'U gradu $city još nema grupe. Pokreni je i pošalji na odobrenje.',
        'There is no group in $city yet. Start one and send it for approval.',
      );
  static String get noGroupsFilter => L10n.tr(
        'Nijedna grupa ne odgovara filterima. Promeni grad ili tip.',
        'No group matches the filters. Change the city or type.',
      );
  static String get startGroup => L10n.tr('Pokreni grupu', 'Start a group');
  static String get suggestGroup => L10n.tr('Predloži grupu', 'Suggest a group');
  static String get cityOptional => L10n.tr('Grad (opciono)', 'City (optional)');
  static String get categoryLabel => L10n.tr('Tip grupe', 'Group type');
  static String get locationOptional =>
      L10n.tr('Lokacija, npr. park (opciono)', 'Location, e.g. a park (optional)');
  static String get breedLabel => L10n.tr('Rasa', 'Breed');
  static String get searchBreeds => L10n.tr('Pretraži rase', 'Search breeds');
  static String get showAllBreeds =>
      L10n.tr('Prikaži sve rase', 'Show all breeds');
  static String get showFeaturedBreeds =>
      L10n.tr('Prikaži istaknute rase', 'Show featured breeds');
  static String get featuredBreeds =>
      L10n.tr('Istaknute rase', 'Featured breeds');
  static String get noBreeds =>
      L10n.tr('Nijedna rasa ne odgovara pretrazi.', 'No breed matches the search.');
  static String get noMembersYet => L10n.tr('Još nema članova', 'No members yet');
  static String get globalGroup => L10n.tr('Cela Srbija', 'All of Serbia');
  static String get localGroup => L10n.tr('Lokalna grupa', 'Local group');
  static String get noBreedGroup =>
      L10n.tr('Još nema grupe', 'No group yet');

  static String category(GroupCategory category) => switch (category) {
        GroupCategory.general => L10n.tr('Opšte grupe', 'General groups'),
        GroupCategory.parks =>
          L10n.tr('Parkovi i lokacije', 'Parks and locations'),
        GroupCategory.puppies => L10n.tr('Štenci', 'Puppies'),
        GroupCategory.smallDogs => L10n.tr('Mali psi', 'Small dogs'),
        GroupCategory.largeDogs => L10n.tr('Veliki psi', 'Large dogs'),
        GroupCategory.active => L10n.tr('Aktivne šetnje', 'Active walks'),
        GroupCategory.hiking =>
          L10n.tr('Planinarenje i izleti', 'Hiking and trips'),
      };

  static String memberCount(int count) {
    if (L10n.isEnglish) {
      return count == 1 ? '1 member' : '$count members';
    }
    return '$count $members';
  }
}
