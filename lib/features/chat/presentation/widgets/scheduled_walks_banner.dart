import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_time.dart';
import '../../domain/scheduled_walk.dart';
import '../chat_strings.dart';

class ScheduledWalksBanner extends StatelessWidget {
  const ScheduledWalksBanner({super.key, required this.walks});

  final List<ScheduledWalk> walks;

  @override
  Widget build(BuildContext context) {
    if (walks.isEmpty) {
      return const SizedBox.shrink();
    }
    final walk = walks.first;
    return Material(
      color: AppColors.primarySoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.pets, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${ChatStrings.scheduledWalks}: ${walk.dogName} · ${walk.locationName} · ${formatWalkStamp(walk.walkTime)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
