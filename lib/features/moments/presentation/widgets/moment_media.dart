import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/media/tap_to_play_video.dart';
import '../../domain/moment_model.dart';

/// Small square / grid preview of a moment: the photo, or a "video" tile
/// (no frame is downloaded for a thumbnail).
class MomentThumb extends StatelessWidget {
  const MomentThumb({super.key, required this.moment, this.iconSize = 28});

  final MomentModel moment;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (moment.isVideo) {
      return VideoThumbnail(
        key: ValueKey('moment-video-thumb-${moment.id}'),
        iconSize: iconSize,
      );
    }
    return buildDogImage(moment.momentPhotoUrl, seed: moment.id);
  }
}

/// Cover URL usable as an image: videos are skipped ('' when there is none).
String momentImageUrl(MomentModel moment) =>
    moment.isVideo ? '' : moment.momentPhotoUrl;
