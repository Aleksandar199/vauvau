import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_time.dart';
import '../../domain/scheduled_walk.dart';
import '../chat_strings.dart';

class ScheduledWalksBanner extends StatefulWidget {
  const ScheduledWalksBanner({super.key, required this.walks});

  final List<ScheduledWalk> walks;

  @override
  State<ScheduledWalksBanner> createState() => _ScheduledWalksBannerState();
}

class _ScheduledWalksBannerState extends State<ScheduledWalksBanner> {
  bool _expanded = false;

  static const _textStyle = TextStyle(
    color: AppColors.ink,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.25,
  );

  @override
  Widget build(BuildContext context) {
    final walks = widget.walks;
    if (walks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Always use a dropdown — a single-line row truncates on small phones.
    return _BannerShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(Icons.pets, color: AppColors.primary, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${ChatStrings.scheduledWalks} (${walks.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.ink,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            for (final walk in walks)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Text(
                  _walkLabel(walk),
                  style: _textStyle.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _walkLabel(ScheduledWalk walk) {
    return '${walk.dogName} · ${walk.locationName} · '
        '${formatWalkStamp(walk.walkTime)}';
  }
}

class _BannerShell extends StatelessWidget {
  const _BannerShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: child,
      ),
    );
  }
}
