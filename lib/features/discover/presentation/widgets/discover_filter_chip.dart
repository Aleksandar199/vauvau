import 'package:flutter/material.dart';

abstract final class DiscoverFilterStyle {
  static const Color selectedFill = Color(0xFF1A1A1A);
  static const Color selectedLabel = Color(0xFFFFFFFF);
  static const Color idleFill = Color(0xFFFFFFFF);
  static const Color idleLabel = Color(0xFF1A1A1A);
  static const Color idleBorder = Color(0xFF94A3B8);
  static const Color walkDot = Color(0xFF2E7D32);

  static ButtonStyle chipStyle({required bool selected}) {
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        selected ? selectedFill : idleFill,
      ),
      foregroundColor: WidgetStatePropertyAll(
        selected ? selectedLabel : idleLabel,
      ),
      overlayColor: WidgetStatePropertyAll(
        selectedFill.withValues(alpha: 0.12),
      ),
      side: WidgetStatePropertyAll(
        selected ? BorderSide.none : const BorderSide(color: idleBorder),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class WalkStatusDot extends StatelessWidget {
  const WalkStatusDot({super.key, this.size = 8});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: DiscoverFilterStyle.walkDot,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0xB34CAF50), blurRadius: 6)],
      ),
    );
  }
}

class DiscoverFilterChip extends StatelessWidget {
  const DiscoverFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected
        ? DiscoverFilterStyle.selectedLabel
        : DiscoverFilterStyle.idleLabel;
    return TextButton(
      style: DiscoverFilterStyle.chipStyle(selected: selected),
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
