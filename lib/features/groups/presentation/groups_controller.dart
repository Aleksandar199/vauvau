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
import '../domain/groups_models.dart';

class GroupsController extends Notifier<List<BreedGroup>> {
  @override
  List<BreedGroup> build() {
    final repo = ref.watch(groupsRepositoryProvider);
    final sub = repo.watchGroups().listen(
      (groups) => state = groups,
      onError: (Object error) => debugPrint('Groups stream: $error'),
    );
    ref.onDispose(sub.cancel);
    return const [];
  }

  Future<void> markRead(String groupId) {
    return ref.read(groupsRepositoryProvider).markRead(groupId);
  }

  Future<void> join(String groupId) {
    return ref.read(groupsRepositoryProvider).joinGroup(groupId);
  }

  Future<void> sendText(String groupId, String text) {
    return ref.read(groupsRepositoryProvider).sendMessage(
          groupId: groupId,
          text: text,
        );
  }

  Future<void> sendPhoto(String groupId, XFile file) async {
    final error = await ContentValidationService.validateImage(file);
    if (error != null) {
      throw DogsException(error);
    }
    final url = await ImageUploadService.upload(await file.readAsBytes());
    await ref.read(groupsRepositoryProvider).sendPhoto(
          groupId: groupId,
          imageUrl: url,
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

final groupMessagesProvider =
    StreamProvider.family<List<GroupMessage>, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).watchMessages(groupId);
});

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

final groupLastReadProvider =
    StreamProvider.family<DateTime?, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).watchLastRead(groupId);
});

final joinedGroupThreadsProvider = Provider<List<GroupInboxThread>>((ref) {
  final memberId = ref.watch(groupsMemberIdProvider);
  final threads = [
    for (final group in ref.watch(groupsControllerProvider))
      if (group.isMember(memberId))
        GroupInboxThread.fromMessages(
          group: group,
          messages: ref.watch(groupMessagesProvider(group.id)).asData?.value ??
              const [],
          lastRead: ref.watch(groupLastReadProvider(group.id)).asData?.value,
        ),
  ]..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
  return threads;
});
