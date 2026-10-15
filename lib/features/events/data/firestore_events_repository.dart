import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../groups/domain/groups_models.dart';
import '../domain/event_model.dart';
import '../domain/events_repository.dart';
import 'local_events_repository.dart';
import 'seed_events.dart';

class FirestoreEventsRepository implements EventsRepository {
  FirestoreEventsRepository({
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
      firestore.collection('events');

  Future<void> ensureSeeded() async {
    if (_seedStarted) {
      return;
    }
    _seedStarted = true;
    final existing = await _col.limit(1).get();
    if (existing.docs.isEmpty) {
      final batch = firestore.batch();
      for (final event in SeedEvents.all) {
        batch.set(_col.doc(event.id), {
          ...SeedEvents.firestoreData(event),
          'dateTime': Timestamp.fromDate(event.dateTime),
          'createdAt': Timestamp.fromDate(event.createdAt),
        });
      }
      await batch.commit();
      return;
    }
    await _scrubStockCdnImages();
  }

  /// Clears Unsplash / stock CDN URLs left from older seeds.
  Future<void> _scrubStockCdnImages() async {
    final snaps = await _col.get();
    WriteBatch? batch;
    var ops = 0;
    for (final doc in snaps.docs) {
      final url = (doc.data()['imageUrl'] as String?)?.trim() ?? '';
      if (!isStockCdnPhotoUrl(url)) {
        continue;
      }
      batch ??= firestore.batch();
      batch.update(doc.reference, {'imageUrl': ''});
      ops++;
      if (ops >= 400) {
        await batch.commit();
        batch = null;
        ops = 0;
      }
    }
    if (batch != null && ops > 0) {
      await batch.commit();
    }
  }

  @override
  Stream<List<EventModel>> watchEvents() async* {
    await ensureSeeded();
    yield* FirestoreAuthGuard.guardedStream<List<EventModel>>(
      label: 'events.watch',
      empty: const [],
      create: () => _col.orderBy('dateTime').snapshots().map(
            (snapshot) => snapshot.docs.map(_fromDoc).toList(),
          ),
    );
  }

  @override
  Stream<List<GroupMessage>> watchMessages(String eventId) {
    return FirestoreAuthGuard.guardedStream<List<GroupMessage>>(
      label: 'events.messages',
      empty: const [],
      create: () => _col
          .doc(eventId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) => snapshot.docs.map(_messageFromDoc).toList()),
    );
  }

  @override
  Stream<DateTime?> watchLastRead(String eventId) {
    if (currentUserId.isEmpty) {
      return Stream<DateTime?>.value(null);
    }
    return FirestoreAuthGuard.guardedStream<DateTime?>(
      label: 'events.lastRead',
      empty: null,
      create: () => _col
          .doc(eventId)
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
  Future<void> joinEvent(String eventId) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final ref = _col.doc(eventId);
    var added = false;
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final ids = [
        for (final value in data['participantUserIds'] as List? ?? const [])
          if (value is String && value.isNotEmpty) value,
      ];
      if (ids.contains(currentUserId)) {
        return;
      }
      ids.add(currentUserId);
      added = true;
      tx.update(ref, {'participantUserIds': ids});
    });
    final memberRef = ref.collection('members').doc(currentUserId);
    final memberSnap = await memberRef.get();
    if (!memberSnap.exists) {
      await memberRef.set({
        'lastReadTimestamp': FieldValue.serverTimestamp(),
      });
    }
    if (added) {
      // Rules require senderId == auth.uid — announce join as the member.
      await sendMessage(
        eventId: eventId,
        text: EventsJoinCopy.joined(senderName),
      );
    }
    await markRead(eventId);
  }

