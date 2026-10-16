import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/reward_rules.dart';
import '../challenge_hub_screen.dart';
import '../rewards_controller.dart';
import '../rewards_strings.dart';

/// Compact "Dnevni VauVau izazov" button on the map: level + points.
/// Watches only reward providers, so it rebuilds on its own (not the map).
class ChallengeEntryCard extends ConsumerWidget {
  const ChallengeEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = RewardsPalette.of(context);
    final summary = ref.watch(rewardSummaryProvider).value;
    final level = LevelRules.levelFor(summary?.xp ?? 0);
    return Material(
      color: palette.card,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ChallengeHubScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: palette.accentSoft,
                child: Icon(level.icon, color: palette.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RewardsStrings.hubTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      summary == null
                          ? RewardsStrings.entrySubtitle
                          : '${level.name} · ${summary.xp} XP · '
                                '${RewardsStrings.points(summary.points)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }
}
