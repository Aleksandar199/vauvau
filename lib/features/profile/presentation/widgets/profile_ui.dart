import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_cards.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../moments/domain/moment_model.dart';

/// Round profile / dog avatar with white ring and soft elevation.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.url,
    this.size = 96,
    this.seed = '',
    this.uploading = false,
    this.fallbackIcon = Icons.person,
  });

  final String url;
  final double size;
  final String seed;
  final bool uploading;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: AppCardTokens.softShadow(0.08),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: ColoredBox(
          color: AppColors.primarySoft,
          child: uploading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : _content(),
        ),
      ),
    );
  }

  Widget _content() {
    final usable = url.startsWith('http://') || url.startsWith('https://');
    if (!usable) {
      return Icon(
        fallbackIcon,
        color: AppColors.primaryDeep,
        size: size * 0.36,
      );
    }
    return buildDogImage(
      url,
      seed: seed.isEmpty ? url : seed,
      width: size,
      height: size,
    );
  }
}

/// Square 3-column moments gallery.
class ProfileMomentsGrid extends StatelessWidget {
  const ProfileMomentsGrid({
    super.key,
    required this.moments,
    this.onTap,
    this.emptyLabel = 'Još nema momenata.',
  });

  final List<MomentModel> moments;
  final ValueChanged<MomentModel>? onTap;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (moments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          emptyLabel,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final moment = moments[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap == null ? null : () => onTap!(moment),
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: buildDogImage(moment.momentPhotoUrl, seed: moment.id),
            ),
          ),
        );
      },
    );
  }
}

/// Instagram-style count next to the profile photo ("12 / Pratioci").
class ProfileCountTile extends StatelessWidget {
  const ProfileCountTile({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Expanded(
      child: onTap == null
          ? content
          : Semantics(
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}
