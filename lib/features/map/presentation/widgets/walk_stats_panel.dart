import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_cards.dart';
import '../map_strings.dart';
import '../walk_controller.dart';
import 'walk_history_sheet.dart';

class WalkStatsPanel extends ConsumerWidget {
  const WalkStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walk = ref.watch(walkControllerProvider);
    final distanceKm = walk.distanceKm;
    final distance = distanceKm.toStringAsFixed(2);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppCardTokens.softShadow(0.12),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryStat(
                      value: walk.elapsedLabel,
                      label: MapStrings.walkTime,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                    child: _PrimaryStat(
                      value: distance,
                      label: MapStrings.walkDistance,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => showWalkHistorySheet(context),
                  child: Text(MapStrings.walkHistory),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          final notifier =
                              ref.read(walkControllerProvider.notifier);
                          if (walk.isPaused) {
                            notifier.resume();
                          } else {
                            notifier.pause();
                          }
                        },
                        icon: Icon(
                          walk.isPaused ? Icons.play_arrow : Icons.pause,
                        ),
                        label: Text(
                          walk.isPaused
                              ? MapStrings.resumeWalk
                              : MapStrings.pauseWalk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _confirmEnd(context, ref),
                        icon: const Icon(Icons.stop),
                        label: Text(MapStrings.endWalk),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(MapStrings.endWalkTitle),
          content: Text(MapStrings.endWalkBody),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(MapStrings.endWalk),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(MapStrings.cancel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      final session = ref.read(walkControllerProvider);
      final distance = session.distanceKm.toStringAsFixed(2);
      final duration = session.elapsedLabel;
      ref.read(walkControllerProvider.notifier).end();
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${MapStrings.walkSaved} $duration · $distance km',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            // No SnackBarAction: with an action Flutter keeps the bar until
            // the user dismisses it when accessibility timing is enabled.
          ),
        );
      Future<void>.delayed(const Duration(seconds: 3), () {
        messenger.hideCurrentSnackBar();
      });
    }
  }
}

class WalkGpsBanner extends StatelessWidget {
  const WalkGpsBanner({super.key, required this.isPaused});

  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isPaused ? Icons.pause_circle_filled : Icons.gps_fixed,
              size: 16,
              color: isPaused ? Colors.amber : const Color(0xFF4ADE80),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                isPaused
                    ? MapStrings.gpsPausedBanner
                    : MapStrings.gpsActiveBanner,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryStat extends StatelessWidget {
  const _PrimaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
