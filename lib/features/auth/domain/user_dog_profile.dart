import '../../../core/images/dog_photo_urls.dart';

class UserDogProfile {
  const UserDogProfile({
    this.id = '',
    this.name = '',
    this.breed = '',
    this.age = 0,
    this.gender = '',
    this.bio = '',
    this.photoUrls = const [],
    this.size = '',
    this.temperament = const [],
  });

  final String id;
  final String name;
  final String breed;
  final int age;
  final String gender;
  final String bio;
  final List<String> photoUrls;
  final String size;
  final List<String> temperament;

  bool get hasProfile => id.isNotEmpty && name.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'gender': gender,
      'bio': bio,
      'size': size,
      'temperament': temperament,
      ...firestorePhotoFields(photoUrls),
    };
  }

  static UserDogProfile fromMap(Object? raw) {
    if (raw is! Map) {
      return const UserDogProfile();
    }
    final data = Map<String, dynamic>.from(raw);
    return UserDogProfile(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: data['gender'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      photoUrls: collectPhotoUrls(data),
      size: data['size'] as String? ?? '',
      temperament: _strings(data['temperament']),
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => item.toString()).toList();
  }
}
