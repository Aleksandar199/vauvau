import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../discover/domain/discover_profile.dart';
import '../../../discover/presentation/discover_controller.dart';
import '../../../discover/presentation/widgets/swipe_dog_card.dart';
import '../../domain/moment_model.dart';
import '../moments_controller.dart';
import '../moments_strings.dart';

class MomentCard extends ConsumerWidget {
  const MomentCard({super.key, required this.moment});

  final MomentModel moment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberId = ref.watch(momentsMemberIdProvider);
    final liked = moment.isLikedBy(memberId);
    final now = DateTime.now();
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: buildDogImage(moment.dogPhotoUrl, seed: moment.dogId),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moment.dogName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${moment.dogBreed} · ${MomentsStrings.timeAgo(moment.createdAt, now)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        MomentsStrings.locationPin(moment.locationName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: buildDogImage(moment.momentPhotoUrl, seed: moment.id),
          ),
          if (moment.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(moment.caption),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => ref
                      .read(momentsControllerProvider.notifier)
                      .toggleLike(moment.id),
                  child: Text(
                    '${liked ? '❤️' : '🤍'} ${moment.likeCount}',
                    style: TextStyle(
                      color: liked ? const Color(0xFFC62828) : AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => showMomentCommentsSheet(context, moment.id),
                  child: Text(
                    '${MomentsStrings.comment} ${moment.commentsCount}',
                  ),
                ),
                TextButton(
                  onPressed: () => _openDog(context, ref),
                  child: const Text(MomentsStrings.viewDog),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDog(BuildContext context, WidgetRef ref) {
    final discover = ref.read(discoverControllerProvider);
    DiscoverProfile? profile;
    if (discover.myDog.id == moment.dogId) {
      profile = discover.myDog;
    }
    profile ??= () {
      for (final dog in discover.visible) {
        if (dog.id == moment.dogId) {
          return dog;
        }
      }
      return null;
    }();
    profile ??= DiscoverProfile(
      id: moment.dogId,
      name: moment.dogName,
      ownerName: moment.authorName,
      ownerId: moment.authorUserId,
      breed: moment.dogBreed,
      ageYears: 1,
      gender: '',
      size: '',
      location: moment.locationName,
      bio: '',
      photoUrls: [moment.dogPhotoUrl],
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DogDetailSheet(profile: profile!),
    );
  }
}

Future<void> showMomentCommentsSheet(BuildContext context, String momentId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _CommentsSheet(momentId: momentId),
      );
    },
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.momentId});

  final String momentId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments =
        ref.watch(momentCommentsProvider(widget.momentId)).value ?? const [];
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  MomentsStrings.commentsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(comment.authorName),
                    subtitle: Text(comment.text),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: MomentsStrings.commentHint,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) {
      return;
    }
    _input.clear();
    await ref
        .read(momentsControllerProvider.notifier)
        .addComment(widget.momentId, text);
  }
}
