import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared card surface tokens for Zone 1+ feed UI.
abstract final class AppCardTokens {
  static const double radius = 16;
  static const double imageRadius = 12;
  static const double actionHeight = 52;
  static const double actionRadius = 14;

  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  static BorderRadius get imageBorderRadius =>
      BorderRadius.circular(imageRadius);

  static BorderRadius get heroBottomRadius =>
      const BorderRadius.vertical(bottom: Radius.circular(24));

  /// Outer spacing around each feed card.
  static const EdgeInsets outerMargin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  /// Inner content padding inside a card.
  static const EdgeInsets innerPadding = EdgeInsets.all(12);

  static List<BoxShadow> softShadow([double opacity = 0.04]) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

enum StatusBadgeTone { urgent, warning, success, neutral, primary }

/// Vibrant status / urgency badge for Lost, Adoption, Events cards.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusBadgeTone.urgent,
  });

  final String label;
  final StatusBadgeTone tone;

  Color get _background {
    return switch (tone) {
      StatusBadgeTone.urgent => Colors.red.shade700,
      StatusBadgeTone.warning => const Color(0xFFEA580C),
      StatusBadgeTone.success => const Color(0xFF15803D),
      StatusBadgeTone.neutral => const Color(0xFF475569),
      StatusBadgeTone.primary => AppColors.primaryDeep,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Compact overlay chip for status / illustration labels on photos.
class ImageOverlayBadge extends StatelessWidget {
  const ImageOverlayBadge({
    super.key,
    required this.label,
    this.dark = true,
    this.fontSize = 11,
  });

  final String label;
  final bool dark;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : const Color(0xFF475569),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}

class CardLocationRow extends StatelessWidget {
  const CardLocationRow({
    super.key,
    required this.label,
    this.iconColor,
  });

  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 14,
          color: iconColor ?? Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class CardTimeLabel extends StatelessWidget {
  const CardTimeLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
      ),
    );
  }
}

class CardTitleText extends StatelessWidget {
  const CardTitleText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }
}

/// Full-width primary action used on detail bottom bars.
class DetailPrimaryButton extends StatelessWidget {
  const DetailPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppCardTokens.actionRadius),
    );
    const textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    if (filled) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppCardTokens.actionHeight),
          shape: shape,
          textStyle: textStyle,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppCardTokens.actionHeight),
        shape: shape,
        textStyle: textStyle,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.margin = AppCardTokens.outerMargin,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppCardTokens.borderRadius,
        boxShadow: AppCardTokens.softShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: padding == null
          ? child
          : Padding(padding: padding!, child: child),
    );
    if (onTap == null) {
      return card;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppCardTokens.borderRadius,
        child: card,
      ),
    );
  }
}
