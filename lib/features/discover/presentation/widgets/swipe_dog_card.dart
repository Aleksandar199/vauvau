import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ui_bits.dart';
import '../../domain/discover_profile.dart';
import '../discover_image.dart';
import '../discover_strings.dart';

class SwipeDogCard extends StatefulWidget {
  const SwipeDogCard({
    super.key,
    required this.profile,
    this.compact = false,
  });

  final DiscoverProfile profile;
  final bool compact;

  @override
  State<SwipeDogCard> createState() => _SwipeDogCardState();
}

class _SwipeDogCardState extends State<SwipeDogCard> {
  int _photoIndex = 0;

  void _cyclePhoto() {
    final photos = widget.profile.photoUrls;
    if (photos.length < 2) {
      return;
    }
    setState(() => _photoIndex = (_photoIndex + 1) % photos.length);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final photos = profile.photoUrls;
    final url = photos.isEmpty
        ? ''
        : photos[_photoIndex.clamp(0, photos.length - 1)];
    final titleStyle = widget.compact
        ? Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)
        : Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.compact ? 16 : 24),
        boxShadow: widget.compact ? const [] : AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.compact ? 16 : 24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
              child: url.isEmpty
                  ? const Icon(Icons.pets, size: 72)
                  : Image(
                      image: discoverImageOf(context, url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.pets, size: 72));
                      },
                    ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x00000000),
                    Color(0xE60F172A),
                  ],
                ),
              ),
            ),
            if (!widget.compact && photos.length > 1)
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _cyclePhoto,
                  child: Row(
                    children: [
                      for (var i = 0; i < photos.length; i++)
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i == _photoIndex
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (!widget.compact)
              Positioned(
                top: 28,
                right: 16,
                child: DistancePill(label: profile.distanceLabel),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(widget.compact ? 12 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(profile.headline, style: titleStyle),
                        ),
                        GenderIcon(gender: profile.gender),
                      ],
                    ),
                    if (!widget.compact) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.subtitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in profile.traits.take(3))
                            PersonalityBadge(label: tag),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpecChip extends StatelessWidget {
  const SpecChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.lightOnBackground,
            ),
          ),
        ],
      ),
    );
  }
}

class DogDetailSheet extends StatelessWidget {
  const DogDetailSheet({
    super.key,
    required this.profile,
    this.onMessage,
    this.onLike,
    this.onPass,
  });

  final DiscoverProfile profile;
  final VoidCallback? onMessage;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.6,
      builder: (context, controller) {
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(DiscoverStrings.close),
                ),
              ),
              SizedBox(
                height: 280,
                child: SwipeDogCard(profile: profile),
              ),
              const SizedBox(height: 16),
              Text(
                DiscoverStrings.details,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SpecChip(label: DiscoverStrings.breed, value: profile.breed),
                  SpecChip(
                    label: DiscoverStrings.age,
                    value: DiscoverStrings.years(profile.ageYears),
                  ),
                  SpecChip(label: DiscoverStrings.size, value: profile.size),
                  SpecChip(
                    label: DiscoverStrings.energy,
                    value: profile.energyLabel,
                  ),
                  SpecChip(
                    label: DiscoverStrings.vaccinated,
                    value: profile.vaccinated
                        ? DiscoverStrings.yes
                        : DiscoverStrings.no,
                  ),
                  SpecChip(
                    label: DiscoverStrings.chipped,
                    value: profile.chipped
                        ? DiscoverStrings.yes
                        : DiscoverStrings.no,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(DiscoverStrings.traits),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in profile.traits) PersonalityBadge(label: tag),
                ],
              ),
              const SizedBox(height: 16),
              Text(DiscoverStrings.owner),
              Text('${profile.ownerName} • ${profile.distanceLabel}'),
              const SizedBox(height: 8),
              Text(DiscoverStrings.location),
              Text(profile.location),
              const SizedBox(height: 8),
              Text(profile.bio),
              const SizedBox(height: 20),
              if (onLike != null || onPass != null) ...[
                Row(
                  children: [
                    if (onPass != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onPass,
                          child: const Text(DiscoverStrings.pass),
                        ),
                      ),
                    if (onLike != null && onPass != null)
                      const SizedBox(width: 8),
                    if (onLike != null)
                      Expanded(
                        child: FilledButton(
                          onPressed: onLike,
                          child: const Text(DiscoverStrings.like),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (onMessage != null) ...[
                FilledButton(
                  onPressed: onMessage,
                  child: const Text(DiscoverStrings.message),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(DiscoverStrings.close),
              ),
            ],
            ),
          ),
        );
      },
    );
  }
}
