import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';

/// Swipeable hero gallery. Shows each photo uncropped over a blurred copy of
/// itself so portrait and landscape shots both fill the frame nicely.
class DogPhotoGallery extends StatefulWidget {
  const DogPhotoGallery({
    super.key,
    required this.photos,
    required this.seed,
    this.height = 420,
  });

  final List<String> photos;
  final String seed;
  final double height;

  @override
  State<DogPhotoGallery> createState() => _DogPhotoGalleryState();
}

class _DogPhotoGalleryState extends State<DogPhotoGallery> {
  late final PageController _controller = PageController();
  int _index = 0;

  List<String> get _photos =>
      widget.photos.isEmpty ? const [''] : widget.photos;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openViewer() async {
    final result = await showDogPhotoViewer(
      context,
      photos: _photos,
      seed: widget.seed,
      initialIndex: _index,
    );
    if (result != null && result != _index && mounted) {
      _controller.jumpToPage(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    final multiple = photos.length > 1;

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, i) => GestureDetector(
              onTap: _openViewer,
              child: BlurBackdropPhoto(url: photos[i], seed: widget.seed),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x66000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          if (multiple) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < photos.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40000000), blurRadius: 4),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 10,
              child: _CounterPill(label: '${_index + 1}/${photos.length}'),
            ),
            if (_index > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _goTo(_index - 1),
                  ),
                ),
              ),
            if (_index < photos.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _goTo(_index + 1),
                  ),
                ),
              ),
          ],
          Positioned(
            left: 14,
            bottom: 10,
            child: _CounterPill(
              icon: Icons.zoom_out_map_rounded,
              label: '',
              onTap: _openViewer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uncropped photo over a blurred copy of itself.
class BlurBackdropPhoto extends StatelessWidget {
  const BlurBackdropPhoto({super.key, required this.url, required this.seed});

  final String url;
  final String seed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DogImage(url: url, seed: seed),
          ),
        ),
        const ColoredBox(color: Color(0x33000000)),
        DogImage(url: url, seed: seed, fit: BoxFit.contain),
      ],
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.label, this.icon, this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label.isEmpty ? 7 : 10,
            vertical: label.isEmpty ? 7 : 4,
          ),
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 18)
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

Future<int?> showDogPhotoViewer(
  BuildContext context, {
  required List<String> photos,
  required String seed,
  int initialIndex = 0,
}) {
  return Navigator.of(context).push<int>(
    PageRouteBuilder<int>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => DogPhotoViewer(
        photos: photos,
        seed: seed,
        initialIndex: initialIndex,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Full-screen, pinch-to-zoom photo viewer. Pops with the last viewed index.
class DogPhotoViewer extends StatefulWidget {
  const DogPhotoViewer({
    super.key,
    required this.photos,
    required this.seed,
    this.initialIndex = 0,
  });

  final List<String> photos;
  final String seed;
  final int initialIndex;

  @override
  State<DogPhotoViewer> createState() => _DogPhotoViewerState();
}

class _DogPhotoViewerState extends State<DogPhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_index);

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: photos.length,
              onPageChanged: (value) => setState(() {
                _index = value;
                _zoomed = false;
              }),
              itemBuilder: (context, i) => _ZoomablePhoto(
                url: photos[i],
                seed: widget.seed,
                onZoomChanged: (zoomed) {
                  if (zoomed != _zoomed) {
                    setState(() => _zoomed = zoomed);
                  }
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: _close,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    if (photos.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${_index + 1} / ${photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    required this.url,
    required this.seed,
    required this.onZoomChanged,
  });

  final String url;
  final String seed;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _transform = TransformationController();
  TapDownDetails? _lastTap;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  void _toggleZoom(TapDownDetails details) {
    if (_isZoomed) {
      _transform.value = Matrix4.identity();
    } else {
      const scale = 2.5;
      final p = details.localPosition;
      _transform.value = Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    widget.onZoomChanged(_isZoomed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _lastTap = details,
      onDoubleTap: () {
        final tap = _lastTap;
        if (tap != null) {
          _toggleZoom(tap);
        }
      },
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 5,
        onInteractionEnd: (_) => widget.onZoomChanged(_isZoomed),
        child: SizedBox.expand(
          child: DogImage(
            url: widget.url,
            seed: widget.seed,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
