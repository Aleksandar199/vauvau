import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
    if (existing.docs.isNotEmpty) {
      return;
    }
    final batch = firestore.batch();
    for (final event in SeedEvents.all) {
      batch.set(_col.doc(event.id), {
        ...SeedEvents.firestoreData(event),
        'dateTime': Timestamp.fromDate(event.dateTime),
        'createdAt': Timestamp.fromDate(event.createdAt),
      });
    }
    await batch.commit();
  }

  @override
  Stream<List<EventModel>> watchEvents() async* {
    await ensureSeeded();
    yield* _col.orderBy('dateTime').snapshots().map(
          (snapshot) => snapshot.docs.map(_fromDoc).toList(),
        );
  }

  @override
  Stream<List<GroupMessage>> watchMessages(String eventId) {
    return _col
        .doc(eventId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_messageFromDoc).toList());
  }

  @override
  Stream<DateTime?> watchLastRead(String eventId) {
    if (currentUserId.isEmpty) {
      return Stream<DateTime?>.value(null);
    }
    return _col
        .doc(eventId)
        .collection('members')
        .doc(currentUserId)
        .snapshots()
        .map((snap) {
      final created = snap.data()?['lastReadTimestamp'];
      return created is Timestamp ? created.toDate() : null;
    });
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
      await sendMessage(
        eventId: eventId,
        text: EventsJoinCopy.joined(senderName),
        senderId: 'vauvau-system',
        senderName: 'VauVau',
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
  }) async {
    if (currentUserId.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl.trim().isEmpty) {
      return;
    }
    final id = senderId ?? currentUserId;
    final name = senderName ?? this.senderName;
    final preview = trimmed.isEmpty ? '📷 Fotografija' : trimmed;
    final eventRef = _col.doc(eventId);
    await eventRef.collection('messages').add({
      'senderId': id,
      'senderName': name,
      'senderAvatarUrl': id == currentUserId ? senderAvatarUrl : '',
      'text': trimmed,
      'imageUrl': imageUrl.trim(),
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
  Future<void> sendPhoto({
    required String eventId,
    required String imageUrl,
  }) {
    return sendMessage(eventId: eventId, text: '', imageUrl: imageUrl);
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
    );
  }

  GroupMessage _messageFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final senderId = data['senderId'] as String? ?? '';
    return GroupMessage(
      id: doc.id,
      senderId: senderId,
      senderName: data['senderName'] as String? ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: _date(data['createdAt']),
      isMine: senderId == currentUserId,
    );
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
