import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PulseBadge extends StatefulWidget {
  const PulseBadge({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.enabled = true,
  });

  final Widget child;
  final Color color;
  final bool enabled;

  @override
  State<PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulseBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

class PersonalityBadge extends StatelessWidget {
  const PersonalityBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Compact breed / age / vaccine style pill used on profiles.
class DetailPillChip extends StatelessWidget {
  const DetailPillChip({
    super.key,
    required this.label,
    this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value == null || value!.isEmpty ? label : '$label · $value';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryDeep,
        ),
      ),
    );
  }
}

/// Compact metric tile (walks / moments / age).
class MetricStatChip extends StatelessWidget {
  const MetricStatChip({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DistancePill extends StatelessWidget {
  const DistancePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class GenderIcon extends StatelessWidget {
  const GenderIcon({super.key, required this.gender, this.color = Colors.white});

  final String gender;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final male = gender == 'mužjak';
    return Icon(
      male ? Icons.male : Icons.female,
      color: color,
      size: 20,
    );
  }
}