  @override
  Future<void> markRead(String eventId) async {
    if (currentUserId.isEmpty) {
      return;
    }
    await _col.doc(eventId).collection('members').doc(currentUserId).set(
      {
        'lastReadTimestamp': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> sendMessage({
    required String eventId,
    required String text,
    String imageUrl = '',
    String? senderId,
    String? senderName,
    GroupMessage? replyTo,
  }) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl.trim().isEmpty) {
      return;
    }
    // Always the signed-in user — rules require senderId == auth.uid.
    final id = currentUserId;
    final name = (senderName ?? this.senderName).trim().isEmpty
        ? this.senderName
        : (senderName ?? this.senderName);
    final preview = trimmed.isEmpty ? '📷 Fotografija' : trimmed;
    final eventRef = _col.doc(eventId);
    await eventRef.collection('messages').add({
      'senderId': id,
      'senderName': name,
      'senderAvatarUrl': senderAvatarUrl,
      'text': trimmed,
      'imageUrl': imageUrl.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      if (replyTo != null) ...{
        'replyToMessageId': replyTo.id,
        'replyToText': replyTo.preview,
        'replyToSenderName': replyTo.senderName.trim().isEmpty
            ? 'Član'
            : replyTo.senderName.trim(),
      },
    });
    await eventRef.set(
      {
        'lastMessage': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> sendPhoto({
    required String eventId,
    required String imageUrl,
    GroupMessage? replyTo,
  }) {
    return sendMessage(
      eventId: eventId,
      text: '',
      imageUrl: imageUrl,
      replyTo: replyTo,
    );
  }

  @override
  Future<void> sendWalkInvite({
    required String eventId,
    required DateTime walkTime,
    required String walkLocationName,
  }) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final place = walkLocationName.trim();
    final preview =
        place.isEmpty ? 'Poziv na šetnju' : 'Poziv na šetnju: $place';
    final eventRef = _col.doc(eventId);
    await eventRef.collection('messages').add({
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
    await eventRef.set(
      {
        'lastMessage': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> respondToWalkInvite({
    required String eventId,
    required String messageId,
    required GroupWalkInviteStatus status,
  }) {
    if (currentUserId.isEmpty) {
      return Future.value();
    }
    final accepted = status == GroupWalkInviteStatus.accepted;
    return _col.doc(eventId).collection('messages').doc(messageId).update({
      if (accepted) ...{
        'acceptedByUserIds': FieldValue.arrayUnion([currentUserId]),
        'declinedByUserIds': FieldValue.arrayRemove([currentUserId]),
      } else ...{
        'declinedByUserIds': FieldValue.arrayUnion([currentUserId]),
        'acceptedByUserIds': FieldValue.arrayRemove([currentUserId]),
      },
      'status': 'pending',
    });
  }

  @override
  Future<String> createEvent(EventModel event) async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      final uid = (authUser?.uid ?? currentUserId).trim();
      if (uid.isEmpty) {
        throw StateError('Morate biti prijavljeni.');
      }
      final authName = (authUser?.displayName ?? '').trim();
      final fallbackName = event.organizerName.trim().isEmpty
          ? senderName.trim()
          : event.organizerName.trim();
      final organizerName = authName.isNotEmpty
          ? authName
          : (fallbackName.isNotEmpty ? fallbackName : 'Korisnik');
      final title = event.title.trim();
      final locationName = event.locationName.trim();
      if (title.isEmpty) {
        throw StateError('Naslov je obavezan.');
      }
      if (locationName.isEmpty) {
        throw StateError('Lokacija je obavezna.');
      }
      final imageUrl = event.imageUrl.trim().isEmpty
          ? kFallbackDogPhotoUrl
          : event.imageUrl.trim();
      final payload = <String, Object>{
        'title': title,
        'locationName': locationName,
        'dateTime': Timestamp.fromDate(event.dateTime),
        'description': event.description.trim(),
        'imageUrl': imageUrl,
        'organizerUserId': uid,
        'organizerName': organizerName,
        'participantUserIds': <String>[uid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        if (event.cityId.trim().isNotEmpty) 'cityId': event.cityId.trim(),
      };
      debugPrint('Event create payload: $payload');
      final doc = await _col.add(payload);
      await doc.collection('members').doc(uid).set({
        'lastReadTimestamp': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (error, stack) {
      debugPrint('Event create FAILED: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  EventModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final ids = [
      for (final value in data['participantUserIds'] as List? ?? const [])
        if (value is String && value.isNotEmpty) value,
    ];
    return EventModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      locationName: data['locationName'] as String? ?? '',
      dateTime: _date(data['dateTime']),
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      organizerUserId: data['organizerUserId'] as String? ?? '',
      organizerName: data['organizerName'] as String? ?? '',
      participantUserIds: ids,
      createdAt: _date(data['createdAt']),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: _dateOrNull(data['lastMessageAt']),
      cityId: data['cityId'] as String? ?? '',
    );
  }

  GroupMessage _messageFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final senderId = data['senderId'] as String? ?? '';
    final type = data['type'] == 'walk_invite'
        ? GroupMessageType.walkInvite
        : GroupMessageType.text;
    final status = switch (data['status'] as String?) {
          'pending' => GroupWalkInviteStatus.pending,
          'accepted' => GroupWalkInviteStatus.accepted,
          'declined' => GroupWalkInviteStatus.declined,
          _ => null,
        } ??
        (type == GroupMessageType.walkInvite
            ? GroupWalkInviteStatus.pending
            : null);
    final walkTime = data['walkTime'];
    return GroupMessage(
      id: doc.id,
      senderId: senderId,
      senderName: data['senderName'] as String? ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: _date(data['createdAt']),
      isMine: senderId == currentUserId,
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
    required String eventId,
    required String messageId,
  }) async {
    if (currentUserId.isEmpty) {
      return;
    }
    final ref = _col.doc(eventId).collection('messages').doc(messageId);
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

  DateTime _date(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  DateTime? _dateOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    return _date(value);
  }
}
