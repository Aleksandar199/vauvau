import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Place categories shown on the map. City is an attribute on the place,
/// not hardcoded into category logic.
enum MapPlaceType {
  park,
  cafe,
  restaurant,
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

extension MapPlaceTypeVisuals on MapPlaceType {
  IconData get icon => switch (this) {
        MapPlaceType.park => Icons.pets,
        MapPlaceType.cafe => Icons.local_cafe,
        MapPlaceType.restaurant => Icons.restaurant,
        MapPlaceType.petShop => Icons.shopping_bag_outlined,
        MapPlaceType.groomer => Icons.content_cut,
        MapPlaceType.vet => Icons.medical_services_outlined,
        MapPlaceType.lodging => Icons.hotel_outlined,
        MapPlaceType.training => Icons.school_outlined,
        MapPlaceType.dogHotel => Icons.night_shelter_outlined,
        MapPlaceType.selfWash => Icons.bathtub_outlined,
        MapPlaceType.dogTreats => Icons.bakery_dining_outlined,
        MapPlaceType.shelter => Icons.volunteer_activism_outlined,
        MapPlaceType.water => Icons.water_drop_outlined,
        MapPlaceType.petSitter => Icons.home_outlined,
        MapPlaceType.other => Icons.place_outlined,
      };

  Color get pinColor => switch (this) {
        MapPlaceType.park => AppColors.success,
        MapPlaceType.cafe => AppColors.cafe,
        MapPlaceType.restaurant => const Color(0xFFEA580C),
        MapPlaceType.petShop => const Color(0xFF7C3AED),
        MapPlaceType.groomer => const Color(0xFFEC4899),
        MapPlaceType.vet => const Color(0xFF0EA5E9),
        MapPlaceType.lodging => const Color(0xFF6366F1),
        MapPlaceType.training => const Color(0xFFCA8A04),
        MapPlaceType.dogHotel => const Color(0xFFB45309),
        MapPlaceType.selfWash => const Color(0xFF06B6D4),
        MapPlaceType.dogTreats => const Color(0xFFD97706),
        MapPlaceType.shelter => const Color(0xFF16A34A),
        MapPlaceType.water => const Color(0xFF0284C7),
        MapPlaceType.petSitter => const Color(0xFF0D9488),
        MapPlaceType.other => const Color(0xFF64748B),
      };

  String get filterLabel => switch (this) {
        MapPlaceType.park => 'Parkovi',
        MapPlaceType.cafe => 'Kafići',
        MapPlaceType.restaurant => 'Restorani',
        MapPlaceType.petShop => 'Pet Shop',
        MapPlaceType.groomer => 'Grooming',
        MapPlaceType.vet => 'Veterinar',
        MapPlaceType.lodging => 'Smeštaj',
        MapPlaceType.training => 'Dresura',
        MapPlaceType.dogHotel => 'Pansion',
        MapPlaceType.selfWash => 'Perionica',
        MapPlaceType.dogTreats => 'Hrana',
        MapPlaceType.shelter => 'Udomljavanje',
        MapPlaceType.water => 'Voda',
        MapPlaceType.petSitter => 'Čuvanje',
        MapPlaceType.other => 'Ostalo',
      };
}
