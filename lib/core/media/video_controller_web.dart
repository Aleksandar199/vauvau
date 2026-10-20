import 'package:video_player/video_player.dart';

/// On web a picked file's path is a blob: URL; Storage videos are https
/// URLs (a <video> element needs no bucket CORS).
VideoPlayerController videoControllerFor(String pathOrUrl) =>
    VideoPlayerController.networkUrl(Uri.parse(pathOrUrl));
