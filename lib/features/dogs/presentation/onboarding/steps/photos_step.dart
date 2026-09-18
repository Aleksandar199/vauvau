import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_strings.dart';

class PhotosStep extends StatelessWidget {
  const PhotosStep({
    super.key,
    required this.photos,
    required this.onAddGallery,
    required this.onAddCamera,
    required this.onRemove,
  });

  final List<XFile> photos;
  final VoidCallback onAddGallery;
  final VoidCallback onAddCamera;
  final ValueChanged<int> onRemove;

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
              onPressed: photos.length >= 5 ? null : onAddGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text(AppStrings.addFromGallery),
            ),
            OutlinedButton.icon(
              onPressed: photos.length >= 5 ? null : onAddCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text(AppStrings.addFromCamera),
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
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder(
                    future: photos[index].readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const ColoredBox(
                          color: Color(0x11000000),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton.filled(
                    onPressed: () => onRemove(index),
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
