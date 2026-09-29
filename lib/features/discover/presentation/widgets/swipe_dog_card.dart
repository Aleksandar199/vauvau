import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ui_bits.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/discover_profile.dart';
import '../discover_controller.dart';
import '../discover_strings.dart';
import 'compatibility_card.dart';
import 'match_dialog.dart';

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
        child: Column(
          children: [
            Expanded(
              child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
              child: buildDogImage(url, seed: widget.profile.id),
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
            FallbackIllustrationCaption(url: url),
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
                      CompatibilityCard(other: profile),
                      const SizedBox(height: 16),
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
                      if (profile.likesTags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          '🐕 Voli',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in profile.likesTags)
                              PersonalityBadge(label: tag),
                          ],
                        ),
                      ],
                      if (profile.dislikesTags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          '❌ Ne voli',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in profile.dislikesTags)
                              PersonalityBadge(label: tag),
                          ],
                        ),
                      ],
                      if (profile.bio.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          DiscoverStrings.about,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(profile.bio),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        DiscoverStrings.owner,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      _OwnerRow(
                        ownerId: profile.ownerId,
                        ownerName: profile.ownerName,
                      ),
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
                profile: profile,
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
    required this.profile,
    required this.onClose,
    this.onMessage,
    this.onReport,
  });

  final DiscoverProfile profile;
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
                _LikeButton(profile: profile),
                const SizedBox(width: 4),
                _SuperLikeButton(profile: profile),
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

class _OwnerRow extends StatefulWidget {
  const _OwnerRow({required this.ownerId, required this.ownerName});

  final String ownerId;
  final String ownerName;

  @override
  State<_OwnerRow> createState() => _OwnerRowState();
}

class _OwnerRowState extends State<_OwnerRow> {
  late final Future<String> _photoFuture = _loadPhoto();

  Future<String> _loadPhoto() async {
    if (widget.ownerId.isEmpty) {
      return '';
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ownerId)
          .get();
      final data = snapshot.data();
      if (data == null) {
        return '';
      }
      final custom = (data['customPhotoUrl'] as String?)?.trim() ?? '';
      if (custom.isNotEmpty) {
        return custom;
      }
      return (data['photoUrl'] as String?)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FutureBuilder<String>(
          future: _photoFuture,
          builder: (context, snapshot) {
            final url = snapshot.data ?? '';
            final usable =
                url.startsWith('http://') || url.startsWith('https://');
            return CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              child: ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: usable
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return const Icon(
                              Icons.person,
                              size: 20,
                              color: AppColors.primaryDeep,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person,
                          size: 20,
                          color: AppColors.primaryDeep,
                        ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.ownerName,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _LikeButton extends ConsumerStatefulWidget {
  const _LikeButton({required this.profile});

  final DiscoverProfile profile;

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
  var _liked = false;
  var _busy = false;
  var _mine = false;
  var _committed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLiked());
  }

  Future<void> _loadLiked() async {
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    final mine = uid.isNotEmpty &&
        (widget.profile.ownerId == uid ||
            widget.profile.id ==
                ref.read(discoverControllerProvider).myDog.id);
    var liked = _liked || _committed;
    if (!_committed && uid.isNotEmpty && !mine) {
      liked = await ref.read(discoverRepositoryProvider).hasLiked(
            userId: uid,
            dogId: widget.profile.id,
          );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _mine = mine;
      if (!_committed) {
        _liked = liked;
      }
    });
  }

  bool _isNetworkError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'network-request-failed';
    }
    final text = error.toString().toLowerCase();
    return text.contains('socket') || text.contains('network');
  }

  Future<void> _tap() async {
    if (_liked || _busy || _mine) {
      return;
    }
    setState(() {
      _busy = true;
      _liked = true;
      _committed = true;
    });
    try {
      final isMatch = await ref.read(discoverControllerProvider.notifier).swipe(
            widget.profile,
            'like',
          );
      if (!mounted) {
        return;
      }
      if (isMatch) {
        await showMatchDialogIfNeeded(
          context: context,
          ref: ref,
          matched: widget.profile,
          isMatch: true,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(DiscoverStrings.likedToast)),
        );
      }
    } catch (error) {
      debugPrint('DOG LIKE ERROR for: ${widget.profile.id} $error');
      if (!mounted) {
        return;
      }
      if (_isNetworkError(error)) {
        setState(() {
          _liked = false;
          _committed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(DiscoverStrings.likeFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mine) {
      return const SizedBox.shrink();
    }
    return IconButton.filled(
      tooltip: _liked ? DiscoverStrings.liked : DiscoverStrings.like,
      onPressed: _tap,
      style: IconButton.styleFrom(
        backgroundColor: _liked ? const Color(0xFFE11D48) : AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(_liked ? Icons.favorite : Icons.favorite_border),
    );
  }
}

class _SuperLikeButton extends ConsumerStatefulWidget {
  const _SuperLikeButton({required this.profile});

  final DiscoverProfile profile;

  @override
  ConsumerState<_SuperLikeButton> createState() => _SuperLikeButtonState();
}

class _SuperLikeButtonState extends ConsumerState<_SuperLikeButton> {
  var _busy = false;
  var _mine = false;
  var _sent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
      final mine = uid.isNotEmpty &&
          (widget.profile.ownerId == uid ||
              widget.profile.id ==
                  ref.read(discoverControllerProvider).myDog.id);
      if (mounted) {
        setState(() => _mine = mine);
      }
    });
  }

  Future<void> _tap() async {
    if (_busy || _mine) {
      return;
    }
    setState(() => _busy = true);
    try {
      final isMatch = await ref.read(discoverControllerProvider.notifier).swipe(
            widget.profile,
            'superLike',
          );
      if (!mounted) {
        return;
      }
      setState(() => _sent = true);
      if (isMatch) {
        await showMatchDialogIfNeeded(
          context: context,
          ref: ref,
          matched: widget.profile,
          isMatch: true,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(DiscoverStrings.superLikedToast)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(DiscoverStrings.likeFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mine) {
      return const SizedBox.shrink();
    }
    return IconButton.filled(
      tooltip: DiscoverStrings.superLike,
      onPressed: _tap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.superLike,
        foregroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(_sent ? Icons.star : Icons.star_border),
    );
  }
}