import '../../../core/constants/dog_breeds.dart';
import '../../../core/constants/serbia_locations.dart';
import 'groups_models.dart';

/// Filter of the „Za šetnju“ tab. [cityId] null = Cela Srbija; [category] null
/// = Sve.
class GroupFilter {
  const GroupFilter({this.cityId, this.category});

  final String? cityId;
  final GroupCategory? category;

  GroupFilter copyWith({
    String? cityId,
    bool clearCity = false,
    GroupCategory? category,
    bool clearCategory = false,
  }) {
    return GroupFilter(
      cityId: clearCity ? null : (cityId ?? this.cityId),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

/// Pure filtering, ordering and breed lookup for the groups screen. Ordering
/// uses only verifiable signals (featured flag, location link, `lastMessageAt`,
/// `sortOrder`, title); member counts are never used as „popularity“.
abstract final class GroupRanking {
  /// Walk groups (everything except breed groups) that match [filter].
  /// With a city: that city's local groups and the global ones.
  static List<BreedGroup> walkGroups(
    Iterable<BreedGroup> groups,
    GroupFilter filter,
  ) {
    final result = <BreedGroup>[
      for (final group in groups)
        if (group.isApproved &&
            group.scope != GroupScope.breed &&
            _matchesCity(group, filter.cityId) &&
            (filter.category == null || group.category == filter.category))
          group,
    ];
    return sort(result, cityId: filter.cityId);
  }

  static bool _matchesCity(BreedGroup group, String? cityId) {
    if (cityId == null) {
      return true;
    }
    return group.scope == GroupScope.global || group.cityId == cityId;
  }

  /// Cela Srbija: featured global, other global, location groups, other local.
  /// City: location groups, general city group, other city groups, featured
  /// global, other global. Inside a tier: most recent real message first, then
  /// `sortOrder`, then folded title, then id (stable).
  static List<BreedGroup> sort(Iterable<BreedGroup> groups, {String? cityId}) {
    final list = List<BreedGroup>.from(groups);
    list.sort((a, b) {
      final byTier = _tier(a, cityId).compareTo(_tier(b, cityId));
      if (byTier != 0) {
        return byTier;
      }
      final aAt = a.lastMessageAt;
      final bAt = b.lastMessageAt;
      if (aAt != null || bAt != null) {
        if (aAt == null) {
          return 1;
        }
        if (bAt == null) {
          return -1;
        }
        final byActivity = bAt.compareTo(aAt);
        if (byActivity != 0) {
          return byActivity;
        }
      }
      final bySort = a.sortOrder.compareTo(b.sortOrder);
      if (bySort != 0) {
        return bySort;
      }
      final byTitle = SerbiaLocations.foldName(
        a.title,
      ).compareTo(SerbiaLocations.foldName(b.title));
      return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
    });
    return list;
  }

  static int _tier(BreedGroup group, String? cityId) {
    final isGlobal = group.scope == GroupScope.global;
    if (cityId == null) {
      if (isGlobal) {
        return group.featured ? 0 : 1;
      }
      return group.hasLocation ? 2 : 3;
    }
    if (isGlobal) {
      return group.featured ? 3 : 4;
    }
    if (group.hasLocation) {
      return 0;
    }
    return group.category == GroupCategory.general ? 1 : 2;
  }

  // --- breeds -------------------------------------------------------------

  /// Featured start view (registry names), not a statistical ranking.
  static const List<String> featuredBreeds = [
    'Pudlica',
    'Nemački ovčar',
    'Labrador',
    'Zlatni retriver',
    'Francuski buldog',
    'Pomeranac',
    'Jorkširski terijer',
    'Rotvajler',
    'Doberman',
    'Haski (Sibirski)',
    'Mešanac',
  ];

  /// Display label; „Mešanac“ also covers adopted dogs.
  static String breedLabel(String breed) {
    return switch (breed) {
      'Pudlica' => 'Pudle',
      'Nemački ovčar' => 'Nemački ovčari',
      'Labrador' => 'Labrador retriveri',
      'Zlatni retriver' => 'Zlatni retriveri',
      'Francuski buldog' => 'Francuski buldozi',
      'Pomeranac' => 'Pomeranci',
      'Jorkširski terijer' => 'Jorkširski terijeri',
      'Rotvajler' => 'Rotvajleri',
      'Doberman' => 'Dobermani',
      'Haski (Sibirski)' => 'Sibirski haskiji',
      'Mešanac' => 'Mešanci i udomljeni psi',
      _ => breed,
    };
  }

  /// Registry breeds matching [query] (diacritics/Cyrillic insensitive) in
  /// registry order; matches the display label too.
  static List<String> searchBreeds(String query) {
    final needle = SerbiaLocations.foldName(query);
    if (needle.isEmpty) {
      return List<String>.from(DogBreeds.suggested);
    }
    return [
      for (final breed in DogBreeds.suggested)
        if (SerbiaLocations.foldName(breed).contains(needle) ||
            SerbiaLocations.foldName(breedLabel(breed)).contains(needle))
          breed,
    ];
  }

  static bool sameBreed(String a, String b) =>
      a.trim().isNotEmpty &&
      SerbiaLocations.foldName(a) == SerbiaLocations.foldName(b);

  /// The group to show for [breed]: the local one in [cityId] if it exists,
  /// otherwise the global breed group; with Cela Srbija the global one, then
  /// the best local one. Null = nothing exists (offer a suggestion).
  static BreedGroup? groupForBreed(
    Iterable<BreedGroup> groups,
    String breed, {
    String? cityId,
  }) {
    final matching = sort([
      for (final group in groups)
        if (group.isApproved &&
            group.scope == GroupScope.breed &&
            sameBreed(group.breedKey, breed))
          group,
    ], cityId: cityId);
    if (matching.isEmpty) {
      return null;
    }
    if (cityId != null) {
      for (final group in matching) {
        if (group.cityId == cityId) {
          return group;
        }
      }
      for (final group in matching) {
        if (group.cityId.isEmpty) {
          return group;
        }
      }
      return null;
    }
    for (final group in matching) {
      if (group.cityId.isEmpty) {
        return group;
      }
    }
    return matching.first;
  }
}
