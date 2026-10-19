import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../dogs/domain/dogs_exception.dart';
import '../data/firestore_groups_repository.dart';
import '../data/local_groups_repository.dart';
import '../domain/group_ranking.dart';
import '../domain/groups_models.dart';

/// Whether the first groups snapshot arrived (or the stream failed), so the
/// screen can tell „loading“ from „no groups“.
typedef GroupsLoadState = ({bool loaded, Object? error});

class GroupsLoadStateNotifier extends Notifier<GroupsLoadState> {
  @override
  GroupsLoadState build() => (loaded: false, error: null);

  void update(GroupsLoadState value) => state = value;
}

final groupsLoadStateProvider =
    NotifierProvider<GroupsLoadStateNotifier, GroupsLoadState>(
      GroupsLoadStateNotifier.new,
    );

class GroupsController extends Notifier<List<BreedGroup>> {
  @override
  List<BreedGroup> build() {
    final repo = ref.watch(groupsRepositoryProvider);
    final status = ref.read(groupsLoadStateProvider.notifier);
    Future.microtask(() => status.update((loaded: false, error: null)));
    final sub = repo.watchGroups().listen((groups) {
      state = List<BreedGroup>.from(groups.whereType<BreedGroup>());
      status.update((loaded: true, error: null));
    }, onError: (Object error) {
      debugPrint('Groups stream: $error');
      status.update((loaded: true, error: error));
    });
    ref.onDispose(sub.cancel);
    return const <BreedGroup>[];
  }

  Future<void> markRead(String groupId) {
    return ref.read(groupsRepositoryProvider).markRead(groupId);
  }

  Future<void> join(String groupId) {
    return ref.read(groupsRepositoryProvider).joinGroup(groupId);
  }

  Future<BreedGroup> createGroup({
    required String title,
    required String description,
    GroupScope? scope,
    String cityId = '',
    GroupCategory category = GroupCategory.general,
    String locationName = '',
    String breedKey = '',
  }) {
    // User-facing create stays pending (rules: isApproved == false +
    // createdBy == uid); only an admin publishes directly, which is the
    // controlled way to add presets such as local park groups.
    return ref
        .read(groupsRepositoryProvider)
        .createGroup(
          title: title,
          description: description,
          approveImmediately: ref.read(isAdminProvider),
          scope: scope,
          cityId: cityId,
          category: category,
          locationName: locationName,
          breedKey: breedKey,
        );
  }

  Future<void> approveGroup(String groupId) {
    return ref.read(groupsRepositoryProvider).approveGroup(groupId);
  }

  Future<void> deleteGroup(String groupId) {
    return ref.read(groupsRepositoryProvider).deleteGroup(groupId);
  }

  Future<void> sendText(String groupId, String text, {GroupMessage? replyTo}) {
    return ref
        .read(groupsRepositoryProvider)
        .sendMessage(groupId: groupId, text: text, replyTo: replyTo);
  }

  Future<void> sendPhoto(
    String groupId,
    XFile file, {
    GroupMessage? replyTo,
  }) async {
    final error = await ContentValidationService.validateImage(file);
    if (error != null) {
      throw DogsException(error);
    }
    final url = await ImageUploadService.uploadFile(file, folderName: 'groups');
    await ref
        .read(groupsRepositoryProvider)
        .sendPhoto(groupId: groupId, imageUrl: url, replyTo: replyTo);
  }

  Future<void> sendWalkInvite({
    required String groupId,
    required DateTime walkTime,
    required String walkLocationName,
  }) {
    return ref
        .read(groupsRepositoryProvider)
        .sendWalkInvite(
          groupId: groupId,
          walkTime: walkTime,
          walkLocationName: walkLocationName,
        );
  }

  Future<void> respondToWalkInvite({
    required String groupId,
    required String messageId,
    required GroupWalkInviteStatus status,
  }) {
    return ref
        .read(groupsRepositoryProvider)
        .respondToWalkInvite(
          groupId: groupId,
          messageId: messageId,
          status: status,
        );
  }

