import 'package:flutter/material.dart';

import '../../domain/reward_rules.dart';
import '../../domain/rewards_models.dart';
import '../rewards_strings.dart';

/// After "Završi šetnju": XP/points, challenges, level-up or why nothing
/// was paid. Plain short walks keep only the snackbar.
Future<void> showWalkResultIfNeeded(
  BuildContext context,
  WalkSaveResult result,
) async {
  final reason = result.ineligibleReason;
  final noteworthy =
      result.totalXp > 0 ||
      result.pendingSync ||
      result.rewardDenied ||
      result.alreadyRewarded ||
      result.capped ||
      (reason != null &&
          reason != WalkIneligibleReason.tooShort &&
          reason != WalkIneligibleReason.notSignedIn);
  if (!noteworthy) return;
  final unlocked = LevelRules.unlocked(result.xpBefore, result.xpAfter);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => WalkResultDialog(result: result),
  );
  if (unlocked != null && context.mounted) {
    await showLevelUpDialog(context, unlocked);
  }
}

Future<void> showLevelUpDialog(BuildContext context, RewardLevel level) {
  final palette = RewardsPalette.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: palette.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: CircleAvatar(
        radius: 32,
        backgroundColor: palette.accentSoft,
        child: Icon(level.icon, size: 34, color: palette.accent),
      ),
      title: Text(
        RewardsStrings.levelUpTitle,
        style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
      ),
      content: Text(
        RewardsStrings.levelUpBody(level),
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.text),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: palette.accent),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(RewardsStrings.ok),
        ),
      ],
    ),
  );
}

class WalkResultDialog extends StatelessWidget {
  const WalkResultDialog({super.key, required this.result});

  final WalkSaveResult result;

  @override
  Widget build(BuildContext context) {
    final palette = RewardsPalette.of(context);
    final reason = result.ineligibleReason;
    final lines = <String>[
      if (result.capped) RewardsStrings.cappedNote,
      if (result.alreadyRewarded) RewardsStrings.alreadyRewarded,
      if (result.pendingSync) RewardsStrings.pendingSync,
      if (result.rewardDenied) RewardsStrings.rewardDenied,
      if (reason != null && result.totalXp == 0)
        RewardsStrings.ineligible(reason),
      for (final entry in result.challengeEntries)
        RewardsStrings.challengeDone(entry.reason.replaceFirst('Izazov: ', '')),
    ];
    return AlertDialog(
      backgroundColor: palette.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        RewardsStrings.walkResultTitle,
        style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.totalXp > 0 || result.totalPoints > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                RewardsStrings.reward(result.totalXp, result.totalPoints),
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(line, style: TextStyle(color: palette.text)),
            ),
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: palette.accent),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(RewardsStrings.ok),
        ),
      ],
    );
  }
}
