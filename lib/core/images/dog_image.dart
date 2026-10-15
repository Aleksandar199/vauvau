import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import '../widgets/feed_state.dart';
import 'dog_photo_urls.dart';
import 'fallback_image_helper.dart';
import 'firebase_web_image.dart';

export 'fallback_image_helper.dart';

Uint8List? decodeDataImageBytes(String url) {
  if (!url.startsWith('data:image')) {
    return null;
  }
  final comma = url.indexOf(',');
  if (comma < 0 || comma == url.length - 1) {
    return null;
  }
  try {
    return base64Decode(url.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

Widget buildDogImage(
  String? url, {
  String seed = '',
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return DogImage(
    url: url,
    seed: seed,
    width: width,
    height: height,
    fit: fit,
  );
}

class DogImage extends StatelessWidget {
  const DogImage({
    super.key,
    required this.url,
    this.seed = '',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String? url;
  final String seed;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Shown instead of the dog illustration when there is no usable image
  /// (e.g. a person placeholder for owner photos).
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    if (isUnusableDogPhotoUrl(value)) {
      return _sized(child: _fallback());
    }
    if (value.startsWith('data:image')) {
      final bytes = decodeDataImageBytes(value);
      if (bytes == null || bytes.isEmpty) {
        return _sized(child: _fallback());
      }
      return _sized(
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      );
    }
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        StorageService.isGsUri(value)) {
      return _sized(child: _network(value));
    }
    return _sized(child: _fallback());
  }

  /// Fill parent when width/height are omitted (StoryRing / grid cells).
  Widget _sized({required Widget child}) {
    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: child);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedWidth &&
            constraints.hasBoundedHeight &&
            constraints.maxWidth.isFinite &&
            constraints.maxHeight.isFinite &&
            constraints.maxWidth > 0 &&
            constraints.maxHeight > 0;
        if (!bounded) {
          return child;
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: child,
        );
      },
    );
  }

  Widget _fallback() {
    return fallback ??
        DogIllustrationFallback(seed: seed, width: width, height: height);
  }

  Widget _placeholder() {
    return SoftPlaceholder(width: width, height: height);
  }

  Widget _network(String src) {
    return _networkImage(src, isIllustrationFallback: false);
  }

  Widget _networkImage(String src, {required bool isIllustrationFallback}) {
    if (!isIllustrationFallback && StorageService.isFirebaseStorageUrl(src)) {
      return _FirebaseStorageImage(
        url: src,
        width: width,
        height: height,
        fit: fit,
        placeholder: _placeholder(),
        broken: fallback ?? _broken(),
      );
    }

    return CachedNetworkImage(
      imageUrl: src,
      cacheKey: src,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (context, url) => _placeholder(),
      errorWidget: (context, url, error) {
        debugPrint('DogImage load failed url=$url error=$error');
        if (!isIllustrationFallback) {
          return _fallback();
        }
        return _broken();
      },
    );
  }

  Widget _broken() {
    return ColoredBox(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 28),
      ),
    );
  }
}

/// Loads Firebase Storage images.
///
/// Prefer HTTPS download URLs via [Image.network]. If Firestore still has a
/// legacy `gs://` URI, resolve it to HTTPS first; fall back to SDK bytes.
class _FirebaseStorageImage extends StatefulWidget {
  const _FirebaseStorageImage({
    required this.url,
    required this.fit,
    required this.placeholder,
    required this.broken,
    this.width,
    this.height,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget placeholder;
  final Widget broken;

  @override
  State<_FirebaseStorageImage> createState() => _FirebaseStorageImageState();
}

class _FirebaseStorageImageState extends State<_FirebaseStorageImage> {
  String? _httpsUrl;
  Uint8List? _bytes;
  Object? _error;
  var _loading = true;
  var _bytesFallbackStarted = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant _FirebaseStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _prepare();
    }
  }

  Future<void> _prepare() async {
    final raw = widget.url.trim();
    setState(() {
      _loading = true;
      _error = null;
      _bytes = null;
      _httpsUrl = null;
      _bytesFallbackStarted = false;
    });

    try {
      if (StorageService.isHttpsDownloadUrl(raw) &&
          !StorageService.isGsUri(raw)) {
        if (!mounted || widget.url.trim() != raw) {
          return;
        }
        setState(() {
          _httpsUrl = raw;
          _loading = false;
        });
        return;
      }

      // Legacy gs:// rows (or anything that isn't a browser-loadable URL).
      final https = await StorageService().resolveDownloadUrl(raw);
      if (!mounted || widget.url.trim() != raw) {
        return;
      }
      setState(() {
        _httpsUrl = https;
        _loading = false;
      });
    } catch (error, stack) {
      debugPrint(
        'DogImage Firebase resolve failed url=$raw error=$error',
      );
      debugPrint('$stack');
      // getData() also hits CORS on web — skip bytes fallback there.
      if (kIsWeb) {
        if (!mounted || widget.url.trim() != raw) {
          return;
        }
        setState(() {
          _error = error;
          _loading = false;
        });
        return;
      }
      try {
        final bytes = await StorageService().downloadBytes(raw);
        if (!mounted || widget.url.trim() != raw) {
          return;
        }
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      } catch (bytesError, bytesStack) {
        debugPrint(
          'DogImage Firebase bytes failed url=$raw error=$bytesError',
        );
        debugPrint('$bytesStack');
        if (!mounted || widget.url.trim() != raw) {
          return;
        }
        setState(() {
          _error = bytesError;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadBytesFallback() async {
    if (_bytesFallbackStarted) {
      return;
    }
    _bytesFallbackStarted = true;
    final raw = widget.url.trim();
    try {
      final bytes = await StorageService().downloadBytes(
        _httpsUrl ?? raw,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _httpsUrl = null;
        _error = null;
      });
    } catch (error, stack) {
      debugPrint(
        'DogImage Firebase network→bytes fallback failed url=$raw error=$error',
      );
      debugPrint('$stack');
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.placeholder;
    }
    if (_error != null) {
      return widget.broken;
    }
    if (_bytes != null && _bytes!.isNotEmpty) {
      return _memoryImage(_bytes!);
    }
    final https = _httpsUrl;
    if (https == null || https.isEmpty) {
      return widget.broken;
    }

    // Flutter web (CanvasKit) cannot decode Storage URLs without bucket CORS —
    // Image.network fails with statusCode 0. A real HTML <img> still paints.
    if (kIsWeb) {
      return buildFirebaseWebImage(
        url: https,
        fit: widget.fit,
        placeholder: widget.placeholder,
        errorWidget: widget.broken,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = widget.width ??
            (constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : null);
        final h = widget.height ??
            (constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null);
        return Image.network(
          https,
          width: w,
          height: h,
          fit: widget.fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          alignment: Alignment.center,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return widget.placeholder;
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              'DogImage Firebase Image.network failed url=$https error=$error',
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _bytes == null && _error == null) {
                _loadBytesFallback();
              }
            });
            return widget.placeholder;
          },
        );
      },
    );
  }

  Widget _memoryImage(Uint8List bytes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = widget.width ??
            (constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : null);
        final h = widget.height ??
            (constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null);
        return Image.memory(
          bytes,
          width: w,
          height: h,
          fit: widget.fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              'DogImage Firebase decode failed url=${widget.url} error=$error',
            );
            return widget.broken;
          },
        );
      },
    );
  }
}
