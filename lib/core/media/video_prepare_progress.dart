import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'video_strings.dart';

/// "Pripremam video… 42%" while a picked video is trimmed / re-encoded.
class VideoPrepareProgress extends StatelessWidget {
  const VideoPrepareProgress({super.key, required this.progress});

  /// 0..1
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('video-preparing'),
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            VideoStrings.preparing(progress),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress <= 0 ? null : progress,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
