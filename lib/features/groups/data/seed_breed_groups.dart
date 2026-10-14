import '../domain/groups_models.dart';

abstract final class SeedBreedGroups {
  static const String defaultDescription =
      'Šetnje, dogovori za playdate i saveti za negu';

  static const String parkDescription =
      'Lokalna park grupa — dogovorite šetnje, susrete i igru u parku.';

  /// Removed preset — cleaned up during seed sync.
  static const String removedSmallDogsId = 'vlasnici-malih-pasa-novi-sad';

  static const List<BreedGroup> all = [
    BreedGroup(
      id: 'aktivne-setnje-playdate',
      title: '🏃‍♂️ Aktivne šetnje & Playdate',
      description: 'Dogovorite šetnje, trčanje i igru u parku.',
      imageUrl: '',
      memberIds: [],
      memberCount: 45,
      sortOrder: 1,
      isApproved: true,
    ),
    BreedGroup(
      id: 'kej-zezeljev-most',
      title: '🌊 Kej / Žeželjev most',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 42,
      sortOrder: 2,
      isApproved: true,
    ),
    BreedGroup(
      id: 'labradori-novi-sad',
      title: '🦮 Labradori Novi Sad',
      description: defaultDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 41,
      sortOrder: 3,
      isApproved: true,
    ),
    BreedGroup(
      id: 'limanski-park',
      title: '🌳 Limanski park',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 38,
      sortOrder: 4,
      isApproved: true,
    ),
    BreedGroup(
      id: 'pomeranci-novi-sad',
      title: '🐕 Pomeranci Novi Sad',
      description: defaultDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 34,
      sortOrder: 5,
      isApproved: true,
    ),
    BreedGroup(
      id: 'petrovaradinska-tvrdjava',
      title: '🏰 Petrovaradinska tvrđava',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 31,
      sortOrder: 6,
      isApproved: true,
    ),
    BreedGroup(
      id: 'futoski-park',
      title: '🍃 Futoški park',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 29,
      sortOrder: 7,
      isApproved: true,
    ),
    BreedGroup(
      id: 'francuski-buldozi-novi-sad',
      title: '🐩 Francuski buldozi Novi Sad',
      description: defaultDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 28,
      sortOrder: 8,
      isApproved: true,
    ),
    BreedGroup(
      id: 'kamenicki-park',
      title: '🌲 Kamenički park',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 22,
      sortOrder: 9,
      isApproved: true,
    ),
  ];

  static Map<String, dynamic> firestoreData(BreedGroup group) {
    return {
      'title': group.title,
      'description': group.description,
      'imageUrl': group.imageUrl,
      'memberIds': group.memberIds,
      'memberCount': group.memberCount,
      'sortOrder': group.sortOrder,
      'lastMessage': group.lastMessage,
      'isApproved': group.isApproved,
      'createdBy': group.createdBy,
    };
  }

  static List<BreedGroup> sortByPopularity(Iterable<BreedGroup> groups) {
    final List<BreedGroup> sorted = List<BreedGroup>.from(
      groups.whereType<BreedGroup>(),
    );
    sorted.sort((BreedGroup a, BreedGroup b) {
      final byMembers = b.displayMemberCount.compareTo(a.displayMemberCount);
      if (byMembers != 0) {
        return byMembers;
      }
      return a.title.compareTo(b.title);
    });
    return sorted;
  }
}
