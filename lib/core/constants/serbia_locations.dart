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
    if (city.isEmpty) {
      return neighborhood;
    }
    if (neighborhood.isEmpty) {
      return city;
    }
    return '$city · $neighborhood';
  }

  static String displayPlace(String raw) {
    return raw.trim().replaceAll(' - ', ' · ');
  }
}
