import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../follows/presentation/follow_button.dart';
import '../../domain/story.dart';
import '../stories_strings.dart';
import '../story_player_screen.dart';
import '../story_providers.dart';

/// Prati + the owner's active stories, shown in the owner profile popup.
/// Renders nothing outside a ProviderScope (plain widget tests).
class OwnerSocialActions extends StatelessWidget {
  const OwnerSocialActions({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  final String ownerId;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    if (ownerId.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return _OwnerSocialRow(ownerId: ownerId, ownerName: ownerName);
  }
}

class _OwnerSocialRow extends ConsumerWidget {
  const _OwnerSocialRow({required this.ownerId, required this.ownerName});

  final String ownerId;
  final String ownerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(ownerStoriesProvider(ownerId)).value ?? const [];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          FollowButton(ownerId: ownerId, ownerName: ownerName),
          if (stories.isNotEmpty)
            OutlinedButton.icon(
              key: const ValueKey('owner-stories-button'),
              onPressed: () => openStoryPlayer(
                context,
                groups: [StoryAuthorGroup.of(stories)],
              ),
              icon: const Icon(Icons.auto_stories_outlined),
              label: Text(
                stories.length > 1
                    ? StoriesStrings.storiesCount(stories.length)
                    : StoriesStrings.barTitle,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
        ],
      ),
    );
  }
}
