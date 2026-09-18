import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/chat_room.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({
    required this._firestore,
    required this.currentUserId,
  });

  final FirebaseFirestore _firestore;
  final String currentUserId;
  List<ChatConversation> _inbox = const [];
  final StreamController<List<ChatConversation>> _inboxController =
      StreamController<List<ChatConversation>>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _messageSubs = {};

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chats');

  void start() {
    _roomsSub = _rooms
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .listen(_onRooms);
  }

  void _onRooms(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final rooms = snapshot.docs.map(_conversationFromRoom).toList();
    final keep = rooms.map((chat) => chat.id).toSet();
    for (final id in _messageSubs.keys.toList()) {
      if (!keep.contains(id)) {
        _messageSubs.remove(id)?.cancel();
      }
    }
    for (final chat in rooms) {
      _messageSubs.putIfAbsent(
        chat.id,
        () => _rooms.doc(chat.id).collection('messages').orderBy('timestamp').snapshots().listen(
              (messages) => _onMessages(chat.id, messages),
            ),
      );
    }
    _inbox = [
      for (final chat in rooms)
        _merge(chat, _byId(chat.id)?.messages ?? const []),
    ];
    _emit();
  }

  void _onMessages(
    String roomId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final messages = snapshot.docs.map(_messageFromDoc).toList();
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == roomId) _merge(chat, messages) else chat,
    ];
    _emit();
  }

  ChatConversation? _byId(String id) {
    for (final chat in _inbox) {
      if (chat.id == id) {
        return chat;
      }
    }
    return null;
  }

  ChatConversation _merge(ChatConversation chat, List<ChatMessage> messages) {
    return chat.copyWith(messages: messages);
  }

  @override
  List<ChatConversation> get currentInbox =>
      List<ChatConversation>.from(_inbox);

  @override
  Stream<List<ChatConversation>> watchInbox() async* {
    yield currentInbox;
    yield* _inboxController.stream;
  }

  @override
  Stream<List<ChatRoom>> watchRooms() {
    return _rooms
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatRoom(
              id: doc.id,
              participantIds: _stringList(data['participantIds']),
              dogIds: _stringList(data['dogIds']),
              lastMessage: data['lastMessage'] as String? ?? '',
              lastMessageTimestamp: _date(data['lastMessageTimestamp']),
              unreadCount: _unreadForMe(data),
            );
          }).toList(),
        );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_messageFromDoc).toList());
  }

  @override
  String openFromMatch({
    required DiscoverProfile profile,
    required String myUserId,
    required String myDogId,
  }) {
    final id = 'chat-${profile.id}';
    final existing = _byId(id);
    if (existing != null) {
      return existing.id;
    }
    unawaited(
      _rooms.doc(id).set({
        'id': id,
        'participantIds': [myUserId, 'owner-${profile.id}'],
        'dogIds': [myDogId, profile.id],
        'peerUserId': 'owner-${profile.id}',
        'dogId': profile.id,
        'dogName': profile.name,
        'ownerName': profile.ownerName,
        'breed': profile.breed,
        'location': profile.location,
        'photoUrl': profile.photoUrls.isEmpty ? '' : profile.photoUrls.first,
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'unreadByUser': <String, int>{myUserId: 0},
        'isNewMatch': true,
      }, SetOptions(merge: true)),
    );
    return id;
  }

  @override
  void markRead(String conversationId) {
    unawaited(
      _rooms.doc(conversationId).set({
        'unreadCount': 0,
      }, SetOptions(merge: true)),
    );
  }

  @override
  void sendMessage(String conversationId, String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return;
    }
    unawaited(
      _writeMessage(
        conversationId,
        {
          'senderId': currentUserId,
          'receiverId': _byId(conversationId)?.peerUserId ?? '',
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'text',
        },
        text,
      ),
    );
  }

  @override
  void sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  }) {
    unawaited(
      _writeMessage(
        conversationId,
        {
          'senderId': currentUserId,
          'receiverId': _byId(conversationId)?.peerUserId ?? '',
          'text': 'Poziv na šetnju: $walkLocationName',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'walk_invite',
          'status': 'pending',
          'walkTime': Timestamp.fromDate(walkTime),
          'walkLocationName': walkLocationName,
        },
        'Poziv na šetnju: $walkLocationName',
      ),
    );
  }

  @override
  void sendLocationPin({
    required String conversationId,
    required String locationName,
  }) {
    unawaited(
      _writeMessage(
        conversationId,
        {
          'senderId': currentUserId,
          'receiverId': _byId(conversationId)?.peerUserId ?? '',
          'text': locationName,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'location_pin',
        },
        locationName,
      ),
    );
  }

  @override
  void respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  }) {
    unawaited(
      _rooms.doc(conversationId).collection('messages').doc(messageId).update({
        'status': status == WalkInviteStatus.accepted ? 'accepted' : 'declined',
      }),
    );
  }

  @override
  void dispose() {
    _roomsSub?.cancel();
    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    _inboxController.close();
  }

  Future<void> _writeMessage(
    String conversationId,
    Map<String, dynamic> payload,
    String preview,
  ) async {
    await _rooms.doc(conversationId).collection('messages').add(payload);
    await _rooms.doc(conversationId).set({
      'lastMessage': preview,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'isNewMatch': false,
    }, SetOptions(merge: true));
  }

  ChatConversation _conversationFromRoom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ChatConversation(
      id: doc.id,
      dogId: data['dogId'] as String? ?? '',
      dogName: data['dogName'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      location: data['location'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      participantIds: _stringList(data['participantIds']),
      dogIds: _stringList(data['dogIds']),
      peerUserId: data['peerUserId'] as String? ?? '',
      messages: _byId(doc.id)?.messages ?? const [],
      lastActivityAt: _date(data['lastMessageTimestamp']) ?? DateTime.now(),
      isNewMatch: data['isNewMatch'] as bool? ?? false,
      unreadCount: _unreadForMe(data),
    );
  }

  ChatMessage _messageFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final senderId = data['senderId'] as String? ?? '';
    return ChatMessage(
      id: doc.id,
      senderId: senderId,
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: _date(data['timestamp']) ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      isMine: senderId == currentUserId,
      type: ChatMessage.typeFromKey(data['type'] as String?),
      status: ChatMessage.statusFromKey(data['status'] as String?),
      walkTime: _date(data['walkTime']),
      walkLocationName: data['walkLocationName'] as String?,
    );
  }

  int _unreadForMe(Map<String, dynamic> data) {
    final map = data['unreadByUser'];
    if (map is Map && map[currentUserId] is int) {
      return map[currentUserId] as int;
    }
    return data['unreadCount'] as int? ?? 0;
  }

  List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => item.toString()).toList();
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  void _emit() {
    if (!_inboxController.isClosed) {
      _inboxController.add(currentInbox);
    }
  }
}
