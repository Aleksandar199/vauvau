import 'package:flutter/material.dart';

import 'map_city.dart';
import 'models/poi_model.dart';
import 'map_place_type.dart';

class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
    this.nearbyDogs = 0,
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
    this.municipality = '',
    this.description = '',
    this.imageUrl,
    this.sourceUrl = '',
    this.city = MapCity.noviSad,
    this.cityId = '',
    this.verificationStatus = PoiVerificationStatus.unknown,
    this.lastVerified,
    this.source = '',
    this.rating,
    this.isSponsored = false,
    this.sponsorName = '',
    this.sponsoredUntil,
    this.sponsorBadge = '',
    this.sponsorPriority = 0,
  });

  factory MapPlace.fromPoi(PoiModel poi) {
    return MapPlace(
      id: poi.id,
      name: poi.name,
      type: poi.mapPlaceType,
      neighborhood: poi.address,
      latitude: poi.latitude,
      longitude: poi.longitude,
      phone: poi.phone,
      website: poi.website,
      is24_7: poi.is24_7,
      isEmergencyService: poi.isEmergencyService,
      overnightStay: poi.overnightStay,
      dayCare: poi.dayCare,
      hasYard: poi.hasYard,
      pricePerNight: poi.pricePerNight,
      openingHours: poi.openingHours,
      petFriendly: poi.petFriendly,
      dogFriendlyIndoor: poi.dogFriendlyIndoor,
      dogFriendlyOutdoor: poi.dogFriendlyOutdoor,
      waterAvailable: poi.waterAvailable,
      municipality: poi.municipality,
      description: poi.description,
      imageUrl: poi.imageUrl,
      sourceUrl: poi.sourceUrl,
      city: poi.city,
      cityId: poi.resolvedCityId,
      verificationStatus: poi.verificationStatus,
      lastVerified: poi.lastVerified,
      source: poi.source,
      rating: poi.rating,
      isSponsored: poi.isSponsored,
      sponsorName: poi.sponsorName,
      sponsoredUntil: poi.sponsoredUntil,
      sponsorBadge: poi.sponsorBadge,
      sponsorPriority: poi.sponsorPriority,
    );
  }

  final String id;
  final String name;
  final MapPlaceType type;
  final String neighborhood;
  final double latitude;
  final double longitude;
  final int nearbyDogs;
  final String phone;
  final String? website;
  final bool is24_7;
  final bool isEmergencyService;
  final bool overnightStay;
  final bool dayCare;
  final bool hasYard;
  final double? pricePerNight;
  final String openingHours;
  final bool petFriendly;
  final bool? dogFriendlyIndoor;
  final bool? dogFriendlyOutdoor;
  final bool? waterAvailable;
  final String municipality;
  final String description;
  final String? imageUrl;
  final String sourceUrl;
  final MapCity city;
  final String cityId;
  final PoiVerificationStatus verificationStatus;
  final DateTime? lastVerified;
  final String source;
  final double? rating;
  final bool isSponsored;
  final String sponsorName;
  final DateTime? sponsoredUntil;
  final String sponsorBadge;
  final int sponsorPriority;

  String get address => neighborhood;

  Color get pinColor => isEmergencyService
      ? const Color(0xFFDC2626)
      : type.pinColor;

  bool get isHotel =>
      type == MapPlaceType.dogHotel || type == MapPlaceType.lodging;

  MapPlace copyWith({
    PoiVerificationStatus? verificationStatus,
    bool? petFriendly,
    DateTime? lastVerified,
  }) {
    return MapPlace(
      id: id,
      name: name,
      type: type,
      neighborhood: neighborhood,
      latitude: latitude,
      longitude: longitude,
      nearbyDogs: nearbyDogs,
      phone: phone,
      website: website,
      is24_7: is24_7,
      isEmergencyService: isEmergencyService,
      overnightStay: overnightStay,
      dayCare: dayCare,
      hasYard: hasYard,
      pricePerNight: pricePerNight,
      openingHours: openingHours,
      petFriendly: petFriendly ?? this.petFriendly,
      dogFriendlyIndoor: dogFriendlyIndoor,
      dogFriendlyOutdoor: dogFriendlyOutdoor,
      waterAvailable: waterAvailable,
      municipality: municipality,
      description: description,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
      city: city,
      cityId: cityId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      lastVerified: lastVerified ?? this.lastVerified,
      source: source,
      rating: rating,
      isSponsored: isSponsored,
      sponsorName: sponsorName,
      sponsoredUntil: sponsoredUntil,
      sponsorBadge: sponsorBadge,
      sponsorPriority: sponsorPriority,
    );
  }
}
