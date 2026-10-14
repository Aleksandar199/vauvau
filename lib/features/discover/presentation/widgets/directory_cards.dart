import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../domain/discover_profile.dart';
import '../discover_strings.dart';
import 'discover_dog_photo.dart';
import 'discover_filter_chip.dart';

class DiscoverGridCard extends StatelessWidget {
  const DiscoverGridCard({
    super.key,
    required this.profile,
    required this.onTap,
    this.isMine = false,
    this.onLongPress,
  });

  final DiscoverProfile profile;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: isMine ? 4 : 2,
      shadowColor: isMine
          ? theme.colorScheme.primary.withValues(alpha: 0.4)
          : Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMine
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.35),
          width: isMine ? 2.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DiscoverDogPhoto(
                    urls: profile.photoUrls,
                    dogName: profile.name,
                    seed: profile.id,
                  ),
                  if (profile.statusBadge.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _StatusBadge(
                        label: profile.statusBadge,
                        highlight: profile.walking,
                      ),
                    ),
                  if (isMine)
                    const Positioned(top: 8, right: 8, child: _OwnerBadge()),
                ],
              ),
            ),
            FallbackIllustrationCaption(url: profile.photoUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: profile.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' ${profile.ageLabel}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    profile.breed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.distanceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.68,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.highlight});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlight) ...[
            const WalkStatusDot(size: 6),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  const _OwnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DiscoverStrings.yourPet,
        style: TextStyle(
          color: Color(0xFF1F1F2A),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
