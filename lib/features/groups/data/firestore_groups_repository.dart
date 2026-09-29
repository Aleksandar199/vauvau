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
    final existing = await _col.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }
    final batch = firestore.batch();
    for (final group in SeedBreedGroups.all) {
      batch.set(_col.doc(group.id), SeedBreedGroups.firestoreData(group));
    }
    await batch.commit();
  }

  @override
  Stream<List<BreedGroup>> watchGroups() async* {
    await ensureSeeded();
    yield* _col.orderBy('sortOrder').snapshots().map(
          (snapshot) => snapshot.docs.map(_groupFromDoc).toList(),
        );
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
    final memberRef = _col.doc(groupId).collection('members').doc(currentUserId);
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

  BreedGroup _groupFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final ids = [
      for (final value in data['memberIds'] as List? ?? const [])
        if (value is String && value.isNotEmpty) value,
    ];
    final lastAt = data['lastMessageAt'];
    return BreedGroup(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      memberIds: ids,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? ids.length,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: lastAt is Timestamp ? lastAt.toDate() : null,
    );
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
