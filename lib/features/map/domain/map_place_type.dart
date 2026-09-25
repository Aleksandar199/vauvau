import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum MapPlaceType { park, cafe, petShop, groomer, vet, dogHotel, petSitter }

extension MapPlaceTypeVisuals on MapPlaceType {
  IconData get icon => switch (this) {
        MapPlaceType.park => Icons.park,
        MapPlaceType.cafe => Icons.local_cafe,
        MapPlaceType.petShop => Icons.storefront,
        MapPlaceType.groomer => Icons.content_cut,
        MapPlaceType.vet => Icons.medical_services_outlined,
        MapPlaceType.dogHotel => Icons.night_shelter_outlined,
        MapPlaceType.petSitter => Icons.home_outlined,
      };

  Color get pinColor => switch (this) {
        MapPlaceType.park => AppColors.success,
        MapPlaceType.cafe => AppColors.cafe,
        MapPlaceType.petShop => const Color(0xFF7C3AED),
        MapPlaceType.groomer => const Color(0xFFEC4899),
        MapPlaceType.vet => const Color(0xFF0EA5E9),
        MapPlaceType.dogHotel => const Color(0xFFB45309),
        MapPlaceType.petSitter => const Color(0xFF0D9488),
      };
}
