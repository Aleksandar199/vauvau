import 'package:cloud_firestore/cloud_firestore.dart';

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
      await ref.set(patch, SetOptions(merge: true));
    }

    final removed = await _col.doc(SeedBreedGroups.removedSmallDogsId).get();
    if (removed.exists) {
      await _col.doc(SeedBreedGroups.removedSmallDogsId).delete();
    }
  }

  @override
  Stream<List<BreedGroup>> watchGroups() async* {
    await ensureSeeded();
    yield* _col.snapshots().map((snapshot) {
      final List<BreedGroup> approved = snapshot.docs
          .map((doc) => BreedGroup.tryFromMap(doc.id, doc.data()))
          .whereType<BreedGroup>()
          .where((group) => group.isApproved)
          .toList();
      return SeedBreedGroups.sortByPopularity(approved);
    });
  }

  @override
  Stream<List<BreedGroup>> watchPendingGroups() async* {
    await ensureSeeded();
    yield* _col.snapshots().map((snapshot) {
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
    });
  }

  @override
  Stream<List<GroupMessage>> watchMessages(String groupId) {
    return _col
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(_messageFromDoc).toList(),
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
    return _col
        .doc(groupId)
        .collection('members')
        .doc(currentUserId)
        .snapshots()
        .map((snap) {
      final created = snap.data()?['lastReadTimestamp'];
      return created is Timestamp ? created.toDate() : null;
    });
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
      'imageUrl':
          'https://images.unsplash.com/photo-1558788353-f76d92427f16?auto=format&fit=crop&w=400&q=80',
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
  }) {
    return sendMessage(groupId: groupId, text: '', imageUrl: imageUrl);
  }

  GroupMessage _messageFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final created = data['createdAt'];
    return GroupMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      isMine: (data['senderId'] as String? ?? '') == currentUserId,
    );
  }
}
