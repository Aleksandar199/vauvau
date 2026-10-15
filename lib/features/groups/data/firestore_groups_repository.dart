import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import 'seed_breed_groups.dart';
import '../domain/groups_models.dart';

class FirestoreGroupsRepository implements GroupsRepository {
  FirestoreGroupsRepository({
    required this.firestore,
    required this.currentUserId,
    required this.senderName,
    required this.senderAvatarUrl,
  });

  final FirebaseFirestore firestore;
  final String currentUserId;
  final String senderName;
  final String senderAvatarUrl;
  var _seedStarted = false;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('breed_groups');

  Future<void> ensureSeeded() async {
    if (_seedStarted) {
      return;
    }
    _seedStarted = true;

    // Rules allow seed writes only for admins; others must still get the
    // groups stream, so a rejected seed write is skipped.
    try {
      await _seedGroups();
    } catch (error) {
      debugPrint('groups seed skipped: $error');
    }
  }

  Future<void> _seedGroups() async {
    for (final group in SeedBreedGroups.all) {
      final ref = _col.doc(group.id);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set(SeedBreedGroups.firestoreData(group));
        continue;
      }
      final data = snap.data() ?? {};
      final ids = [
        for (final value in data['memberIds'] as List? ?? const [])
          if (value is String && value.isNotEmpty) value,
      ];
      final patch = <String, dynamic>{
        'title': group.title,
        'description': group.description,
        'imageUrl': group.imageUrl,
        'isApproved': true,
        'sortOrder': group.sortOrder,
        'createdBy': data['createdBy'] as String? ?? '',
      };
      // Keep live member tallies; refresh mock counts only when nobody joined.
      if (ids.isEmpty) {
        patch['memberCount'] = group.memberCount;
        patch['memberIds'] = const <String>[];
      }
      try {
        await ref.set(patch, SetOptions(merge: true));
      } catch (error) {
        // Non-admins may not change seed fields; an unchanged patch passes.
        debugPrint('groups seed patch ${group.id} skipped: $error');
      }
    }

