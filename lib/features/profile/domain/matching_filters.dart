import '../../discover/domain/discover_profile.dart';

enum FilterGender { any, male, female }

enum FilterCity { any, noviSad, beograd }

enum FilterEnergy { any, low, medium, high }

class MatchingFilters {
  const MatchingFilters({
    this.sizes = const {'mali', 'srednji', 'veliki', 'gigantski'},
    this.gender = FilterGender.any,
    this.city = FilterCity.any,
    this.radiusKm = 20,
    this.energy = FilterEnergy.any,
    this.minAge = 0,
    this.maxAge = 15,
    this.vaccinatedOnly = false,
    this.sterilizedOnly = false,
  });

  final Set<String> sizes;
  final FilterGender gender;
  final FilterCity city;
  final double radiusKm;
  final FilterEnergy energy;
  final double minAge;
  final double maxAge;
  final bool vaccinatedOnly;
  final bool sterilizedOnly;

  MatchingFilters copyWith({
    Set<String>? sizes,
    FilterGender? gender,
    FilterCity? city,
    double? radiusKm,
    FilterEnergy? energy,
    double? minAge,
    double? maxAge,
    bool? vaccinatedOnly,
    bool? sterilizedOnly,
  }) {
    return MatchingFilters(
      sizes: sizes ?? this.sizes,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      radiusKm: radiusKm ?? this.radiusKm,
      energy: energy ?? this.energy,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      vaccinatedOnly: vaccinatedOnly ?? this.vaccinatedOnly,
      sterilizedOnly: sterilizedOnly ?? this.sterilizedOnly,
    );
  }

  List<DiscoverProfile> apply(List<DiscoverProfile> source) {
    return source.where(matches).toList();
  }

  bool matches(DiscoverProfile profile) {
    if (sizes.isNotEmpty && !sizes.contains(profile.size)) {
      return false;
    }
    if (gender == FilterGender.male && profile.gender != 'mužjak') {
      return false;
    }
    if (gender == FilterGender.female && profile.gender != 'ženka') {
      return false;
    }
    if (city == FilterCity.noviSad && !profile.location.startsWith('Novi Sad')) {
      return false;
    }
    if (city == FilterCity.beograd && !profile.location.startsWith('Beograd')) {
      return false;
    }
    if (profile.distanceKm > radiusKm) {
      return false;
    }
    if (profile.ageYears < minAge || profile.ageYears > maxAge) {
      return false;
    }
    if (vaccinatedOnly && !profile.vaccinated) {
      return false;
    }
    if (sterilizedOnly && !profile.sterilized) {
      return false;
    }
    if (energy != FilterEnergy.any &&
        _energyOf(profile.energyLevel) != energy) {
      return false;
    }
    return true;
  }

  FilterEnergy _energyOf(String value) {
    switch (value) {
      case 'niska':
        return FilterEnergy.low;
      case 'visoka':
        return FilterEnergy.high;
      default:
        return FilterEnergy.medium;
    }
  }
}
