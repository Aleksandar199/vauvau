import '../map_city.dart';
import '../map_place_type.dart';

enum PoiCategory {
  cafe,
  restaurant,
  park,
  petShop,
  groomer,
  vet,
  lodging,
  training,
  dogHotel,
  selfWash,
  dogTreats,
  shelter,
  water,
  petSitter,
  other,
}

enum PoiVerificationStatus {
  verified,
  userSubmitted,
  pending,
  reported,
  unknown,
  rejected,
}

extension PoiVerificationStatusX on PoiVerificationStatus {
  bool get isAwaitingReview =>
      this == PoiVerificationStatus.pending ||
      this == PoiVerificationStatus.userSubmitted;

  String get firestoreValue => name;

  static PoiVerificationStatus fromString(String? value) {
    return switch (value) {
      'verified' => PoiVerificationStatus.verified,
      'userSubmitted' => PoiVerificationStatus.userSubmitted,
      'pending' => PoiVerificationStatus.pending,
      'reported' => PoiVerificationStatus.reported,
      'rejected' => PoiVerificationStatus.rejected,
      _ => PoiVerificationStatus.unknown,
    };
  }
}

class PoiModel {
  const PoiModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone = '',
    this.website,
    this.is24_7 = false,
    this.isEmergencyService = false,
    this.overnightStay = false,
    this.dayCare = false,
    this.hasYard = false,
    this.pricePerNight,
    this.openingHours = '',
    this.petFriendly = true,
    this.dogFriendlyIndoor,
    this.dogFriendlyOutdoor,
    this.waterAvailable,
    this.isDogPark,
    this.municipality = '',
    this.description = '',
    this.imageUrl,
    this.sourceUrl = '',
    this.city = MapCity.noviSad,
    this.cityId = '',
    this.verificationStatus = PoiVerificationStatus.unknown,
    required this.lastVerified,
    required this.source,
    this.rating,
    this.isSponsored = false,
    this.sponsorName = '',
    this.sponsoredUntil,
    this.sponsorBadge = '',
    this.sponsorPriority = 0,
  });

  final String id;
  final String name;
  final PoiCategory category;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String? website;
  final bool is24_7;
  final bool isEmergencyService;
  final bool overnightStay;
  final bool dayCare;
  final bool hasYard;
  final double? pricePerNight;
  /// Free-text hours, e.g. "Pon–Pet 09–20, Sub 10–14".
  final String openingHours;
  final bool petFriendly;
  final bool? dogFriendlyIndoor;
  final bool? dogFriendlyOutdoor;
  final bool? waterAvailable;
  /// Officially designated (fenced) dog area. Null = not set; legacy docs
  /// fall back to the "Park za pse" naming convention.
  final bool? isDogPark;
  final String municipality;
  final String description;
  final String? imageUrl;
  final String sourceUrl;
  final MapCity city;
  final String cityId;
  final PoiVerificationStatus verificationStatus;
  final DateTime lastVerified;
  final String source;
  final double? rating;
  final bool isSponsored;
  final String sponsorName;
  final DateTime? sponsoredUntil;
  final String sponsorBadge;
  final int sponsorPriority;

  MapPlaceType get mapPlaceType => switch (category) {
        PoiCategory.cafe => MapPlaceType.cafe,
        PoiCategory.restaurant => MapPlaceType.restaurant,
        PoiCategory.park => MapPlaceType.park,
        PoiCategory.petShop => MapPlaceType.petShop,
        PoiCategory.groomer => MapPlaceType.groomer,
        PoiCategory.vet => MapPlaceType.vet,
        PoiCategory.lodging => MapPlaceType.lodging,
        PoiCategory.training => MapPlaceType.training,
        PoiCategory.dogHotel => MapPlaceType.dogHotel,
        PoiCategory.selfWash => MapPlaceType.selfWash,
        PoiCategory.dogTreats => MapPlaceType.dogTreats,
        PoiCategory.shelter => MapPlaceType.shelter,
        PoiCategory.water => MapPlaceType.water,
        PoiCategory.petSitter => MapPlaceType.petSitter,
        PoiCategory.other => MapPlaceType.other,
      };

  String get resolvedCityId {
    if (cityId.isNotEmpty) return cityId;
    return city.cityId;
  }

  PoiModel copyWith({
    String? name,
    String? address,
    PoiCategory? category,
    double? latitude,
    double? longitude,
    PoiVerificationStatus? verificationStatus,
    bool? petFriendly,
    DateTime? lastVerified,
    String? source,
    double? rating,
    String? phone,
    String? website,
    bool clearWebsite = false,
    bool? is24_7,
    bool? isEmergencyService,
    bool? overnightStay,
    bool? dayCare,
    bool? hasYard,
    double? pricePerNight,
    bool clearPricePerNight = false,
    String? openingHours,
    MapCity? city,
    String? cityId,
    String? municipality,
    String? description,
    String? imageUrl,
    String? sourceUrl,
    bool? dogFriendlyIndoor,
    bool? dogFriendlyOutdoor,
    bool? waterAvailable,
    bool? isDogPark,
    bool? isSponsored,
    String? sponsorName,
    DateTime? sponsoredUntil,
    String? sponsorBadge,
    int? sponsorPriority,
  }) {
    return PoiModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      website: clearWebsite ? null : (website ?? this.website),
      is24_7: is24_7 ?? this.is24_7,
      isEmergencyService: isEmergencyService ?? this.isEmergencyService,
      overnightStay: overnightStay ?? this.overnightStay,
      dayCare: dayCare ?? this.dayCare,
      hasYard: hasYard ?? this.hasYard,
      pricePerNight:
          clearPricePerNight ? null : (pricePerNight ?? this.pricePerNight),
      openingHours: openingHours ?? this.openingHours,
      petFriendly: petFriendly ?? this.petFriendly,
      dogFriendlyIndoor: dogFriendlyIndoor ?? this.dogFriendlyIndoor,
      dogFriendlyOutdoor: dogFriendlyOutdoor ?? this.dogFriendlyOutdoor,
      waterAvailable: waterAvailable ?? this.waterAvailable,
      isDogPark: isDogPark ?? this.isDogPark,
      municipality: municipality ?? this.municipality,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      lastVerified: lastVerified ?? this.lastVerified,
      source: source ?? this.source,
      rating: rating ?? this.rating,
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorName: sponsorName ?? this.sponsorName,
      sponsoredUntil: sponsoredUntil ?? this.sponsoredUntil,
      sponsorBadge: sponsorBadge ?? this.sponsorBadge,
      sponsorPriority: sponsorPriority ?? this.sponsorPriority,
    );
  }
}
