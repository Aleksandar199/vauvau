import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_cards.dart';
import '../theme/app_colors.dart';
import 'dog_photo_urls.dart';

abstract final class FallbackImageHelper {
  static const String badgeLabel = 'Ilustrovana slika';

  static const Color captionBackground = Color(0xFFFFF3E0);
  static const Color captionForeground = Color(0xFF666666);

  /// Display-only stock dog photos (never persist — see [dog_photo_urls]).
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

  /// Soft tile behind the network illustration while it loads / on error.
  static const List<Color> illustrationColors = [
    Color(0xFFFFE0B2),
    Color(0xFFFFCCBC),
    Color(0xFFC8E6C9),
    Color(0xFFBBDEFB),
    Color(0xFFE1BEE7),
    Color(0xFFFFF9C4),
    Color(0xFFB2EBF2),
    Color(0xFFDCEDC8),
    Color(0xFFFFCDD2),
    Color(0xFFD7CCC8),
  ];

  static Color colorForSeed(String seed) {
    if (illustrationColors.isEmpty) {
      return const Color(0xFFE2E8F0);
    }
    final index = seed.hashCode.abs() % illustrationColors.length;
    return illustrationColors[index];
  }

  /// Deterministic pick from [illustrationUrls] for the same seed.
  static String getRandomFallbackImage(String seed) {
    if (illustrationUrls.isEmpty) {
      return '';
    }
    final index = seed.hashCode.abs() % illustrationUrls.length;
    return illustrationUrls[index];
  }

  static bool shouldUseFallback(String? url) => isUnusableDogPhotoUrl(url);
}

/// Network dog illustration when a post/profile has no real photo.
/// URLs are display-only — never written to Firestore as user photos.
class DogIllustrationFallback extends StatelessWidget {
  const DogIllustrationFallback({
    super.key,
    this.seed = '',
    this.width,
    this.height,
  });

  final String seed;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final url = FallbackImageHelper.getRandomFallbackImage(seed);
    final placeholder = _localPlaceholder();
    if (url.isEmpty) {
      return placeholder;
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, _) => placeholder,
      errorWidget: (context, _, _) => placeholder,
      fadeInDuration: const Duration(milliseconds: 180),
    );
  }

  Widget _localPlaceholder() {
    final color = FallbackImageHelper.colorForSeed(seed);
    return ColoredBox(
      color: color,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Icon(
            Icons.pets_rounded,
            color: AppColors.primary.withValues(alpha: 0.55),
            size: _iconSize,
          ),
        ),
      ),
    );
  }

  double get _iconSize {
    final w = width;
    final h = height;
    if (w != null && h != null) {
      final minSide = w < h ? w : h;
      return (minSide * 0.42).clamp(18.0, 48.0);
    }
    return 32;
  }
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
