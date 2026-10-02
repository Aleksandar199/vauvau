import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/compatibility.dart';
import '../../domain/discover_profile.dart';
import '../discover_controller.dart';

class CompatibilityCard extends ConsumerWidget {
  const CompatibilityCard({super.key, required this.other, this.light = false});

  final DiscoverProfile other;
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(discoverControllerProvider).myDog;
    if (mine.id.isEmpty || mine.id == other.id) {
      return const SizedBox.shrink();
    }
    final insight = describeCompatibility(mine: mine, other: other);
    final fg = light ? Colors.white : const Color(0xFF14532D);
    final bg = light ? const Color(0x33FFFFFF) : const Color(0xFFE8F5E9);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.28)),
      ),
      child: Text(
        insight.headline,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, height: 1.35),
      ),
    );
  }
}
