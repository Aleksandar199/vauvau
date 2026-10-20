import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../moments/domain/moment_model.dart';
import '../../../moments/presentation/create_moment_sheet.dart';
import '../../../moments/presentation/moments_controller.dart';
import '../../../moments/presentation/moments_strings.dart';
import '../../../moments/presentation/widgets/moment_media.dart';
import '../../../moments/presentation/widgets/moment_post_card.dart';
import '../profile_strings.dart';

/// "Objave" on the profile: my feed posts as small square thumbnails (same
/// size as the dog photo row), newest first; a tap opens the post.
class ProfilePostsStrip extends ConsumerWidget {
  const ProfilePostsStrip({super.key});

  static const double tileSize = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final posts = ref.watch(myPostsProvider);
    final items = posts.value ?? const <MomentModel>[];
    return Column(
      key: const ValueKey('profile-posts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ProfileStrings.metricPosts, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (posts.isLoading && items.isEmpty)
          const SizedBox(
            height: tileSize,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (items.isEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  ProfileStrings.postsEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('profile-posts-new'),
                onPressed: () => showCreateMomentSheet(context),
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(MomentsStrings.newPost),
              ),
            ],
          )
        else
          SizedBox(
            height: tileSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final post = items[index];
                return InkWell(
                  key: ValueKey('profile-post-${post.id}'),
                  onTap: () => _openPost(context, post),
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: MomentThumb(moment: post, iconSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openPost(BuildContext context, MomentModel post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(ProfileStrings.metricPosts)),
          body: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [MomentPostCard(moment: post)],
          ),
        ),
      ),
    );
  }
}
