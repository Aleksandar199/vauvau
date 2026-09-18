class DogArea {
  const DogArea({
    required this.cityId,
    required this.cityName,
    required this.neighborhoodId,
    required this.neighborhoodName,
  });

  final String cityId;
  final String cityName;
  final String neighborhoodId;
  final String neighborhoodName;

  Map<String, String> toMap() {
    return {
      'cityId': cityId,
      'cityName': cityName,
      'neighborhoodId': neighborhoodId,
      'neighborhoodName': neighborhoodName,
    };
  }

  factory DogArea.fromMap(Map<String, dynamic> map) {
    return DogArea(
      cityId: map['cityId'] as String? ?? '',
      cityName: map['cityName'] as String? ?? '',
      neighborhoodId: map['neighborhoodId'] as String? ?? '',
      neighborhoodName: map['neighborhoodName'] as String? ?? '',
    );
  }
}
