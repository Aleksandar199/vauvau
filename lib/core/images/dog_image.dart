import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'dog_photo_urls.dart';
import 'fallback_image_helper.dart';

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
  });

  final String? url;
  final String seed;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    if (isUnusableDogPhotoUrl(value)) {
      return _fallback();
    }
    if (value.startsWith('data:image')) {
      final bytes = decodeDataImageBytes(value);
      if (bytes == null || bytes.isEmpty) {
        return _fallback();
      }
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _network(value, isFallback: false);
    }
    return _fallback();
  }

  Widget _fallback() {
    final src = FallbackImageHelper.getRandomFallbackImage(seed);
    return _network(src, isFallback: true);
  }

  Widget _network(String src, {required bool isFallback}) {
    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        if (!isFallback) {
          return _fallback();
        }
        if (src != kFallbackDogPhotoUrl) {
          return Image.network(
            kFallbackDogPhotoUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                width: width,
                height: height,
                child: ColoredBox(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.pets, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        }
        return SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.pets, color: Colors.grey)),
          ),
        );
      },
    );
  }
}
