import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Builds the same image with the requested [BoxFit].
typedef FitImageBuilder = Widget Function(BoxFit fit);

/// Shows the whole image ([BoxFit.contain]) inside a fixed-ratio frame and
/// fills the empty bands with a blurred, dimmed copy of the same image
/// instead of cropping it with [BoxFit.cover].
///
/// On web Firebase Storage images are HTML `<img>` platform views that
/// [ImageFiltered] cannot blur, so the bands use a muted surface color there.
class BlurFillImage extends StatelessWidget {
  const BlurFillImage({
    super.key,
    required this.imageBuilder,
    this.aspectRatio = 16 / 9,
    this.borderRadius = BorderRadius.zero,
    this.onTap,
    this.tapTooltip,
  });

  final FitImageBuilder imageBuilder;
  final double aspectRatio;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final String? tapTooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget frame = Stack(
      fit: StackFit.expand,
      children: [
        if (kIsWeb)
          ColoredBox(color: scheme.surfaceContainerHighest)
        else ...[
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
              tileMode: TileMode.clamp,
            ),
            child: ExcludeSemantics(child: imageBuilder(BoxFit.cover)),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
        ],
        imageBuilder(BoxFit.contain),
      ],
    );
    if (onTap != null) {
      frame = Semantics(
        button: true,
        label: tapTooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: frame,
        ),
      );
    }
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(borderRadius: borderRadius, child: frame),
    );
  }
}

/// Full-screen, pinch-to-zoom preview for an image that is not a URL yet
/// (e.g. a photo picked in a form before upload). URLs use
/// `showDogPhotoViewer`.
Future<void> showImageFullScreen(
  BuildContext context, {
  required FitImageBuilder imageBuilder,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => FullScreenImagePreview(
        imageBuilder: imageBuilder,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class FullScreenImagePreview extends StatelessWidget {
  const FullScreenImagePreview({super.key, required this.imageBuilder});

  final FitImageBuilder imageBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: SizedBox.expand(child: imageBuilder(BoxFit.contain)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
