class Neighborhood {
  const Neighborhood({required this.id, required this.name});

  final String id;
  final String name;
}

class CityLocation {
  const CityLocation({
    required this.id,
    required this.name,
    required this.neighborhoods,
  });

  final String id;
  final String name;
  final List<Neighborhood> neighborhoods;
}

abstract final class SerbiaLocations {
  static const String noviSadId = 'novi_sad';

  static const List<CityLocation> cities = [
    CityLocation(
      id: noviSadId,
      name: 'Novi Sad',
      neighborhoods: [
        Neighborhood(id: 'liman_1', name: 'Liman 1'),
        Neighborhood(id: 'liman_2', name: 'Liman 2'),
        Neighborhood(id: 'liman_3', name: 'Liman 3'),
        Neighborhood(id: 'liman_4', name: 'Liman 4'),
        Neighborhood(id: 'grbavica', name: 'Grbavica'),
        Neighborhood(id: 'centar', name: 'Centar'),
        Neighborhood(id: 'detelinara', name: 'Detelinara'),
        Neighborhood(id: 'novo_naselje', name: 'Novo Naselje'),
        Neighborhood(id: 'telep', name: 'Telep'),
        Neighborhood(id: 'podbara', name: 'Podbara'),
        Neighborhood(id: 'rotkvarija', name: 'Rotkvarija'),
        Neighborhood(id: 'salajka', name: 'Salajka'),
        Neighborhood(id: 'banatic', name: 'Banatić'),
        Neighborhood(id: 'sajmiste', name: 'Sajmište'),
        Neighborhood(id: 'avijaticarsko_naselje', name: 'Avijatičarsko Naselje'),
        Neighborhood(id: 'adamovicevo_naselje', name: 'Adamovićevo Naselje'),
        Neighborhood(id: 'petrovaradin', name: 'Petrovaradin'),
        Neighborhood(id: 'sremska_kamenica', name: 'Sremska Kamenica'),
        Neighborhood(id: 'futog', name: 'Futog'),
        Neighborhood(id: 'veternik', name: 'Veternik'),
        Neighborhood(id: 'adice', name: 'Adice'),
        Neighborhood(id: 'klisa', name: 'Klisa'),
        Neighborhood(id: 'vidovdansko_naselje', name: 'Vidovdansko Naselje'),
        Neighborhood(id: 'slana_bara', name: 'Slana Bara'),
      ],
    ),
    CityLocation(
      id: 'beograd',
      name: 'Beograd',
      neighborhoods: [
        Neighborhood(id: 'dorcol', name: 'Dorćol'),
        Neighborhood(id: 'vracar', name: 'Vračar'),
        Neighborhood(id: 'novi_beograd', name: 'Novi Beograd'),
      ],
    ),
  ];

  static const List<String> adoptionCities = [
    'Novi Sad',
    'Beograd',
    'Niš',
    'Kragujevac',
    'Ostalo',
  ];

  static const List<String> noviSadAdoptionNeighborhoods = [
    'Liman 1',
    'Liman 2',
    'Liman 3',
    'Liman 4',
    'Grbavica',
    'Centar (Stari Grad)',
    'Detelinara (Stara i Nova)',
    'Novo Naselje (Bistrica)',
    'Telep',
    'Podbara',
    'Rotkvarija',
    'Salajka',
    'Banatić',
    'Sajmište',
    'Avijatičarsko Naselje',
    'Adamovićevo Naselje',
    'Petrovaradin',
    'Sremska Kamenica',
    'Futog',
    'Veternik',
    'Adice',
    'Klisa',
    'Vidovdansko Naselje',
    'Slana Bara',
  ];

  static List<String> neighborhoodsForAdoptionCity(String city) {
    if (city == 'Novi Sad') {
      return noviSadAdoptionNeighborhoods;
    }
    if (city == 'Beograd') {
      return [
        for (final hood in cityById('beograd')?.neighborhoods ?? const [])
          hood.name,
      ];
    }
    return const ['Ostalo'];
  }

  static CityLocation get noviSad => cities.first;

  static CityLocation? cityById(String id) {
    for (final city in cities) {
      if (city.id == id) {
        return city;
      }
    }
    return null;
  }

  static String formatPlace(String cityName, String neighborhoodName) {
    final city = cityName.trim();
    final neighborhood = neighborhoodName.trim();
    if (city.isEmpty && neighborhood.isEmpty) {
      return '';
    }
    if (city.isEmpty) {
      return sanitizeLocationLabel(neighborhood);
    }
    if (neighborhood.isEmpty) {
      return sanitizeLocationLabel(city);
    }
    return sanitizeLocationLabel('$city, $neighborhood');
  }

  static String displayPlace(String raw) {
    return sanitizeLocationLabel(raw);
  }

  /// Turns "Novi Sad Telep Telep" / "Novi Sad · Telep · Telep" into "Novi Sad, Telep".
  static String sanitizeLocationLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final normalized = trimmed
        .replaceAll('·', ',')
        .replaceAll('•', ',')
        .replaceAll(RegExp(r'\s*[-–/|]\s*'), ',');
    final chunks = <String>[];
    for (final piece in normalized.split(',')) {
      final cleaned = _dedupeRepeatedWords(piece.trim());
      if (cleaned.isEmpty) {
        continue;
      }
      if (chunks.any((item) => item.toLowerCase() == cleaned.toLowerCase())) {
        continue;
      }
      if (chunks.isNotEmpty &&
          chunks.last.toLowerCase().contains(cleaned.toLowerCase())) {
        continue;
      }
      chunks.add(cleaned);
    }
    if (chunks.isEmpty) {
      return trimmed;
    }
    if (chunks.length == 1) {
      return _splitCityAndNeighborhood(chunks.first);
    }
    final city = chunks.first;
    final rest = <String>[];
    for (final part in chunks.skip(1)) {
      var neighborhood = part;
      if (neighborhood.toLowerCase().startsWith(city.toLowerCase())) {
        neighborhood =
            neighborhood.substring(city.length).replaceFirst(RegExp(r'^[,·\-\s]+'), '').trim();
      }
      if (neighborhood.isEmpty ||
          neighborhood.toLowerCase() == city.toLowerCase() ||
          city.toLowerCase().contains(neighborhood.toLowerCase())) {
        continue;
      }
      rest.add(neighborhood);
    }
    if (rest.isEmpty) {
      return _splitCityAndNeighborhood(city);
    }
    return '$city, ${rest.join(', ')}';
  }

  static String _dedupeRepeatedWords(String value) {
    final words =
        value.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final out = <String>[];
    for (final word in words) {
      if (out.isNotEmpty && out.last.toLowerCase() == word.toLowerCase()) {
        continue;
      }
      out.add(word);
    }
    return out.join(' ');
  }

  static String _splitCityAndNeighborhood(String value) {
    for (final city in cities) {
      final name = city.name;
      if (!value.toLowerCase().startsWith(name.toLowerCase())) {
        continue;
      }
      if (value.length == name.length) {
        return name;
      }
      var rest = value.substring(name.length).trim();
      rest = rest.replaceFirst(RegExp(r'^[,·\-]+'), '').trim();
      rest = _dedupeRepeatedWords(rest);
      if (rest.isEmpty || rest.toLowerCase() == name.toLowerCase()) {
        return name;
      }
      return '$name, $rest';
    }
    return value;
  }
}
