import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_cards.dart';
import '../../domain/adoption_dog.dart';
import '../adoption_strings.dart';

class AdoptionCard extends StatelessWidget {
  const AdoptionCard({
    super.key,
    required this.dog,
    required this.onTap,
  });

  final AdoptionDog dog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = dog.photoUrl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppCardTokens.borderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: AppCardTokens.borderRadius,
            boxShadow: AppCardTokens.softShadow(0.08),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: AppCardTokens.imageBorderRadius,
                        child: buildDogImage(url, seed: dog.id),
                      ),
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: StatusBadge(
                          label: AdoptionStrings.badge,
                          tone: StatusBadgeTone.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FallbackIllustrationCaption(url: url),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardTitleText(text: '${dog.name} · ${dog.age}'),
                    const SizedBox(height: 2),
                    Text(
                      dog.breed,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CardLocationRow(label: dog.location),
                    const SizedBox(height: 2),
                    CardTimeLabel(label: AdoptionStrings.timeAgo(dog.createdAt)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
