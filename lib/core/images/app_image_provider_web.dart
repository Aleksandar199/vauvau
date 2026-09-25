import 'package:flutter/widgets.dart';

ImageProvider appImageProvider(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }
  if (trimmed.startsWith('assets/')) {
    return AssetImage(trimmed);
  }
  return NetworkImage(trimmed);
}
