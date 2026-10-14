/// Suggested dog breeds for onboarding / profile forms (Serbian common names).
abstract final class DogBreeds {
  static const String customId = '__custom__';

  /// Alphabetical list of common breeds in Serbia / region.
  static const List<String> suggested = [
    'Akita',
    'Alaskan malamut',
    'Američki stafordski terijer',
    'Australski ovčar',
    'Basenji',
    'Beagle',
    'Belgijski ovčar (Malinoa)',
    'Bernski planinski pas',
    'Bišon',
    'Bokser',
    'Border koli',
    'Bullmastiff',
    'Cane Corso',
    'Čivava',
    'Dalmatinac',
    'Doberman',
    'Dogo Argentino',
    'Džek Rasel terijer',
    'Engleski buldog',
    'Engleski koker španijel',
    'Engleski seter',
    'Francuski buldog',
    'Greyhound',
    'Haski (Sibirski)',
    'Hrvatski ovčar',
    'Irski seter',
    'Japan Chin',
    'Jorkširski terijer',
    'Kavkaski ovčar',
    'Labrador',
    'Lagoto romanjolo',
    'Maltezer',
    'Mešanac',
    'Mops',
    'Nemački ovčar',
    'Newfoundland',
    'Papijon',
    'Pekinezer',
    'Pitbul',
    'Pointer',
    'Pomeranac',
    'Presa Canario',
    'Pudlica',
    'Rotvajler',
    'Samojed',
    'Šarplaninac',
    'Šetlandski ovčar',
    'Šiba Inu',
    'Šnaucer',
    'Špic',
    'Staffordshire bull terijer',
    'Vizsla',
    'Weimaraner',
    'West Highland White Terijer',
    'Whippet',
    'Zlatni retriver',
  ];

  static bool isSuggested(String breed) {
    final trimmed = breed.trim();
    if (trimmed.isEmpty) return false;
    return suggested.any((b) => b.toLowerCase() == trimmed.toLowerCase());
  }

  /// Dropdown value for an existing breed string.
  /// Returns [customId] when the breed is non-empty but not in [suggested].
  static String? dropdownValue(String breed) {
    final trimmed = breed.trim();
    if (trimmed.isEmpty) return null;
    for (final b in suggested) {
      if (b.toLowerCase() == trimmed.toLowerCase()) return b;
    }
    return customId;
  }

  static bool isCustomSelection(String? dropdownValue) =>
      dropdownValue == customId;
}
