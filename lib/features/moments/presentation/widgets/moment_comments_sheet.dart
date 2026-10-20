import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/comment_like_button.dart';
import '../../../profile/presentation/owner_profile_sheet.dart';
import '../../../moderation/presentation/block_controller.dart';
import '../../domain/moment_model.dart';
import '../moments_controller.dart';
import '../moments_strings.dart';
import '../pointer_safe.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

Future<void> showMomentCommentsSheet(BuildContext context, MomentModel moment) {
  return afterPointerSettles(() async {
    if (!context.mounted) {
      return;
    }
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: MomentCommentsSheet(moment: moment),
        );
      },
    );
  });
}

/// Comments of one moment: latest [pageSize] first, "Prikaži starije" loads
/// more, one level of replies, like, delete (own comment, the post's author
/// or admin). A failed send keeps the text and the same comment id, so
/// "Pošalji" again never duplicates it.
class MomentCommentsSheet extends ConsumerStatefulWidget {
  const MomentCommentsSheet({super.key, required this.moment});

  static const int pageSize = 30;

  final MomentModel moment;

  @override
  ConsumerState<MomentCommentsSheet> createState() =>
      _MomentCommentsSheetState();
}

class _MomentCommentsSheetState extends ConsumerState<MomentCommentsSheet> {
  final _input = TextEditingController();
  var _limit = MomentCommentsSheet.pageSize;
  MomentComment? _replyTo;
  String? _pendingId;
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = (momentId: widget.moment.id, limit: _limit);
    final async = ref.watch(momentCommentsProvider(key));
    final blocked = ref.watch(blockedUserIdsProvider);
    final comments = [
      for (final comment in async.value ?? const <MomentComment>[])
        if (!blocked.contains(comment.authorUserId)) comment,
    ];
    final me = ref.watch(momentsMemberIdProvider);
    final isAdmin = ref.watch(isMomentsAdminProvider);
    final thread = threadComments(comments);
    final canLoadOlder = (async.value?.length ?? 0) >= _limit;
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    MomentsStrings.commentsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MomentsStrings.close,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: async.isLoading && comments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : thread.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        MomentsStrings.noComments,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: thread.length + (canLoadOlder ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (canLoadOlder && index == 0) {
                        return TextButton(
                          onPressed: () => setState(
                            () => _limit += MomentCommentsSheet.pageSize,
                          ),
                          child: Text(MomentsStrings.olderComments),
                        );
                      }
                      final entry = thread[index - (canLoadOlder ? 1 : 0)];
                      final comment = entry.comment;
                      final canDelete = comment.authorUserId == me ||
                          widget.moment.authorUserId == me ||
                          isAdmin;
                      return _CommentTile(
                        key: ValueKey('comment-${comment.id}'),
                        comment: comment,
                        nested: entry.nested,
                        me: me,
                        onReply: () => setState(() => _replyTo = comment),
                        onLike: () => ref
                            .read(momentActionsProvider)
                            .toggleCommentLike(widget.moment.id, comment.id)
                            .catchError((Object _) {}),
                        onDelete: canDelete ? () => _delete(comment) : null,
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (_replyTo != null)
            Container(
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      MomentsStrings.replyingTo(_replyTo!.authorName),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: MomentsStrings.cancel,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _replyTo = null),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('moment-comment-input'),
                      controller: _input,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: MomentComment.maxTextLength,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: MomentsStrings.commentHint,
                        counterText: '',
                        isDense: true,
                      ),
                      onChanged: (_) {
                        // New text = new comment (new id on the next send).
                        _pendingId = null;
                        if (_error != null) {
                          setState(() => _error = null);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: MomentsStrings.send,
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) {
      return;
    }
    final actions = ref.read(momentActionsProvider);
    _pendingId ??= actions.newCommentId(widget.moment.id);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await actions.addComment(
        widget.moment,
        text,
        commentId: _pendingId!,
        replyTo: _replyTo,
      );
      if (!mounted) {
        return;
      }
      _input.clear();
      setState(() {
        _pendingId = null;
        _replyTo = null;
        _sending = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _error = error is StateError
            ? error.message
            : MomentsStrings.commentNotSent;
      });
    }
  }

  Future<void> _delete(MomentComment comment) async {
    try {
      await ref.read(momentActionsProvider).deleteComment(widget.moment, comment);
    } catch (_) {
      if (mounted) {
        setState(() => _error = MomentsStrings.actionFailed);
      }
    }
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    super.key,
    required this.comment,
    required this.nested,
    required this.me,
    required this.onReply,
    required this.onLike,
    this.onDelete,
  });

  final MomentComment comment;
  final bool nested;
  final String me;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = comment.authorName.trim().isEmpty
        ? '?'
        : comment.authorName.trim().characters.first.toUpperCase();
    return Padding(
      padding: EdgeInsets.fromLTRB(nested ? 44 : 4, 6, 0, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: comment.authorUserId.isEmpty
                ? null
                : () => showOwnerProfileSheet(
                      context,
                      userId: comment.authorUserId,
                      fallbackName: comment.authorName,
                    ),
            child: CircleAvatar(
              radius: nested ? 14 : 17,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${comment.authorName}  ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (!nested && comment.isReply)
                        TextSpan(
                          text: '${MomentsStrings.replyTo(comment.replyToAuthorName)} ',
                          style: theme.textTheme.bodySmall,
                        ),
                      TextSpan(text: comment.text),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      MomentsStrings.timeAgo(comment.createdAt, DateTime.now()),
                      style: theme.textTheme.bodySmall,
                    ),
                    InkWell(
                      onTap: onReply,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          MomentsStrings.reply,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (onDelete != null)
                      InkWell(
                        onTap: onDelete,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            MomentsStrings.delete,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          CommentLikeButton(
            liked: comment.isLikedBy(me),
            count: comment.likeCount,
            tooltip: MomentsStrings.like,
            onPressed: onLike,
          ),
        ],
      ),
    );
  }
}
