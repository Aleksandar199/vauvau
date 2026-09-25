class AdoptionDog {
  const AdoptionDog({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.size,
    required this.location,
    required this.description,
    required this.imageUrls,
    required this.contactPhone,
    required this.uploaderUserId,
    required this.uploaderName,
    required this.isVaccinated,
    required this.isSterilized,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String breed;
  final String age;
  final String gender;
  final String size;
  final String location;
  final String description;
  final List<String> imageUrls;
  final String contactPhone;
  final String uploaderUserId;
  final String uploaderName;
  final bool isVaccinated;
  final bool isSterilized;
  final DateTime createdAt;

  String get photoUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  AdoptionDog copyWith({
    String? id,
    String? name,
    String? breed,
    String? age,
    String? gender,
    String? size,
    String? location,
    String? description,
    List<String>? imageUrls,
    String? contactPhone,
    String? uploaderUserId,
    String? uploaderName,
    bool? isVaccinated,
    bool? isSterilized,
    DateTime? createdAt,
  }) {
    return AdoptionDog(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      size: size ?? this.size,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      contactPhone: contactPhone ?? this.contactPhone,
      uploaderUserId: uploaderUserId ?? this.uploaderUserId,
      uploaderName: uploaderName ?? this.uploaderName,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      isSterilized: isSterilized ?? this.isSterilized,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