    final removed = await _col.doc(SeedBreedGroups.removedSmallDogsId).get();
    if (removed.exists) {
      await _col.doc(SeedBreedGroups.removedSmallDogsId).delete();
    }
  }

  @override
  Stream<List<BreedGroup>> watchGroups() async* {
    await ensureSeeded();
    yield* FirestoreAuthGuard.guardedStream<List<BreedGroup>>(
      label: 'groups.watch',
      empty: const [],
      create: () => _col.snapshots().map((snapshot) {
        final List<BreedGroup> approved = snapshot.docs
            .map((doc) => BreedGroup.tryFromMap(doc.id, doc.data()))
            .whereType<BreedGroup>()
            .where((group) => group.isApproved)
            .toList();
        return SeedBreedGroups.sortByPopularity(approved);
      }),
    );
  }

  @override
  Stream<List<BreedGroup>> watchPendingGroups() async* {
    await ensureSeeded();
    yield* FirestoreAuthGuard.guardedStream<List<BreedGroup>>(
      label: 'groups.pending',
      empty: const [],
      create: () => _col.snapshots().map((snapshot) {
        final List<BreedGroup> pending = snapshot.docs
            .map((doc) => BreedGroup.tryFromMap(doc.id, doc.data()))
            .whereType<BreedGroup>()
            .where((group) => !group.isApproved)
            .toList()
          ..sort(
            (BreedGroup a, BreedGroup b) {
              final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bAt.compareTo(aAt);
            },
          );
        return pending;
      }),
    );
  }

  @override
  Stream<List<GroupMessage>> watchMessages(String groupId) {
    return FirestoreAuthGuard.guardedStream<List<GroupMessage>>(
      label: 'groups.messages',
      empty: const [],
      create: () => _col
          .doc(groupId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map(_messageFromDoc).toList(),
          ),
    );
  }

  @override
  Future<void> joinGroup(String groupId) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final ref = _col.doc(groupId);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final ids = [
        for (final value in data['memberIds'] as List? ?? const [])
          if (value is String && value.isNotEmpty) value,
      ];
      if (ids.contains(currentUserId)) {
        return;
      }
      ids.add(currentUserId);
      final stored = (data['memberCount'] as num?)?.toInt() ?? ids.length - 1;
      tx.update(ref, {
        'memberIds': ids,
        'memberCount': stored + 1,
      });
    });
    final memberRef =
        _col.doc(groupId).collection('members').doc(currentUserId);
    final memberSnap = await memberRef.get();
    if (!memberSnap.exists) {
      await memberRef.set({
        'lastReadTimestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Stream<DateTime?> watchLastRead(String groupId) {
    if (currentUserId.isEmpty) {
      return Stream<DateTime?>.value(null);
    }
    return FirestoreAuthGuard.guardedStream<DateTime?>(
      label: 'groups.lastRead',
      empty: null,
      create: () => _col
          .doc(groupId)
          .collection('members')
          .doc(currentUserId)
          .snapshots()
          .map((snap) {
        final created = snap.data()?['lastReadTimestamp'];
        return created is Timestamp ? created.toDate() : null;
      }),
    );
  }

  @override
  Future<void> markRead(String groupId) async {
    if (currentUserId.isEmpty) {
      return;
    }
    await _col.doc(groupId).collection('members').doc(currentUserId).set(
      {
        'lastReadTimestamp': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<BreedGroup> createGroup({
    required String title,
    required String description,
    bool approveImmediately = false,
  }) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw StateError('Naziv grupe je obavezan.');
    }
    final desc = description.trim().isEmpty
        ? SeedBreedGroups.defaultDescription
        : description.trim();
    // Non-admin clients must write pending groups only.
    final approved = approveImmediately;
    final ref = _col.doc();
    final data = <String, dynamic>{
      'title': trimmedTitle,
      'description': desc,
      'imageUrl': '',
      'memberIds': <String>[currentUserId],
      'memberCount': 1,
      'sortOrder': 999,
      'lastMessage': '',
      'isApproved': approved,
      'createdBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await ref.set(data);
    try {
      await ref.collection('members').doc(currentUserId).set({
        'lastReadTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Group document is already created; member read cursor is best-effort.
    }
    return BreedGroup(
      id: ref.id,
      title: trimmedTitle,
      description: desc,
      imageUrl: data['imageUrl'] as String,
      memberIds: [currentUserId],
      memberCount: 1,
      sortOrder: 999,
      isApproved: approved,
      createdBy: currentUserId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> approveGroup(String groupId) async {
    await _col.doc(groupId).set(
      {'isApproved': true},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _col.doc(groupId).delete();
  }

  @override
  Future<void> sendMessage({
    required String groupId,
    required String text,
    String imageUrl = '',
    GroupMessage? replyTo,
  }) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl.trim().isEmpty) {
      return;
    }
    final preview = trimmed.isEmpty ? '📷 Fotografija' : trimmed;
    final groupRef = _col.doc(groupId);
    await groupRef.collection('messages').add({
      'senderId': currentUserId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'text': trimmed,
      'imageUrl': imageUrl.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      if (replyTo != null) ...{
        'replyToMessageId': replyTo.id,
        'replyToText': _clipReply(replyTo.preview),
        'replyToSenderName': replyTo.senderName.trim().isEmpty
            ? 'Član'
            : replyTo.senderName.trim(),
      },
    });
    await groupRef.set(
      {
        'lastMessage': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> sendPhoto({
    required String groupId,
    required String imageUrl,
    GroupMessage? replyTo,
  }) {
    return sendMessage(
      groupId: groupId,
      text: '',
      imageUrl: imageUrl,
      replyTo: replyTo,
    );
  }

  @override
  Future<void> sendWalkInvite({
    required String groupId,
    required DateTime walkTime,
    required String walkLocationName,
  }) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final place = walkLocationName.trim();
    final preview =
        place.isEmpty ? 'Poziv na šetnju' : 'Poziv na šetnju: $place';
    final groupRef = _col.doc(groupId);
    await groupRef.collection('messages').add({
      'senderId': currentUserId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'text': preview,
      'imageUrl': '',
      'type': 'walk_invite',
      'status': 'pending',
      'walkTime': Timestamp.fromDate(walkTime),
      'walkLocationName': place,
      'acceptedByUserIds': <String>[],
      'declinedByUserIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await groupRef.set(
      {
        'lastMessage': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> respondToWalkInvite({
    required String groupId,
    required String messageId,
    required GroupWalkInviteStatus status,
  }) {
    if (currentUserId.isEmpty) {
      return Future.value();
    }
    final accepted = status == GroupWalkInviteStatus.accepted;
    return _col.doc(groupId).collection('messages').doc(messageId).update({
      if (accepted) ...{
        'acceptedByUserIds': FieldValue.arrayUnion([currentUserId]),
        'declinedByUserIds': FieldValue.arrayRemove([currentUserId]),
      } else ...{
        'declinedByUserIds': FieldValue.arrayUnion([currentUserId]),
        'acceptedByUserIds': FieldValue.arrayRemove([currentUserId]),
      },
      // Keep invite open for other members; personal state is in the arrays.
      'status': 'pending',
    });
  }

  GroupMessage _messageFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final created = data['createdAt'];
    final type = _typeFromKey(data['type'] as String?);
    final status = _statusFromKey(data['status'] as String?) ??
        (type == GroupMessageType.walkInvite
            ? GroupWalkInviteStatus.pending
            : null);
    final walkTime = data['walkTime'];
    return GroupMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      isMine: (data['senderId'] as String? ?? '') == currentUserId,
      replyToMessageId: data['replyToMessageId'] as String? ?? '',
      replyToText: data['replyToText'] as String? ?? '',
      replyToSenderName: data['replyToSenderName'] as String? ?? '',
      type: type,
      status: status,
      walkTime: walkTime is Timestamp ? walkTime.toDate() : null,
      walkLocationName: data['walkLocationName'] as String?,
      acceptedByUserIds: _stringList(data['acceptedByUserIds']),
      declinedByUserIds: _stringList(data['declinedByUserIds']),
      likes: _stringList(data['likes']),
    );
  }

  @override
  Future<void> toggleMessageLike({
    required String groupId,
    required String messageId,
  }) async {
    if (currentUserId.isEmpty) {
      return;
    }
    final ref = _col.doc(groupId).collection('messages').doc(messageId);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final ids = _stringList(data['likes']);
      if (ids.contains(currentUserId)) {
        ids.remove(currentUserId);
      } else {
        ids.add(currentUserId);
      }
      tx.set(ref, {'likes': ids}, SetOptions(merge: true));
    });
  }

  List<String> _stringList(Object? value) {
    if (value is! List) {
      return <String>[];
    }
    return [
      for (final item in value)
        if (item != null && '$item'.trim().isNotEmpty) '$item',
    ];
  }

  GroupMessageType _typeFromKey(String? value) {
    return value == 'walk_invite'
        ? GroupMessageType.walkInvite
        : GroupMessageType.text;
  }

  GroupWalkInviteStatus? _statusFromKey(String? value) {
    return switch (value) {
      'pending' => GroupWalkInviteStatus.pending,
      'accepted' => GroupWalkInviteStatus.accepted,
      'declined' => GroupWalkInviteStatus.declined,
      _ => null,
    };
  }

  String _clipReply(String raw, [int max = 120]) {
    final text = raw.trim();
    if (text.length <= max) {
      return text;
    }
    return '${text.substring(0, max).trimRight()}…';
  }
}
