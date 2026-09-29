import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/images/dog_image.dart';

class PhotosStep extends StatelessWidget {
  const PhotosStep({
    super.key,
    required this.photos,
    required this.onAddGallery,
    required this.onAddCamera,
    required this.onRemove,
    this.uploading = false,
  });

  final List<String> photos;
  final VoidCallback onAddGallery;
  final VoidCallback onAddCamera;
  final ValueChanged<int> onRemove;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          AppStrings.stepPhotosTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.stepPhotosHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: uploading || photos.length >= 5 ? null : onAddGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text(AppStrings.addFromGallery),
            ),
            OutlinedButton.icon(
              onPressed: uploading || photos.length >= 5 ? null : onAddCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text(AppStrings.addFromCamera),
            ),
            if (uploading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final url = photos[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildDogImage(url, seed: url),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton.filled(
                    tooltip: AppStrings.removePhoto,
                    onPressed: uploading ? null : () => onRemove(index),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
