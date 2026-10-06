import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/images/dog_photo_urls.dart';
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
  final StreamController<bool> _loadedController =
      StreamController<bool>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _messageSubs = {};
  var _hasLoadedInbox = false;
  Timer? _cacheHoldTimer;
  Timer? _emitDebounce;

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
        () => _rooms
            .doc(chat.id)
            .collection('messages')
            .orderBy('timestamp')
            .snapshots()
            .listen((messages) => _onMessages(chat.id, messages)),
      );
    }
    _inbox = [
      for (final chat in rooms)
        _merge(chat, _byId(chat.id)?.messages ?? const []),
    ];

    // Avoid flashing a partial cached inbox (often 1 room) before the
    // server snapshot arrives with the full conversation list.
    if (!_hasLoadedInbox) {
      final fromCache = snapshot.metadata.isFromCache;
      if (fromCache) {
        _cacheHoldTimer ??= Timer(const Duration(milliseconds: 1000), () {
          _publishInitialInbox();
        });
        return;
      }
      _cacheHoldTimer?.cancel();
      _cacheHoldTimer = null;
      _publishInitialInbox();
      return;
    }
    _emitNow();
  }

  void _publishInitialInbox() {
    if (_hasLoadedInbox) {
      _emitNow();
      return;
    }
    _hasLoadedInbox = true;
    if (!_loadedController.isClosed) {
      _loadedController.add(true);
    }
    _emitNow();
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
    if (!_hasLoadedInbox) {
      return;
    }
    // Coalesce rapid per-room message hydrations into one UI update.
    _emitDebounce?.cancel();
    _emitDebounce = Timer(const Duration(milliseconds: 80), _emitNow);
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
  bool get hasLoadedInbox => _hasLoadedInbox;

  @override
  Stream<List<ChatConversation>> watchInbox() async* {
    yield currentInbox;
    yield* _inboxController.stream;
  }

  @override
  Stream<bool> watchInboxLoaded() async* {
    yield _hasLoadedInbox;
    yield* _loadedController.stream;
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
    final peerId = profile.ownerId;
    final ids = [myUserId, peerId]..sort();
    final id = '${ids[0]}_${ids[1]}';
    final existing = _byId(id);
    if (existing != null) {
      return existing.id;
    }
    unawaited(_createRoom(
      id: id,
      myUserId: myUserId,
      myDogId: myDogId,
      peerId: peerId,
      peerProfile: profile,
    ));
    return id;
  }

  Future<void> _createRoom({
    required String id,
    required String myUserId,
    required String myDogId,
    required String peerId,
    required DiscoverProfile peerProfile,
  }) async {
    final myDogSnap = await _firestore.collection('dogs').doc(myDogId).get();
    final myDogData = myDogSnap.data() ?? <String, dynamic>{};
    final myDogName = myDogData['name'] as String? ?? '';
    final myOwnerName = myDogData['ownerName'] as String? ?? '';
    final myBreed = myDogData['breed'] as String? ?? '';
    final myPhotoUrl = resolvedDogPhotoUrl(collectPhotoUrls(myDogData));
    final peerPhotoUrl = resolvedDogPhotoUrl(peerProfile.photoUrls);

    await _rooms.doc(id).set({
      'id': id,
      'participantIds': [myUserId, peerId],
      'dogIds': [myDogId, peerProfile.id],
      'peerUserId': peerId,
      'dogId': peerProfile.id,
      'dogName': peerProfile.name,
      'ownerName': peerProfile.ownerName,
      'breed': peerProfile.breed,
      'location': peerProfile.location,
      'photoUrl': peerPhotoUrl,
      'dogNames': {myUserId: myDogName, peerId: peerProfile.name},
      'ownerNames': {myUserId: myOwnerName, peerId: peerProfile.ownerName},
      'breeds': {myUserId: myBreed, peerId: peerProfile.breed},
      'photoUrls': {myUserId: myPhotoUrl, peerId: peerPhotoUrl},
      'lastMessage': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'unreadByUser': <String, int>{myUserId: 0, peerId: 0},
      'isNewMatch': true,
    }, SetOptions(merge: true));
  }

  @override
  void markRead(String conversationId) {
    unawaited(
      _rooms.doc(conversationId).set({
        'unreadCount': 0,
        'unreadByUser': {currentUserId: 0},
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
    _cacheHoldTimer?.cancel();
    _emitDebounce?.cancel();
    _roomsSub?.cancel();
    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    _inboxController.close();
    _loadedController.close();
  }

  Future<void> _writeMessage(
    String conversationId,
    Map<String, dynamic> payload,
    String preview,
  ) async {
    await _rooms.doc(conversationId).collection('messages').add(payload);
    final peerId = _byId(conversationId)?.peerUserId ?? '';
    await _rooms.doc(conversationId).set({
      'lastMessage': preview,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'isNewMatch': false,
      if (peerId.isNotEmpty)
        'unreadByUser': {peerId: FieldValue.increment(1)},
    }, SetOptions(merge: true));
  }

  ChatConversation _conversationFromRoom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final participantIds = _stringList(data['participantIds']);
    final dogIds = _stringList(data['dogIds']);
    final fallbackPeerId = data['peerUserId'] as String? ?? '';
    final peerId = participantIds.firstWhere(
      (uid) => uid != currentUserId,
      orElse: () => fallbackPeerId,
    );
    final dogNames = data['dogNames'] as Map<String, dynamic>? ?? {};
    final ownerNames = data['ownerNames'] as Map<String, dynamic>? ?? {};
    final breeds = data['breeds'] as Map<String, dynamic>? ?? {};
    final photoUrls = data['photoUrls'] as Map<String, dynamic>? ?? {};
    final peerIndex = participantIds.indexOf(peerId);
    final peerDogId = (peerIndex >= 0 && peerIndex < dogIds.length)
        ? dogIds[peerIndex]
        : (data['dogId'] as String? ?? '');
    return ChatConversation(
      id: doc.id,
      dogId: peerDogId,
      dogName: dogNames[peerId] as String? ?? data['dogName'] as String? ?? '',
      ownerName:
          ownerNames[peerId] as String? ?? data['ownerName'] as String? ?? '',
      breed: breeds[peerId] as String? ?? data['breed'] as String? ?? '',
      location: data['location'] as String? ?? '',
      photoUrl:
          photoUrls[peerId] as String? ?? data['photoUrl'] as String? ?? '',
      participantIds: participantIds,
      dogIds: dogIds,
      peerUserId: peerId,
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

  void _emitNow() {
    if (!_inboxController.isClosed) {
      _inboxController.add(currentInbox);
    }
  }
}
