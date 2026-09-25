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
    this.petFriendly = true,
    this.city = MapCity.noviSad,
    this.verificationStatus = PoiVerificationStatus.unknown,
    this.lastVerified,
    this.source = '',
    this.rating,
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
      petFriendly: poi.petFriendly,
      city: poi.city,
      verificationStatus: poi.verificationStatus,
      lastVerified: poi.lastVerified,
      source: poi.source,
      rating: poi.rating,
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
  final bool petFriendly;
  final MapCity city;
  final PoiVerificationStatus verificationStatus;
  final DateTime? lastVerified;
  final String source;
  final double? rating;

  String get address => neighborhood;

  Color get pinColor => isEmergencyService
      ? const Color(0xFFDC2626)
      : type.pinColor;

  bool get isHotel => type == MapPlaceType.dogHotel;

  MapPlace copyWith({
    PoiVerificationStatus? verificationStatus,
    bool? petFriendly,
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
      petFriendly: petFriendly ?? this.petFriendly,
      city: city,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      lastVerified: lastVerified,
      source: source,
      rating: rating,
    );
  }
}
