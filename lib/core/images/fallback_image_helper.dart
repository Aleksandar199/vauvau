import 'package:flutter/material.dart';

import '../theme/app_cards.dart';
import 'dog_photo_urls.dart';

abstract final class FallbackImageHelper {
  static const String badgeLabel = 'Ilustrovana slika';

  static const Color captionBackground = Color(0xFFFFF3E0);
  static const Color captionForeground = Color(0xFF666666);

  static const List<String> illustrationUrls = [
    'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1568572933382-74d440642117?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1507146426996-ef05306b995a?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1558788353-f76d92427f16?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&w=800&q=80',
  ];

  static String getRandomFallbackImage(String seed) {
    final index = seed.hashCode.abs() % illustrationUrls.length;
    return illustrationUrls[index];
  }

  static bool shouldUseFallback(String? url) => isUnusableDogPhotoUrl(url);
}

class FallbackIllustrationCaption extends StatelessWidget {
  const FallbackIllustrationCaption({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (!FallbackImageHelper.shouldUseFallback(url)) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ImageOverlayBadge(
          label: FallbackImageHelper.badgeLabel,
          dark: false,
          fontSize: 10,
        ),
      ),
    );
  }
}
