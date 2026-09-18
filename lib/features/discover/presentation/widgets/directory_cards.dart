import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ui_bits.dart';
import '../../domain/discover_profile.dart';
import '../discover_image.dart';
import '../discover_strings.dart';

class DiscoverGridCard extends StatelessWidget {
  const DiscoverGridCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final DiscoverProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = profile.photoUrls.isEmpty ? '' : profile.photoUrls.first;
    return Material(
      color: Theme.of(context).cardTheme.color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  url.isEmpty
                      ? const ColoredBox(
                          color: AppColors.primarySoft,
                          child: Icon(Icons.pets, size: 48),
                        )
                      : Image(
                          image: discoverImageOf(context, url),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const ColoredBox(
                              color: AppColors.primarySoft,
                              child: Icon(Icons.pets, size: 48),
                            );
                          },
                        ),
                  if (profile.walking)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: _WalkingBadge(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    profile.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: DistancePill(label: profile.distanceLabel),
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

class DiscoverListCard extends StatelessWidget {
  const DiscoverListCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onMessage,
  });

  final DiscoverProfile profile;
  final VoidCallback onTap;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final url = profile.photoUrls.isEmpty ? '' : profile.photoUrls.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: url.isEmpty
                        ? const ColoredBox(
                            color: AppColors.primarySoft,
                            child: Icon(Icons.pets),
                          )
                        : Image(
                            image: discoverImageOf(context, url),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const ColoredBox(
                                color: AppColors.primarySoft,
                                child: Icon(Icons.pets),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.headline,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(profile.subtitle),
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text('${DiscoverStrings.energy}: ${profile.energyLabel}'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onMessage,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(DiscoverStrings.message),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalkingBadge extends StatelessWidget {
  const _WalkingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        DiscoverStrings.chipWalking,
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
