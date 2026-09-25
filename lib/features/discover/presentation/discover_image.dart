import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/app_image_provider.dart';

typedef DiscoverImageFactory = ImageProvider Function(String url);

final discoverImageFactoryProvider = Provider<DiscoverImageFactory>((ref) {
  return appImageProvider;
});

ImageProvider discoverImageOf(BuildContext context, String url) {
  return ProviderScope.containerOf(context, listen: false)
      .read(discoverImageFactoryProvider)(url);
}
