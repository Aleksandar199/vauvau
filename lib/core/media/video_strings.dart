import '../l10n/l10n.dart';
import 'video_limits.dart';

abstract final class VideoStrings {
  static String get photo => L10n.tr('Fotografija', 'Photo');
  static String get video => L10n.tr('Video', 'Video');
  static String get gallery => L10n.tr('Galerija', 'Gallery');
  static String get camera => L10n.tr('Kamera', 'Camera');
  static String get recordVideo => L10n.tr('Snimi', 'Record');
  static String get play => L10n.tr('Pusti video', 'Play video');
  static String get pause => L10n.tr('Pauziraj video', 'Pause video');
  static String get mute => L10n.tr('Isključi zvuk', 'Mute');
  static String get unmute => L10n.tr('Uključi zvuk', 'Unmute');
  static String get unavailable =>
      L10n.tr('Video nije dostupan.', 'Video is not available.');

  /// [compresses] = Android / iOS (re-encode + trim); web only checks.
  static String limitHint(Duration max, {bool compresses = true}) =>
      compresses
          ? L10n.tr(
              'Video do ${max.inSeconds} s – duži se skraćuje na prvih ${max.inSeconds} s, a kvalitet se prilagođava (do 720p).',
              'Video up to ${max.inSeconds} s – longer ones keep the first ${max.inSeconds} s, quality is adjusted (up to 720p).',
            )
          : L10n.tr(
              'Video do ${max.inSeconds} s i ${VideoLimits.maxBytes ~/ (1024 * 1024)} MB.',
              'Video up to ${max.inSeconds} s and ${VideoLimits.maxBytes ~/ (1024 * 1024)} MB.',
            );

  static String preparing(double progress) => L10n.tr(
        'Pripremam video… ${(progress * 100).round()}%',
        'Preparing video… ${(progress * 100).round()}%',
      );

  static String trimmed(Duration max) => L10n.tr(
        'Video je bio duži – zadržano je prvih ${max.inSeconds} sekundi.',
        'The video was longer – the first ${max.inSeconds} seconds were kept.',
      );

  static String problem(VideoProblem problem, Duration max) {
    switch (problem) {
      case VideoProblem.tooLong:
        return L10n.tr(
          'Video je predug. Najviše ${max.inSeconds} sekundi – skrati ga u galeriji telefona pa pokušaj ponovo.',
          'The video is too long. At most ${max.inSeconds} seconds – trim it in your gallery and try again.',
        );
      case VideoProblem.tooLarge:
        return L10n.tr(
          'Video je prevelik (najviše ${VideoLimits.maxBytes ~/ (1024 * 1024)} MB). Snimi kraći ili manje kvalitetan video.',
          'The video is too large (max ${VideoLimits.maxBytes ~/ (1024 * 1024)} MB). Record a shorter or lower quality video.',
        );
      case VideoProblem.empty:
        return L10n.tr('Video je prazan.', 'The video is empty.');
      case VideoProblem.unreadable:
        return L10n.tr(
          'Ovaj video ne može da se pročita. Probaj drugi (MP4).',
          'This video cannot be read. Try another one (MP4).',
        );
    }
  }
}
