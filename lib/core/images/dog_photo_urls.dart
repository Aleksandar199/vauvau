/// Empty on purpose — never persist stock Unsplash (or any CDN) as a dog photo.
const String kFallbackDogPhotoUrl = '';

List<String> collectPhotoUrls(Map<String, dynamic> data) {
  final urls = <String>[];
  void add(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      if (_isPersistablePhoto(trimmed)) {
        urls.add(trimmed);
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        add(item);
      }
    }
  }

  add(data['photoUrl']);
  add(data['imageUrl']);
  add(data['image']);
  add(data['photos']);
  add(data['galleryUrls']);
  add(data['photoUrls']);
  return uniquePhotoUrls(urls);
}

List<String> uniquePhotoUrls(Iterable<String> raw) {
  final unique = <String>[];
  for (final url in raw) {
    final trimmed = _rawHttpUrl(url);
    if (!_isPersistablePhoto(trimmed) || unique.contains(trimmed)) {
      continue;
    }
    unique.add(trimmed);
  }
  return unique;
}

String resolvedDogPhotoUrl(Iterable<String> urls) {
  final unique = uniquePhotoUrls(urls);
  return unique.isEmpty ? '' : unique.first;
}

bool isUnusableDogPhotoUrl(String? url) {
  final value = url?.trim() ?? '';
  return value.isEmpty ||
      value == 'null' ||
      value.startsWith('blob:') ||
      value.startsWith('placeholder:') ||
      _isStockCdnPhoto(value);
}

bool isStockCdnPhotoUrl(String? url) => _isStockCdnPhoto(url?.trim() ?? '');

Map<String, dynamic> firestorePhotoFields(List<String> urls) {
  final unique = uniquePhotoUrls(urls);
  if (unique.isEmpty) {
    return {
      'photoUrl': '',
      'imageUrl': '',
      'photos': <String>[],
      'photoUrls': <String>[],
      'galleryUrls': <String>[],
    };
  }
  final primary = unique.first;
  return {
    'photoUrl': primary,
    'imageUrl': primary,
    'photos': unique,
    'photoUrls': unique,
    'galleryUrls': unique,
  };
}

String _rawHttpUrl(String value) {
  final trimmed = value.trim();
  final markdown = RegExp(r'^\[(https?://[^\]]+)\]\([^)]+\)$');
  final match = markdown.firstMatch(trimmed);
  if (match != null) {
    return match.group(1)!;
  }
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    return trimmed.substring(1, trimmed.length - 1).trim();
  }
  return trimmed;
}

bool _isPersistablePhoto(String value) {
  if (value.isEmpty ||
      value == 'null' ||
      value.startsWith('blob:') ||
      value.startsWith('placeholder:') ||
      value.startsWith('data:') ||
      _isStockCdnPhoto(value)) {
    return false;
  }
  return value.startsWith('http://') || value.startsWith('https://');
}

bool _isStockCdnPhoto(String value) {
  if (value.isEmpty) {
    return false;
  }
  final lower = value.toLowerCase();
  return lower.contains('images.unsplash.com') ||
      lower.contains('source.unsplash.com') ||
      lower.contains('picsum.photos') ||
      lower.contains('placekitten.com') ||
      lower.contains('loremflickr.com');
}
