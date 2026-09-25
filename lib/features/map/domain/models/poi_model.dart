import '../map_city.dart';
import '../map_place_type.dart';

enum PoiCategory { cafe, park, petShop, vet, dogHotel, petSitter }

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
    this.petFriendly = true,
    this.city = MapCity.noviSad,
    this.verificationStatus = PoiVerificationStatus.unknown,
    required this.lastVerified,
    required this.source,
    this.rating,
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
  final bool petFriendly;
  final MapCity city;
  final PoiVerificationStatus verificationStatus;
  final DateTime lastVerified;
  final String source;
  final double? rating;

  MapPlaceType get mapPlaceType => switch (category) {
        PoiCategory.cafe => MapPlaceType.cafe,
        PoiCategory.park => MapPlaceType.park,
        PoiCategory.petShop => MapPlaceType.petShop,
        PoiCategory.vet => MapPlaceType.vet,
        PoiCategory.dogHotel => MapPlaceType.dogHotel,
        PoiCategory.petSitter => MapPlaceType.petSitter,
      };

  PoiModel copyWith({
    String? name,
    String? address,
    PoiVerificationStatus? verificationStatus,
    bool? petFriendly,
    DateTime? lastVerified,
    String? source,
    double? rating,
    String? phone,
    String? website,
    bool? is24_7,
    bool? isEmergencyService,
    bool? overnightStay,
    bool? dayCare,
    bool? hasYard,
    double? pricePerNight,
    MapCity? city,
  }) {
    return PoiModel(
      id: id,
      name: name ?? this.name,
      category: category,
      address: address ?? this.address,
      latitude: latitude,
      longitude: longitude,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      is24_7: is24_7 ?? this.is24_7,
      isEmergencyService: isEmergencyService ?? this.isEmergencyService,
      overnightStay: overnightStay ?? this.overnightStay,
      dayCare: dayCare ?? this.dayCare,
      hasYard: hasYard ?? this.hasYard,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      petFriendly: petFriendly ?? this.petFriendly,
      city: city ?? this.city,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      lastVerified: lastVerified ?? this.lastVerified,
      source: source ?? this.source,
      rating: rating ?? this.rating,
    );
  }
}