  Future<void> toggleMessageLike({
    required String groupId,
    required String messageId,
  }) {
    return ref
        .read(groupsRepositoryProvider)
        .toggleMessageLike(groupId: groupId, messageId: messageId);
  }

  Future<void> setMessageReaction({
    required String groupId,
    required String messageId,
    String? emoji,
  }) {
    return ref
        .read(groupsRepositoryProvider)
        .setMessageReaction(
          groupId: groupId,
          messageId: messageId,
          emoji: emoji,
        );
  }
}

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  final uid = user?.uid ?? '';
  final name = (user?.displayName ?? '').trim().isEmpty
      ? 'Član'
      : user!.displayName!.trim();
  final avatar = user?.ownerAvatarUrl ?? '';
  if (isFirebaseReady) {
    return FirestoreGroupsRepository(
      firestore: FirebaseFirestore.instance,
      currentUserId: uid,
      senderName: name,
      senderAvatarUrl: avatar,
    );
  }
  final repo = LocalGroupsRepository(
    currentUserId: uid.isEmpty ? 'local-user' : uid,
    senderName: name == 'Član' ? 'Ti' : name,
    senderAvatarUrl: avatar,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final groupsControllerProvider =
    NotifierProvider<GroupsController, List<BreedGroup>>(GroupsController.new);

final pendingGroupsProvider = StreamProvider<List<BreedGroup>>((ref) {
  if (!ref.watch(isAdminProvider)) {
    return Stream<List<BreedGroup>>.value(const <BreedGroup>[]);
  }
  return ref
      .watch(groupsRepositoryProvider)
      .watchPendingGroups()
      .map((groups) => List<BreedGroup>.from(groups.whereType<BreedGroup>()));
});

final groupMessagesProvider = StreamProvider.family<List<GroupMessage>, String>(
  (ref, groupId) {
    return ref
        .watch(groupsRepositoryProvider)
        .watchMessages(groupId)
        .map(
          (messages) =>
              List<GroupMessage>.from(messages.whereType<GroupMessage>()),
        );
  },
);

final groupsMemberIdProvider = Provider<String>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
  if (uid.isNotEmpty) {
    return uid;
  }
  return isFirebaseReady ? '' : 'local-user';
});

final groupByIdProvider = Provider.family<BreedGroup?, String>((ref, groupId) {
  for (final group in ref.watch(groupsControllerProvider)) {
    if (group.id == groupId) {
      return group;
    }
  }
  return null;
});

final groupLastReadProvider = StreamProvider.family<DateTime?, String>((
  ref,
  groupId,
) {
  return ref.watch(groupsRepositoryProvider).watchLastRead(groupId);
});

final joinedGroupThreadsProvider = Provider<List<GroupInboxThread>>((ref) {
  final memberId = ref.watch(groupsMemberIdProvider);
  final groups = List<BreedGroup>.from(
    ref.watch(groupsControllerProvider).whereType<BreedGroup>(),
  );

  final threads = <GroupInboxThread>[
    for (final group in groups)
      if (group.isMember(memberId))
        GroupInboxThread.fromMessages(
          group: group,
          messages: List<GroupMessage>.from(
            ref.watch(groupMessagesProvider(group.id)).asData?.value ??
                const <GroupMessage>[],
          ),
          lastRead: ref.watch(groupLastReadProvider(group.id)).asData?.value,
        ),
  ];

  threads.sort(
    (GroupInboxThread a, GroupInboxThread b) =>
        b.lastActivityAt.compareTo(a.lastActivityAt),
  );
  return threads;
});

/// Public groups list sorted by popularity (member count desc).
final sortedGroupsProvider = Provider<List<BreedGroup>>((ref) {
  final groups = List<BreedGroup>.from(
    ref.watch(groupsControllerProvider).whereType<BreedGroup>(),
  );
  return GroupRanking.sort(groups);
});
