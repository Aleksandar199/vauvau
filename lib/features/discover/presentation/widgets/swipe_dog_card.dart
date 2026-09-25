import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ui_bits.dart';
import '../../domain/discover_profile.dart';
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
              child: buildDogImage(url),
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
                child: DistancePill(
                  label: widget.profile.distanceLabel,
                ),
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
                          for (final tag in profile.traitLabels.take(3))
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
    this.onReport,
  });

  final DiscoverProfile profile;
  final VoidCallback? onMessage;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.6,
      builder: (context, controller) {
        return Material(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 280,
                        child: SwipeDogCard(profile: profile),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        DiscoverStrings.details,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SpecChip(
                            label: DiscoverStrings.breed,
                            value: profile.breed,
                          ),
                          SpecChip(
                            label: DiscoverStrings.age,
                            value: profile.ageLabel,
                          ),
                          SpecChip(
                            label: DiscoverStrings.gender,
                            value: profile.genderLabel,
                          ),
                          SpecChip(
                            label: DiscoverStrings.size,
                            value: profile.sizeLabel,
                          ),
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
                            label: DiscoverStrings.sterilized,
                            value: profile.sterilized
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
                      if (profile.getsAlongLabels.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          DiscoverStrings.getsAlong,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in profile.getsAlongLabels)
                              PersonalityBadge(label: item),
                          ],
                        ),
                      ],
                      if (profile.traitLabels.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          DiscoverStrings.traits,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final tag in profile.traitLabels)
                              PersonalityBadge(label: tag),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        DiscoverStrings.about,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(profile.bio),
                      const SizedBox(height: 16),
                      Text(
                        DiscoverStrings.owner,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text('${profile.ownerName} • ${profile.distanceLabel}'),
                      const SizedBox(height: 8),
                      Text(
                        DiscoverStrings.location,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(profile.location),
                    ],
                  ),
                ),
              ),
              _ProfileActionBar(
                onClose: () => Navigator.of(context).pop(),
                onMessage: onMessage,
                onReport: onReport,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileActionBar extends StatelessWidget {
  const _ProfileActionBar({
    required this.onClose,
    this.onMessage,
    this.onReport,
  });

  final VoidCallback onClose;
  final VoidCallback? onMessage;
  final VoidCallback? onReport;

  Future<void> _confirmReport(BuildContext context) async {
    if (onReport == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(DiscoverStrings.reportConfirmTitle),
          content: const Text(DiscoverStrings.reportConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(DiscoverStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(DiscoverStrings.reportConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      onReport!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.cardShadow,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: DiscoverStrings.close,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text(DiscoverStrings.sendMessage),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: DiscoverStrings.reportProfile,
                  onPressed: onReport == null
                      ? null
                      : () => _confirmReport(context),
                  icon: Icon(
                    Icons.flag_outlined,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
