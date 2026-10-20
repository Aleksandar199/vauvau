import 'package:flutter/material.dart';

import '../../../../core/images/blur_fill_image.dart';
import '../../../../core/images/dog_image.dart';
import '../../../../core/images/dog_photo_urls.dart';
import '../../../../core/theme/app_cards.dart';
import '../../../discover/presentation/widgets/dog_photo_gallery.dart';
import '../../domain/event_model.dart';
import '../events_strings.dart';

/// Event cover: the whole photo (no cropping) on a blurred fill, tap opens
/// the shared full-screen zoom viewer. Events without a real photo keep the
/// illustration fallback and are not tappable.
class EventPhoto extends StatelessWidget {
  const EventPhoto({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final url = event.imageUrl.trim();
    final hasPhoto = !isUnusableDogPhotoUrl(url);
    return BlurFillImage(
      borderRadius: AppCardTokens.imageBorderRadius,
      tapTooltip: EventsStrings.openPhoto,
      onTap: hasPhoto
          ? () => showDogPhotoViewer(context, photos: [url], seed: event.id)
          : null,
      imageBuilder: (fit) => DogImage(url: url, seed: event.id, fit: fit),
    );
  }
}
