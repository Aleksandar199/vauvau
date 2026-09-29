import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/images/dog_photo_urls.dart';

class DiscoverDogPhoto extends StatelessWidget {
  const DiscoverDogPhoto({
    super.key,
    required this.urls,
    this.dogName = '',
    this.seed = '',
    this.fit = BoxFit.cover,
  });

  final List<String> urls;
  final String dogName;
  final String seed;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final unique = uniquePhotoUrls(urls);
    return Semantics(
      label: dogName,
      image: true,
      child: buildDogImage(
        unique.isEmpty ? null : unique.first,
        seed: seed.isEmpty ? dogName : seed,
        fit: fit,
      ),
    );
  }
}
