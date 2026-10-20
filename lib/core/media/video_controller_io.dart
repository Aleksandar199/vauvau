import 'dart:io';

import 'package:video_player/video_player.dart';

/// A local file path (picked / downloaded video) or an https URL.
VideoPlayerController videoControllerFor(String pathOrUrl) {
  if (pathOrUrl.startsWith('https://') || pathOrUrl.startsWith('http://')) {
    return VideoPlayerController.networkUrl(Uri.parse(pathOrUrl));
  }
  return VideoPlayerController.file(File(pathOrUrl));
}
