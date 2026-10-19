import '../domain/groups_models.dart';

abstract final class SeedBreedGroups {
  static const String defaultDescription =
      'Šetnje, dogovori za playdate i saveti za negu';

  static const String parkDescription =
      'Lokalna park grupa — dogovorite šetnje, susrete i igru u parku.';

  /// Removed preset — cleaned up during seed sync.
  static const String removedSmallDogsId = 'vlasnici-malih-pasa-novi-sad';

  static const List<BreedGroup> _legacy = [
    BreedGroup(
      id: 'aktivne-setnje-playdate',
      title: '🏃‍♂️ Aktivne šetnje & Playdate',
      description: 'Dogovorite šetnje, trčanje i igru u parku.',
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 1,
      isApproved: true,
    ),
    BreedGroup(
      id: 'kej-zezeljev-most',
      title: '🌊 Kej / Žeželjev most',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 2,
      isApproved: true,
    ),
    BreedGroup(
      id: 'labradori-novi-sad',
      title: '🦮 Labradori Novi Sad',
      description: defaultDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 3,
      isApproved: true,
    ),
    BreedGroup(
      id: 'limanski-park',
      title: '🌳 Limanski park',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 4,
      isApproved: true,
    ),
    BreedGroup(
      id: 'pomeranci-novi-sad',
      title: '🐕 Pomeranci Novi Sad',
      description: defaultDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 5,
      isApproved: true,
    ),
    BreedGroup(
      id: 'petrovaradinska-tvrdjava',
      title: '🏰 Petrovaradinska tvrđava',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 6,
      isApproved: true,
    ),
    BreedGroup(
      id: 'futoski-park',
      title: '🍃 Futoški park',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 7,
      isApproved: true,
    ),
    BreedGroup(
      id: 'francuski-buldozi-novi-sad',
      title: '🐩 Francuski buldozi Novi Sad',
      description: defaultDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 8,
      isApproved: true,
    ),
    BreedGroup(
      id: 'kamenicki-park',
      title: '🌲 Kamenički park',
      description: parkDescription,
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 9,
      isApproved: true,
    ),
  ];

  /// New global groups. `aktivne-setnje-playdate` already covers „Aktivne
  /// šetnje i trčanje sa psima“, so there is no second document for it.
  /// memberCount is 0: a count is only real once people join.
  static const List<BreedGroup> _global = [
    BreedGroup(
      id: 'setnje-pasa-srbija',
      title: 'Šetnje pasa — Srbija',
      description: 'Opšta grupa za vlasnike pasa iz cele Srbije.',
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 10,
      scope: GroupScope.global,
      featured: true,
    ),
    BreedGroup(
      id: 'vikend-setnje-izleti',
      title: 'Vikend šetnje i izleti sa psima',
      description: 'Dogovorite vikend šetnje i izlete van grada.',
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 11,
      scope: GroupScope.global,
      category: GroupCategory.hiking,
      featured: true,
    ),
    BreedGroup(
      id: 'druzenje-stenaca',
      title: 'Druženje štenaca',
      description: 'Socijalizacija i igra štenaca, saveti za prve mesece.',
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 12,
      scope: GroupScope.global,
      category: GroupCategory.puppies,
      featured: true,
    ),
    BreedGroup(
      id: 'druzenje-malih-pasa',
      title: 'Druženje malih pasa',
      description: 'Igra i šetnje za male rase.',
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 13,
      scope: GroupScope.global,
      category: GroupCategory.smallDogs,
      featured: true,
    ),
    BreedGroup(
      id: 'druzenje-velikih-pasa',
      title: 'Druženje velikih pasa',
      description: 'Igra i šetnje za velike rase.',
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 14,
      scope: GroupScope.global,
      category: GroupCategory.largeDogs,
      featured: true,
    ),
    BreedGroup(
      id: 'planinarenje-sa-psima',
      title: 'Planinarenje sa psima',
      description: 'Planinarske ture i staze pogodne za pse.',
      imageUrl: '',
      memberIds: [],
      memberCount: 0,
      sortOrder: 15,
      scope: GroupScope.global,
      category: GroupCategory.hiking,
      featured: true,
    ),
  ];

  static BreedGroup _withLegacyMeta(BreedGroup group) {
    final meta = LegacyGroupMeta.byId[group.id];
    if (meta == null) {
      return group;
    }
    return group.copyWith(
      scope: meta.scope,
      cityId: meta.cityId,
      category: meta.category,
      locationName: meta.locationName,
      breedKey: meta.breedKey,
      featured: meta.featured,
    );
  }

  /// Every preset group, each id exactly once. Candidates that are NOT here
  /// (not created automatically): Dunavski park, „Šetnje pasa — Novi Sad“ and
  /// all groups for other cities.
  static final List<BreedGroup> all = List.unmodifiable([
    ..._legacy.map(_withLegacyMeta),
    ..._global,
  ]);

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
      ...classificationData(group),
    };
  }

  /// Optional classification fields (merged into existing seed documents).
  static Map<String, dynamic> classificationData(BreedGroup group) {
    return {
      'scope': group.scope.name,
      'category': group.category.key,
      'featured': group.featured,
      if (group.cityId.isNotEmpty) 'cityId': group.cityId,
      if (group.locationName.isNotEmpty) 'locationName': group.locationName,
      if (group.breedKey.isNotEmpty) 'breedKey': group.breedKey,
    };
  }
}
