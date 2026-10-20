import '../../../core/constants/serbia_locations.dart';
import 'lost_dog.dart';

/// City grouping of lost/found listings.
///
/// New listings store `cityId` ([SerbiaLocations] id). Old documents only
/// have free-text `city`, so it is folded (case, diacritics, Cyrillic) and
/// matched by prefix; a city that cannot be recognized lands in [other]
/// instead of disappearing.
abstract final class LostDogCity {
  /// Filter value: every city.
  static const String all = 'all';

  /// Filter value: listings whose city is not one of [SerbiaLocations.cities].
  static const String other = 'other';

  /// Canonical city id of [dog], or null when the city is unknown.
  static String? idOf(LostDog dog) =>
      SerbiaLocations.resolveCityId(dog.cityId, dog.city);

  /// `cityId` to store for a city picked in the form ("Ostalo" → null).
  static String? idForFormCity(String name) =>
      SerbiaLocations.cityIdForLabel(name);

  static bool matches(LostDog dog, String filter) {
    if (filter == all) {
      return true;
    }
    final id = idOf(dog);
    if (filter == other) {
      return id == null;
    }
    return id == filter;
  }

  static List<LostDog> filter(List<LostDog> dogs, String filter) => [
    for (final dog in dogs)
      if (matches(dog, filter)) dog,
  ];

  /// The user's own city when known, otherwise every city.
  static String defaultFilter(String? homeCityId) =>
      homeCityId != null && SerbiaLocations.cityById(homeCityId) != null
      ? homeCityId
      : all;

  /// Whether a new listing should alert a user living in [homeCityId].
  /// Users without a city keep the old behaviour (every listing); users with
  /// a city get only listings confirmed to be in that city.
  static bool alertsUser(LostDog dog, String? homeCityId) {
    if (homeCityId == null || homeCityId.isEmpty) {
      return true;
    }
    return idOf(dog) == homeCityId;
  }
}
