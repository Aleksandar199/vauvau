import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/data/owner_public_profile.dart';
import '../../profile/presentation/owner_profile_sheet.dart';
import '../../profile/presentation/profile_strings.dart';

/// Public profile per user id for follower / following lists.
final followListProfileProvider = FutureProvider.autoDispose
    .family<OwnerPublicProfile?, String>((ref, userId) {
      return ref.watch(ownerProfileLoaderProvider)(userId);
    });

/// "Pratioci" / "Pratim": people in [userIds]; a tap opens their profile.
Future<void> showFollowListSheet(
  BuildContext context, {
  required String title,
  required Set<String> userIds,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FollowListSheet(title: title, userIds: userIds.toList()),
  );
}

class FollowListSheet extends StatelessWidget {
  const FollowListSheet({
    super.key,
    required this.title,
    required this.userIds,
  });

  final String title;
  final List<String> userIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (userIds.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(ProfileStrings.followListEmpty),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: userIds.length,
                  itemBuilder: (_, i) => _FollowListTile(userId: userIds[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FollowListTile extends ConsumerWidget {
  const _FollowListTile({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(followListProfileProvider(userId)).value;
    final name = (profile?.name ?? '').trim();
    final photo = profile?.photoUrl ?? '';
    const placeholder = ColoredBox(
      color: AppColors.primarySoft,
      child: Icon(Icons.person, color: AppColors.primaryDeep),
    );
    return ListTile(
      key: ValueKey('follow-list-$userId'),
      leading: ClipOval(
        child: SizedBox(
          width: 40,
          height: 40,
          child: photo.startsWith('http')
              ? DogImage(url: photo, seed: photo, fallback: placeholder)
              : placeholder,
        ),
      ),
      title: Text(name.isEmpty ? ProfileStrings.ownerUnknown : name),
      subtitle: (profile?.location ?? '').isEmpty
          ? null
          : Text(profile!.location),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showOwnerProfileSheet(
        context,
        userId: userId,
        fallbackName: name,
        fallbackAvatarUrl: photo,
        loader: ref.read(ownerProfileLoaderProvider),
      ),
    );
  }
}
