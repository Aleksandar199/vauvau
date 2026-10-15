import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/network/network_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ui_bits.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../chat/presentation/chat_inbox.dart';
import '../../../chat/presentation/chat_screen.dart';
import '../../../moderation/domain/content_report.dart';
import '../../../moderation/presentation/safety_menu.dart';
import '../../../moments/presentation/widgets/story_widgets.dart';
import '../../../profile/data/owner_public_profile.dart';
import '../../../profile/presentation/owner_profile_sheet.dart';
import '../../../profile/presentation/profile_strings.dart';
import '../../domain/discover_profile.dart';
import '../../domain/discover_repository.dart';
import '../discover_controller.dart';
import '../discover_strings.dart';
import 'compatibility_card.dart';
import 'dog_photo_gallery.dart';
import 'match_dialog.dart';

class SwipeDogCard extends StatefulWidget {
  const SwipeDogCard({super.key, required this.profile, this.compact = false});

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
        : Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white);

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
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.35),
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
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
                      child: DistancePill(label: widget.profile.distanceLabel),
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
                                child: Text(
                                  profile.headline,
                                  style: titleStyle,
                                ),
                              ),
                              GenderIcon(gender: profile.gender),
                            ],
                          ),
                          if (!widget.compact) ...[
                            const SizedBox(height: 4),
                            Text(
                              profile.subtitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
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
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white),
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

class DogDetailSheet extends StatelessWidget {
  const DogDetailSheet({super.key, required this.profile});

  final DiscoverProfile profile;

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
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: controller,
                      padding: EdgeInsets.zero,
                      children: [
                        DogPhotoGallery(
                          photos: profile.photoUrls,
                          seed: profile.id,
                          height: (MediaQuery.sizeOf(context).height * 0.52)
                              .clamp(300.0, 560.0),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          child: _DetailBody(profile: profile),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55000000),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: const CircleBorder(),
                        child: SafetyMenuButton(
                          reportedUserId: profile.ownerId,
                          targetId: profile.id,
                          targetType: ReportContentType.dog,
                          iconColor: Colors.white,
                          onBlocked: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ProfileActionBar(
                profile: profile,
                onClose: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.profile});

  final DiscoverProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                profile.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GenderIcon(gender: profile.gender, color: AppColors.primary),
            const SizedBox(width: 10),
            Flexible(child: _StatusPill(profile: profile)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${profile.breed} · ${profile.ageLabel}',
          style: theme.textTheme.titleMedium?.copyWith(color: muted),
        ),
        if (profile.location.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  profile.location,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 16),
        Row(
          children: [
            MetricStatChip(value: profile.ageLabel, label: DiscoverStrings.age),
            SizedBox(width: 8),
            MetricStatChip(
              value: profile.sizeLabel,
              label: DiscoverStrings.size,
            ),
            SizedBox(width: 8),
            MetricStatChip(
              value: profile.genderLabel,
              label: DiscoverStrings.gender,
            ),
          ],
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: _EnergyTile(level: profile.energyLevel)),
              if (profile.weightKg > 0) ...[
                SizedBox(width: 8),
                MetricStatChip(
                  value: DiscoverStrings.weightValue(profile.weightKg),
                  label: DiscoverStrings.weight,
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
        CompatibilityCard(other: profile),
        if (profile.bio.trim().isNotEmpty)
          _DetailSection(
            title: DiscoverStrings.about,
            child: Text(
              profile.bio.trim(),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
          ),
        _DogStoriesBlock(dogId: profile.id),
        _DetailSection(
          title: DiscoverStrings.health,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HealthBadge(
                label: DiscoverStrings.vaccinated,
                ok: profile.vaccinated,
              ),
              _HealthBadge(
                label: DiscoverStrings.sterilized,
                ok: profile.sterilized,
              ),
              _HealthBadge(label: DiscoverStrings.chipped, ok: profile.chipped),
            ],
          ),
        ),
        if (profile.traitLabels.isNotEmpty)
          _DetailSection(
            title: DiscoverStrings.traits,
            child: _BadgeWrap(labels: profile.traitLabels),
          ),
        if (profile.getsAlongLabels.isNotEmpty)
          _DetailSection(
            title: DiscoverStrings.getsAlong,
            child: _BadgeWrap(labels: profile.getsAlongLabels),
          ),
        if (profile.likeLabels.isNotEmpty)
          _DetailSection(
            title: DiscoverStrings.likes,
            icon: Icons.favorite_border_rounded,
            child: _BadgeWrap(labels: profile.likeLabels),
          ),
        if (profile.dislikeLabels.isNotEmpty)
          _DetailSection(
            title: DiscoverStrings.dislikes,
            icon: Icons.do_not_disturb_alt_rounded,
            child: _BadgeWrap(labels: profile.dislikeLabels),
          ),
        _DetailSection(
          title: DiscoverStrings.owner,
          child: _OwnerRow(
            ownerId: profile.ownerId,
            ownerName: profile.ownerName,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.profile});

  final DiscoverProfile profile;

  @override
  Widget build(BuildContext context) {
    final label = profile.statusBadge;
    final lower = label.toLowerCase();
    final Color color;
    if (lower.contains('tražim') ||
        lower.contains('looking') ||
        lower.contains('play')) {
      color = const Color(0xFFB45309);
    } else if (lower.contains('odmar') || lower.contains('rest')) {
      color = const Color(0xFF475569);
    } else if (profile.walking ||
        lower.contains('šetnj') ||
        lower.contains('walk')) {
      color = const Color(0xFF15803D);
    } else {
      color = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EnergyTile extends StatelessWidget {
  const _EnergyTile({required this.level});

  final String level;

  int get _filled {
    switch (level) {
      case 'visoka':
      case 'high':
        return 3;
      case 'niska':
      case 'low':
        return 1;
      default:
        return 2;
    }
  }

  String get _label => switch (_filled) {
        3 => DiscoverStrings.energyHigh,
        1 => DiscoverStrings.energyLow,
        _ => DiscoverStrings.energyMid,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                _label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              Spacer(),
              Text(
                DiscoverStrings.energyShort,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < _filled
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DogStoriesBlock extends StatelessWidget {
  const _DogStoriesBlock({required this.dogId});

  final String dogId;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: DiscoverStrings.stories,
      icon: Icons.auto_stories_outlined,
      child: DogStoriesSection(dogId: dogId),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BadgeWrap extends StatelessWidget {
  const _BadgeWrap({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final label in labels) PersonalityBadge(label: label)],
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF15803D) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionBar extends ConsumerWidget {
  const _ProfileActionBar({required this.profile, required this.onClose});

  final DiscoverProfile profile;
  final VoidCallback onClose;

  bool _isOwnProfile(WidgetRef ref) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final myDogId = ref.watch(discoverControllerProvider).myDog.id;
    final ownerId = profile.ownerId.trim();
    if (uid.isNotEmpty && ownerId.isNotEmpty && ownerId == uid) {
      return true;
    }
    return myDogId.isNotEmpty && profile.id == myDogId;
  }

  Future<void> _handleMessage(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    final ownerId = profile.ownerId.trim();

    if (_isOwnProfile(ref) || (uid.isNotEmpty && ownerId == uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DiscoverStrings.ownProfileMessage)),
      );
      return;
    }
    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DiscoverStrings.messageUnavailable)),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final chatId = ref.read(chatInboxProvider.notifier).openFromMatch(profile);
    navigator.pop();
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: chatId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
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
                SizedBox(width: 4),
                _SuperLikeButton(profile: profile),
                SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    // Always non-null — own-profile/missing-owner handled in tap.
                    onPressed: () => _handleMessage(context, ref),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(DiscoverStrings.sendMessage),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
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

/// Owner avatar + name; tapping it opens the owner's public profile popup
/// (loaded by [ownerId], never by name).
class _OwnerRow extends ConsumerStatefulWidget {
  const _OwnerRow({required this.ownerId, required this.ownerName});

  final String ownerId;
  final String ownerName;

  @override
  ConsumerState<_OwnerRow> createState() => _OwnerRowState();
}

class _OwnerRowState extends ConsumerState<_OwnerRow> {
  late final Future<String> _photoFuture = _loadPhoto();
  var _photoUrl = '';

  void _openOwner() {
    showOwnerProfileSheet(
      context,
      userId: widget.ownerId,
      fallbackName: widget.ownerName,
      fallbackAvatarUrl: _photoUrl,
      loader: ref.read(ownerProfileLoaderProvider),
    );
  }

  Future<String> _loadPhoto() async {
    final url = await _fetchPhoto();
    _photoUrl = url;
    return url;
  }

  Future<String> _fetchPhoto() async {
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
    final theme = Theme.of(context);
    final canOpen = widget.ownerId.trim().isNotEmpty;
    final row = Row(
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
                      ? DogImage(
                          url: url,
                          seed: url,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
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
            key: const ValueKey('discover-owner-name'),
            style: canOpen
                ? theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryDeep.withValues(
                      alpha: 0.4,
                    ),
                  )
                : theme.textTheme.bodyLarge,
          ),
        ),
        if (canOpen)
          const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDeep),
      ],
    );
    if (!canOpen) {
      return row;
    }
    return Semantics(
      button: true,
      label: ProfileStrings.openOwnerProfile,
      child: InkWell(
        key: const ValueKey('discover-owner-row'),
        borderRadius: BorderRadius.circular(12),
        onTap: _openOwner,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      ),
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
    final mine =
        uid.isNotEmpty &&
        (widget.profile.ownerId == uid ||
            widget.profile.id == ref.read(discoverControllerProvider).myDog.id);
    var liked = _liked || _committed;
    if (!_committed && uid.isNotEmpty && !mine) {
      liked = await ref
          .read(discoverRepositoryProvider)
          .hasLiked(userId: uid, dogId: widget.profile.id);
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

  bool _isNetworkError(Object error) => isNetworkFailure(error);

  Future<void> _tap() async {
    if (_busy || _mine) {
      return;
    }
    setState(() => _busy = true);
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _committed = true;
    });
    try {
      if (wasLiked) {
        final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
        if (uid.isEmpty) {
          setState(() {
            _liked = wasLiked;
            _committed = wasLiked;
            _busy = false;
          });
          return;
        }
        await ref
            .read(discoverRepositoryProvider)
            .unlike(userId: uid, dogId: widget.profile.id);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(DiscoverStrings.unlikedToast)),
        );
      } else {
        final isMatch = await ref
            .read(discoverControllerProvider.notifier)
            .swipe(widget.profile, 'like');
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
            SnackBar(content: Text(DiscoverStrings.likedToast)),
          );
        }
      }
    } catch (error) {
      debugPrint('DOG LIKE ERROR for: ${widget.profile.id} $error');
      if (!mounted) {
        return;
      }
      if (_isNetworkError(error)) {
        setState(() {
          _liked = wasLiked;
          _committed = wasLiked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(DiscoverStrings.likeFailed)),
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
      final mine =
          uid.isNotEmpty &&
          (widget.profile.ownerId == uid ||
              widget.profile.id ==
                  ref.read(discoverControllerProvider).myDog.id);
      if (mounted) {
        setState(() => _mine = mine);
      }
    });
  }

  Future<void> _showDailyLimitDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(DiscoverStrings.superLikeDailyLimitTitle),
        content: Text(DiscoverStrings.superLikeDailyLimitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(DiscoverStrings.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessPopup() async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(milliseconds: 2500), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 48),
                SizedBox(height: 12),
                Text(
                  DiscoverStrings.superLikeSuccessTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  DiscoverStrings.superLikedDog(widget.profile.name),
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
                Text(
                  DiscoverStrings.superLikeSuccessHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _tap() async {
    if (_busy || _mine || _sent) {
      return;
    }
    setState(() => _busy = true);
    try {
      final isMatch = await ref
          .read(discoverControllerProvider.notifier)
          .sendSuperLike(widget.profile);
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
        await _showSuccessPopup();
      }
    } on SuperLikeDailyLimitException {
      if (mounted) {
        await _showDailyLimitDialog();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(DiscoverStrings.superLikeFailed)),
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
    final active = _sent;
    return IconButton.filled(
      tooltip: DiscoverStrings.superLike,
      onPressed: (_busy || active) ? null : _tap,
      style: IconButton.styleFrom(
        backgroundColor: active ? Colors.amber : Colors.amber.shade600,
        disabledBackgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
      ),
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(active ? Icons.star : Icons.star_border),
    );
  }
}
