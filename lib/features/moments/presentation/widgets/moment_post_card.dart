import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/serbia_locations.dart';
import '../../../../core/images/dog_image.dart';
import '../../../../core/media/tap_to_play_video.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../follows/presentation/follow_button.dart';
import '../../../moderation/domain/content_report.dart';
import '../../../moderation/presentation/report_sheet.dart';
import '../../../moderation/presentation/safety_menu.dart';
import '../../../profile/presentation/owner_profile_sheet.dart';
import '../../domain/moment_model.dart';
import '../moments_controller.dart';
import '../moments_strings.dart';
import '../story_viewer.dart' show openMomentDog;
import 'moment_comments_sheet.dart';

enum _PostAction { share, report, block, delete }

/// One post of the Moments feed: author, optional dog, photo, caption,
/// like / comment / share and the overflow menu (report, block, delete).
class MomentPostCard extends ConsumerWidget {
  const MomentPostCard({super.key, required this.moment});

  final MomentModel moment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final me = ref.watch(momentsMemberIdProvider);
    final isAdmin = ref.watch(isMomentsAdminProvider);
    final isMine = me.isNotEmpty && moment.authorUserId == me;
    final liked = moment.isLikedBy(me);
    final caption = moment.caption.trim();
    final cityName = SerbiaLocations.cityById(moment.cityId)?.name ?? '';
    final place = [
      if (moment.locationName.trim().isNotEmpty) moment.locationName.trim(),
      if (cityName.isNotEmpty &&
          !moment.locationName.toLowerCase().contains(cityName.toLowerCase()))
        cityName,
    ].join(', ');

    return Card(
      key: ValueKey('moment-post-${moment.id}'),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openAuthor(context),
                    child: Semantics(
                      button: true,
                      label: MomentsStrings.openAuthor,
                      child: Row(
                        children: [
                          _Avatar(url: moment.authorPhotoUrl, seed: moment.authorUserId),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  moment.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  [
                                    MomentsStrings.timeAgo(
                                      moment.createdAt,
                                      DateTime.now(),
                                    ),
                                    if (place.isNotEmpty) place,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isMine)
                  CompactFollowButton(
                    ownerId: moment.authorUserId,
                    ownerName: moment.authorName,
                  ),
                PopupMenuButton<_PostAction>(
                  tooltip: MomentsStrings.postOptions,
                  icon: const Icon(Icons.more_horiz),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (action) => _onAction(context, ref, action),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _PostAction.share,
                      child: _MenuRow(
                        icon: Icons.ios_share,
                        label: MomentsStrings.shareAction,
                      ),
                    ),
                    if (!isMine) ...[
                      PopupMenuItem(
                        value: _PostAction.report,
                        child: _MenuRow(
                          icon: Icons.flag_outlined,
                          label: MomentsStrings.reportPost,
                          color: Colors.red.shade700,
                        ),
                      ),
                      PopupMenuItem(
                        value: _PostAction.block,
                        child: _MenuRow(
                          icon: Icons.block,
                          label: MomentsStrings.blockAuthor,
                        ),
                      ),
                    ],
                    if (isMine || isAdmin)
                      PopupMenuItem(
                        value: _PostAction.delete,
                        child: _MenuRow(
                          icon: Icons.delete_outline,
                          label: MomentsStrings.deletePost,
                          color: scheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: liked ? null : () => _toggleLike(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: ColoredBox(
                    color: AppColors.primarySoft,
                    // Video: nothing downloads until tapped; muted; one at
                    // a time across the feed.
                    child: moment.isVideo
                        ? TapToPlayVideo(
                            key: ValueKey('moment-video-${moment.id}'),
                            source: moment.momentPhotoUrl,
                          )
                        : DogImage(
                            url: moment.momentPhotoUrl,
                            seed: moment.id,
                          ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  key: ValueKey('moment-like-${moment.id}'),
                  tooltip: liked ? MomentsStrings.unlike : MomentsStrings.like,
                  onPressed: () => _toggleLike(context, ref),
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? const Color(0xFFDC2626) : null,
                  ),
                ),
                IconButton(
                  key: ValueKey('moment-comments-${moment.id}'),
                  tooltip: MomentsStrings.comment,
                  onPressed: () => showMomentCommentsSheet(context, moment),
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                if (moment.commentsCount > 0)
                  Text(
                    '${moment.commentsCount}',
                    style: theme.textTheme.labelLarge,
                  ),
                IconButton(
                  tooltip: MomentsStrings.shareAction,
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.ios_share),
                ),
                const Spacer(),
                if (moment.hasDog)
                  Flexible(
                    child: ActionChip(
                      avatar: const Icon(Icons.pets, size: 16),
                      label: Text(
                        moment.dogName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      tooltip: MomentsStrings.viewDog,
                      backgroundColor: AppColors.primarySoft,
                      labelStyle: const TextStyle(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onPressed: () => openMomentDog(context, ref, moment),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moment.likeCount > 0)
                  Text(
                    MomentsStrings.likesCount(moment.likeCount),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                ],
                if (moment.commentsCount > 0)
                  InkWell(
                    onTap: () => showMomentCommentsSheet(context, moment),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        MomentsStrings.viewAllComments(moment.commentsCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAuthor(BuildContext context) {
    if (moment.authorUserId.isEmpty) {
      return;
    }
    showOwnerProfileSheet(
      context,
      userId: moment.authorUserId,
      fallbackName: moment.authorName,
      fallbackAvatarUrl: moment.authorPhotoUrl,
    );
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(momentActionsProvider).toggleLike(moment);
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(MomentsStrings.actionFailed)),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(
      ClipboardData(
        text: MomentsStrings.shareText(moment.authorName, moment.caption),
      ),
    );
    messenger?.showSnackBar(SnackBar(content: Text(MomentsStrings.shareCopied)));
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _PostAction action,
  ) async {
    switch (action) {
      case _PostAction.share:
        await _share(context);
      case _PostAction.report:
        await showContentReportSheet(
          context: context,
          ref: ref,
          targetType: ReportContentType.moment,
          targetId: moment.id,
          reportedUserId: moment.authorUserId,
          targetName: moment.caption.length > 200
              ? moment.caption.substring(0, 200)
              : moment.caption,
        );
      case _PostAction.block:
        await confirmAndBlockUser(
          context: context,
          ref: ref,
          userId: moment.authorUserId,
        );
      case _PostAction.delete:
        await _confirmDelete(context, ref);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(MomentsStrings.deletePost),
        content: Text(MomentsStrings.deletePostBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MomentsStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(MomentsStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(momentActionsProvider).delete(moment);
      messenger?.showSnackBar(
        SnackBar(content: Text(MomentsStrings.postDeleted)),
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(MomentsStrings.actionFailed)),
      );
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.seed});

  final String url;
  final String seed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: DogImage(
          url: url,
          seed: seed,
          fallback: const ColoredBox(
            color: AppColors.primarySoft,
            child: Icon(Icons.person, color: AppColors.primaryDeep),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
