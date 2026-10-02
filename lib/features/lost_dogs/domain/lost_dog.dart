class LostDog {
  const LostDog({
    required this.id,
    required this.dogName,
    required this.city,
    required this.neighborhood,
    required this.lostDate,
    required this.description,
    required this.imageUrl,
    required this.contactPhone,
    required this.uploaderUserId,
    required this.status,
    required this.createdAt,
    this.type = LostDogType.lost,
    this.breed = '',
    this.foundDate,
  });

  final String id;
  final String dogName;
  final String city;
  final String neighborhood;
  final DateTime lostDate;
  final DateTime? foundDate;
  final String description;
  final String imageUrl;
  final String contactPhone;
  final String uploaderUserId;
  final String status;
  final String type;
  final String breed;
  final DateTime createdAt;

  bool get isLostListing => type != LostDogType.found;

  bool get isFoundListing => type == LostDogType.found;

  bool get isActive =>
      status == LostDogStatus.active || status == LostDogStatus.legacyMissing;

  bool get isMissing => isLostListing && isActive;

  DateTime get eventDate =>
      isFoundListing ? (foundDate ?? lostDate) : lostDate;

  String get placeLabel {
    if (city.isEmpty) {
      return neighborhood;
    }
    if (neighborhood.isEmpty) {
      return city;
    }
    return '$city – $neighborhood';
  }

  LostDog copyWith({
    String? id,
    String? dogName,
    String? city,
    String? neighborhood,
    DateTime? lostDate,
    DateTime? foundDate,
    String? description,
    String? imageUrl,
    String? contactPhone,
    String? uploaderUserId,
    String? status,
    String? type,
    String? breed,
    DateTime? createdAt,
  }) {
    return LostDog(
      id: id ?? this.id,
      dogName: dogName ?? this.dogName,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      lostDate: lostDate ?? this.lostDate,
      foundDate: foundDate ?? this.foundDate,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      contactPhone: contactPhone ?? this.contactPhone,
      uploaderUserId: uploaderUserId ?? this.uploaderUserId,
      status: status ?? this.status,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

abstract final class LostDogType {
  static const String lost = 'lost';
  static const String found = 'found';
}

abstract final class LostDogStatus {
  static const String active = 'active';
  static const String resolved = 'resolved';
  static const String legacyMissing = 'missing';
  static const String legacyFound = 'found';
}

class LostDogComment {
  const LostDogComment({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorUserId;
  final String authorName;
  final String text;
  final DateTime createdAt;
}
