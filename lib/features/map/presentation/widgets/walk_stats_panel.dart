import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_cards.dart';
import '../../../../core/network/connectivity_controller.dart';
import '../../../../core/network/network_strings.dart';
import '../../../location/domain/location_access.dart';
import '../../../location/presentation/location_controller.dart';
import '../../../rewards/presentation/widgets/walk_result_dialog.dart';
import '../../domain/walk_session.dart';
import '../../domain/walk_tracking.dart';
import '../map_strings.dart';
import '../walk_controller.dart';
import 'walk_history_sheet.dart';

class WalkStatsPanel extends ConsumerWidget {
  const WalkStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walk = ref.watch(walkControllerProvider);
    final distance = walk.distanceLabel;
    // Compact panel: the map stays visible behind it during a walk.
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 42),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: AppCardTokens.softShadow(0.12),
        ),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    height: 30,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                    child: _PrimaryStat(
                      value: distance,
                      label: MapStrings.walkDistance,
                    ),
                  ),
                  IconButton(
                    tooltip: MapStrings.walkHistory,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showWalkHistorySheet(context),
                    icon: const Icon(Icons.history),
                  ),
                ],
              ),
              WalkTrackingStatus(walk: walk),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: buttonStyle,
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
                        size: 20,
                      ),
                      label: Text(
                        walk.isPaused
                            ? MapStrings.resumeWalk
                            : MapStrings.pauseWalk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: buttonStyle.copyWith(
                        backgroundColor: const WidgetStatePropertyAll(
                          Color(0xFFB91C1C),
                        ),
                        foregroundColor: const WidgetStatePropertyAll(
                          Colors.white,
                        ),
                      ),
                      onPressed: () => _confirmEnd(context, ref),
                      icon: const Icon(Icons.stop, size: 20),
                      label: Text(MapStrings.endWalk),
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
      final distance = session.distanceLabel;
      final duration = session.elapsedLabel;
      final saving = ref.read(walkControllerProvider.notifier).end();
      if (!context.mounted) return;
      // Reward dialog once Firestore answers (or the write is queued).
      unawaited(
        saving.then((result) {
          if (result != null && context.mounted) {
            showWalkResultIfNeeded(context, result);
          }
        }),
      );
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

/// Top banner during a walk: GPS state, privacy note, and a note when there is
/// no internet (the walk keeps running and is saved later).
class WalkGpsBanner extends ConsumerWidget {
  const WalkGpsBanner({super.key, required this.isPaused});

  final bool isPaused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(
      networkStateProvider.select((state) => state.isOffline),
    );
    const textStyle = TextStyle(
      fontSize: 11,
      color: Colors.white,
      fontWeight: FontWeight.w500,
      height: 1.25,
    );
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPaused ? Icons.pause_circle_filled : Icons.gps_fixed,
                  size: 16,
                  color: isPaused ? Colors.amber : const Color(0xFF4ADE80),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPaused
                        ? MapStrings.gpsPausedBanner
                        : MapStrings.gpsActiveBanner,
                    style: textStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 14, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${MapStrings.privacyRouteOnlyYou} '
                    '${MapStrings.privacyOthersApprox}',
                    style: textStyle.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
            if (offline) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.wifi_off, size: 14, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      NetworkStrings.walkOffline,
                      style: textStyle.copyWith(color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ],
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// GPS state under the walk stats: signal, permission/GPS problems and the
/// "vehicle" warning, so a poor signal is never shown as precise km.
class WalkTrackingStatus extends ConsumerWidget {
  const WalkTrackingStatus({super.key, required this.walk});

  final WalkSession walk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = walk.issue;
    final rows = <Widget>[];
    if (issue != WalkTrackingIssue.none) {
      final text = switch (issue) {
        WalkTrackingIssue.permissionDenied => MapStrings.gpsPermissionIssue,
        WalkTrackingIssue.servicesDisabled => MapStrings.gpsServicesIssue,
        WalkTrackingIssue.unavailable => MapStrings.gpsUnavailableIssue,
        _ => MapStrings.gpsStreamIssue,
      };
      rows.add(
        _StatusRow(
          icon: Icons.location_disabled,
          color: const Color(0xFFB91C1C),
          text: text,
          action: issue == WalkTrackingIssue.unavailable
              ? null
              : TextButton(
                  onPressed: () async {
                    final access = await ref
                        .read(userLocationProvider.notifier)
                        .requestPermission();
                    if (!access.canTrack) {
                      await ref.read(locationClientProvider).openAppSettings();
                      return;
                    }
                    ref.read(walkControllerProvider.notifier).retryGps();
                  },
                  child: Text(MapStrings.gpsRetry),
                ),
        ),
      );
    } else if (!walk.isPaused) {
      final (icon, color, text) = switch (walk.signal) {
        GpsSignal.searching => (
            Icons.gps_not_fixed,
            const Color(0xFF92400E),
            MapStrings.gpsSearching,
          ),
        GpsSignal.good => (
            Icons.gps_fixed,
            const Color(0xFF15803D),
            MapStrings.gpsGood,
          ),
        GpsSignal.weak => (
            Icons.gps_not_fixed,
            const Color(0xFFB45309),
            MapStrings.gpsWeak,
          ),
        GpsSignal.lost => (
            Icons.gps_off,
            const Color(0xFFB91C1C),
            MapStrings.gpsLost,
          ),
      };
      rows.add(_StatusRow(icon: icon, color: color, text: text));
    }
    if (walk.track.vehicleDetected) {
      rows.add(
        _StatusRow(
          icon: Icons.directions_car,
          color: const Color(0xFFB45309),
          text: MapStrings.vehicleDetected,
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.text,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
