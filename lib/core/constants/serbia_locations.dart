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
  static const List<CityLocation> cities = [
    CityLocation(
      id: 'beograd',
      name: 'Beograd',
      neighborhoods: [
        Neighborhood(id: 'dorcol', name: 'Dorćol'),
        Neighborhood(id: 'vracar', name: 'Vračar'),
        Neighborhood(id: 'novi_beograd', name: 'Novi Beograd'),
      ],
    ),
    CityLocation(
      id: 'novi_sad',
      name: 'Novi Sad',
      neighborhoods: [
        Neighborhood(id: 'liman', name: 'Liman'),
        Neighborhood(id: 'centar', name: 'Centar'),
        Neighborhood(id: 'petrovaradin', name: 'Petrovaradin'),
      ],
    ),
  ];

  static CityLocation? cityById(String id) {
    for (final city in cities) {
      if (city.id == id) {
        return city;
      }
    }
    return null;
  }
}
