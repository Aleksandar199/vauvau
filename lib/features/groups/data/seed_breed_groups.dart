import '../domain/groups_models.dart';

abstract final class SeedBreedGroups {
  static const String defaultDescription =
      'Šetnje, dogovori za playdate i saveti za negu';

  static const List<BreedGroup> all = [
    BreedGroup(
      id: 'pomeranci-novi-sad',
      title: '🐕 Pomeranci Novi Sad',
      description: defaultDescription,
      imageUrl:
          'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&w=400&q=80',
      memberIds: [],
      memberCount: 127,
      sortOrder: 1,
    ),
    BreedGroup(
      id: 'labradori-novi-sad',
      title: '🦮 Labradori Novi Sad',
      description: defaultDescription,
      imageUrl:
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=400&q=80',
      memberIds: [],
      memberCount: 214,
      sortOrder: 2,
    ),
    BreedGroup(
      id: 'francuski-buldozi-novi-sad',
      title: '🐩 Francuski buldozi Novi Sad',
      description: defaultDescription,
      imageUrl:
          'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=400&q=80',
      memberIds: [],
      memberCount: 89,
      sortOrder: 3,
    ),
    BreedGroup(
      id: 'vlasnici-malih-pasa-novi-sad',
      title: '🐾 Vlasnici malih pasa Novi Sad',
      description: defaultDescription,
      imageUrl:
          'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=400&q=80',
      memberIds: [],
      memberCount: 156,
      sortOrder: 4,
    ),
    BreedGroup(
      id: 'aktivne-setnje-playdate',
      title: '🏃‍♂️ Aktivne šetnje & Playdate',
      description: 'Dogovorite šetnje, trčanje i igru u parku.',
      imageUrl:
          'https://images.unsplash.com/photo-1558788353-f76d92427f16?auto=format&fit=crop&w=400&q=80',
      memberIds: [],
      memberCount: 301,
      sortOrder: 5,
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
    };
  }
}
