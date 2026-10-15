import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/crash/crash_reporting.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/utils/message_preview.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../core/network/network_failure.dart';
import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/chat_room.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({
    required this._firestore,
    required this.currentUserId,
    this.currentUserName = '',
    this.currentUserAvatarUrl = '',
  });

  final FirebaseFirestore _firestore;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;
  List<ChatConversation> _inbox = const [];
  final StreamController<List<ChatConversation>> _inboxController =
      StreamController<List<ChatConversation>>.broadcast();
  final StreamController<bool> _loadedController =
      StreamController<bool>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _messageSubs = {};
  /// Messages that arrived before the parent room was in [_inbox].
  final Map<String, List<ChatMessage>> _pendingMessages = {};
  /// Walk-invite-only listeners for every room (independent of attachRoom).
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _walkInviteSubs = {};
  final Map<String, List<ChatMessage>> _walkInvites = {};
  final StreamController<Map<String, List<ChatMessage>>>
      _walkInvitesController =
      StreamController<Map<String, List<ChatMessage>>>.broadcast();
  var _hasLoadedInbox = false;
  var _localMessageSeq = 0;
  Timer? _cacheHoldTimer;
  Timer? _emitDebounce;

  /// How many recent messages to keep live per open room.
  static const int messagePageSize = 30;

  /// Ref-count of open ChatDetail screens per room.
  final Map<String, int> _roomAttachCounts = {};

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chats');

  void start() {
    if (currentUserId.isEmpty || currentUserId == 'local-user') {
      _publishEmptyInbox();
      return;
    }
    unawaited(_startGuarded());
  }

  Future<void> _startGuarded() async {
    final user = await FirestoreAuthGuard.ensureReady();
    if (user == null || user.uid != currentUserId) {
      _publishEmptyInbox();
      return;
    }
    await _roomsSub?.cancel();
    _roomsSub = _rooms
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .listen(
          _onRooms,
          onError: (Object error, StackTrace stack) {
            if (FirestoreAuthGuard.isPermissionDenied(error)) {
              FirestoreAuthGuard.logPermissionDenied(
                error,
                stack,
                label: 'chat.watchRooms',
              );
              _publishEmptyInbox();
              return;
            }
            developer.log('chat.watchRooms: $error', stackTrace: stack);
            unawaited(
              CrashReporting.recordError(
                error,
                stack,
                reason: 'chat.watchRooms',
              ),
            );
          },
        );
  }

  void _publishEmptyInbox() {
    _inbox = const [];
    _syncWalkInviteSubs(const {});
    if (!_hasLoadedInbox) {
      _hasLoadedInbox = true;
      if (!_loadedController.isClosed) {
        _loadedController.add(true);
      }
    }
    if (!_inboxController.isClosed) {
      _inboxController.add(_inbox);
    }
  }

  void _onRooms(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final rooms = snapshot.docs.map(_conversationFromRoom).toList();

    // Build inbox BEFORE attaching message listeners. Previously listeners
    // started first and the initial messages snapshot often arrived while the
    // new room was still missing from [_inbox], so the first send was dropped
    // until the next cold start.
    _inbox = [
      for (final chat in rooms)
        _merge(
          chat,
          _messageSubs.containsKey(chat.id)
              ? (_pendingMessages.remove(chat.id) ??
                  _byId(chat.id)?.messages ??
                  const [])
              : const [],
        ),
    ];

    final keep = rooms.map((chat) => chat.id).toSet();
    for (final id in _messageSubs.keys.toList()) {
      if (!keep.contains(id)) {
        _messageSubs.remove(id)?.cancel();
        _pendingMessages.remove(id);
        _roomAttachCounts.remove(id);
      }
    }
    _syncWalkInviteSubs(keep);
    // Messages are hydrated only for rooms opened in ChatDetail (attachRoom).

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

  void _ensureMessageSub(String roomId) {
    _messageSubs.putIfAbsent(
      roomId,
      () => _rooms
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(messagePageSize)
          .snapshots()
          .listen(
            (messages) => _onMessages(roomId, messages),
            onError: (Object error, StackTrace stack) {
              if (FirestoreAuthGuard.isPermissionDenied(error)) {
                FirestoreAuthGuard.logPermissionDenied(
                  error,
                  stack,
                  label: 'chat.watchMessages',
                );
                return;
              }
              developer.log(
                'chat.watchMessages($roomId): $error',
                stackTrace: stack,
              );
            },
          ),
    );
  }

  @override
  Map<String, List<ChatMessage>> get currentWalkInvites => {
        for (final entry in _walkInvites.entries)
          entry.key: List<ChatMessage>.from(entry.value),
      };

  @override
  Stream<Map<String, List<ChatMessage>>> watchWalkInvites() async* {
    yield currentWalkInvites;
    yield* _walkInvitesController.stream;
  }

  void _syncWalkInviteSubs(Set<String> roomIds) {
    var changed = false;
    for (final id in _walkInviteSubs.keys.toList()) {
      if (!roomIds.contains(id)) {
        _walkInviteSubs.remove(id)?.cancel();
        changed = _walkInvites.remove(id) != null || changed;
      }
    }
    for (final id in roomIds) {
      _walkInviteSubs.putIfAbsent(
        id,
        () => _rooms
            .doc(id)
            .collection('messages')
            .where('type', isEqualTo: 'walk_invite')
            .snapshots()
            .listen(
          (snapshot) {
            _walkInvites[id] = snapshot.docs.map(_messageFromDoc).toList();
            _emitWalkInvites();
          },
          onError: (Object error, StackTrace stack) {
            if (FirestoreAuthGuard.isPermissionDenied(error)) {
              FirestoreAuthGuard.logPermissionDenied(
                error,
                stack,
                label: 'chat.watchWalkInvites',
              );
              return;
            }
            developer.log(
              'chat.watchWalkInvites($id): $error',
              stackTrace: stack,
            );
          },
        ),
      );
    }
    if (changed) {
      _emitWalkInvites();
    }
  }

  void _emitWalkInvites() {
    if (!_walkInvitesController.isClosed) {
      _walkInvitesController.add(currentWalkInvites);
    }
  }

  @override
  void attachRoom(String roomId) {
    final id = roomId.trim();
    if (id.isEmpty) {
      return;
    }
    _roomAttachCounts[id] = (_roomAttachCounts[id] ?? 0) + 1;
    _ensureMessageSub(id);
  }

  @override
  void detachRoom(String roomId) {
    final id = roomId.trim();
    if (id.isEmpty) {
      return;
    }
    final next = (_roomAttachCounts[id] ?? 1) - 1;
    if (next > 0) {
      _roomAttachCounts[id] = next;
      return;
    }
    _roomAttachCounts.remove(id);
    _messageSubs.remove(id)?.cancel();
    _pendingMessages.remove(id);
    // Drop hydrated messages — inbox preview uses lastMessagePreview.
    if (_byId(id) != null) {
      _inbox = [
        for (final chat in _inbox)
          if (chat.id == id) chat.copyWith(messages: const []) else chat,
      ];
      if (_hasLoadedInbox) {
        _emitNow();
      }
    }
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
    // Query is newest-first; UI / optimistic merge expect oldest → newest.
    final messages =
        snapshot.docs.map(_messageFromDoc).toList().reversed.toList();
    if (_byId(roomId) == null) {
      _pendingMessages[roomId] = messages;
      return;
    }
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
    return FirestoreAuthGuard.guardedStream<List<ChatRoom>>(
      label: 'chat.watchRooms',
      empty: const [],
      create: () => _rooms
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
          ),
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return FirestoreAuthGuard.guardedStream<List<ChatMessage>>(
      label: 'chat.watchMessages',
      empty: const [],
      create: () => _rooms
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(messagePageSize)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(_messageFromDoc).toList().reversed.toList(),
          ),
    );
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
    // Optimistic room so ChatDetail can render and first send has an inbox row.
    // ChatDetail will attachRoom() for the limited messages listener.
    final placeholder = ChatConversation(
      id: id,
      dogId: profile.id,
      dogName: profile.name,
      ownerName: profile.ownerName,
      breed: profile.breed,
      location: profile.location,
      photoUrl: resolvedDogPhotoUrl(profile.photoUrls),
      participantIds: [myUserId, peerId],
      dogIds: [myDogId, profile.id],
      peerUserId: peerId,
      messages: _pendingMessages.remove(id) ?? const [],
      lastActivityAt: DateTime.now(),
      isNewMatch: true,
    );
    _inbox = [placeholder, ..._inbox];
    _emitNow();
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
    try {
      // Never rewrite an existing room: that would wipe lastMessage / unread,
      // and rules only let participants change those fields anyway.
      if ((await _rooms.doc(id).get()).exists) {
        return;
      }
    } catch (error) {
      developer.log(
        'createRoom existence check failed: $error',
        name: 'FirestoreChatRepository',
      );
    }
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
    final chat = _byId(conversationId);
    if (chat != null && chat.unreadCount > 0) {
      _inbox = [
        for (final item in _inbox)
          if (item.id == conversationId) item.copyWith(unreadCount: 0) else item,
      ];
      _emitNow();
    }
    unawaited(
      _rooms.doc(conversationId).set({
        'unreadCount': 0,
        'unreadByUser': {currentUserId: 0},
      }, SetOptions(merge: true)),
    );
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    String rawText, {
    ChatMessage? replyTo,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      return;
    }
    final peerId = _byId(conversationId)?.peerUserId ?? '';
    final replyFields = _replyFields(conversationId, replyTo);
    final localId = _nextLocalId();
    _appendOptimistic(
      conversationId,
      ChatMessage(
        id: localId,
        senderId: currentUserId,
        receiverId: peerId,
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
        text: text,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        replyToMessageId: replyFields['replyToMessageId'] ?? '',
        replyToText: replyFields['replyToText'] ?? '',
        replyToSenderName: replyFields['replyToSenderName'] ?? '',
      ),
    );
    await _writeMessage(
      conversationId,
      {
        'senderId': currentUserId,
        'receiverId': peerId,
        'senderName': currentUserName,
        'senderAvatarUrl': currentUserAvatarUrl,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'text',
        ...replyFields,
      },
      text,
      localMessageId: localId,
    );
  }

  @override
  Future<void> sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  }) async {
    final peerId = _byId(conversationId)?.peerUserId ?? '';
    final preview = 'Poziv na šetnju: $walkLocationName';
    final localId = _nextLocalId();
    _appendOptimistic(
      conversationId,
      ChatMessage(
        id: localId,
        senderId: currentUserId,
        receiverId: peerId,
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
        text: preview,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        type: ChatMessageType.walkInvite,
        status: WalkInviteStatus.pending,
        walkTime: walkTime,
        walkLocationName: walkLocationName,
      ),
    );
    await _writeMessage(
      conversationId,
      {
        'senderId': currentUserId,
        'receiverId': peerId,
        'senderName': currentUserName,
        'senderAvatarUrl': currentUserAvatarUrl,
        'text': preview,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'walk_invite',
        'status': 'pending',
        'walkTime': Timestamp.fromDate(walkTime),
        'walkLocationName': walkLocationName,
      },
      preview,
      localMessageId: localId,
    );
  }

  @override
  Future<void> sendLocationPin({
    required String conversationId,
    required String locationName,
  }) async {
    final peerId = _byId(conversationId)?.peerUserId ?? '';
    final localId = _nextLocalId();
    _appendOptimistic(
      conversationId,
      ChatMessage(
        id: localId,
        senderId: currentUserId,
        receiverId: peerId,
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
        text: locationName,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        type: ChatMessageType.locationPin,
      ),
    );
    await _writeMessage(
      conversationId,
      {
        'senderId': currentUserId,
        'receiverId': peerId,
        'senderName': currentUserName,
        'senderAvatarUrl': currentUserAvatarUrl,
        'text': locationName,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'location_pin',
      },
      locationName,
      localMessageId: localId,
    );
  }

  @override
  Future<void> sendPhoto({
    required String conversationId,
    required String imageUrl,
    ChatMessage? replyTo,
  }) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return;
    }
    final peerId = _byId(conversationId)?.peerUserId ?? '';
    const preview = '📷 Fotografija';
    final replyFields = _replyFields(conversationId, replyTo);
    final localId = _nextLocalId();
    _appendOptimistic(
      conversationId,
      ChatMessage(
        id: localId,
        senderId: currentUserId,
        receiverId: peerId,
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
        text: '',
        imageUrl: url,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        replyToMessageId: replyFields['replyToMessageId'] ?? '',
        replyToText: replyFields['replyToText'] ?? '',
        replyToSenderName: replyFields['replyToSenderName'] ?? '',
      ),
    );
    await _writeMessage(
      conversationId,
      {
        'senderId': currentUserId,
        'receiverId': peerId,
        'senderName': currentUserName,
        'senderAvatarUrl': currentUserAvatarUrl,
        'text': '',
        'imageUrl': url,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'text',
        ...replyFields,
      },
      preview,
      localMessageId: localId,
    );
  }

  Map<String, String> _replyFields(String conversationId, ChatMessage? replyTo) {
    if (replyTo == null) {
      return const {};
    }
    final chat = _byId(conversationId);
    final name = replyTo.senderName.trim().isNotEmpty
        ? replyTo.senderName.trim()
        : (replyTo.isMine
            ? (currentUserName.trim().isEmpty ? 'Ti' : currentUserName.trim())
            : (chat?.ownerName.trim().isNotEmpty == true
                ? chat!.ownerName.trim()
                : 'Korisnik'));
    return {
      'replyToMessageId': replyTo.id,
      'replyToText': ChatMessage.clipReplyText(replyTo.previewText),
      'replyToSenderName': name,
    };
  }

  void _appendOptimistic(String conversationId, ChatMessage message) {
    if (_byId(conversationId) == null) {
      return;
    }
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            messages: [...chat.messages, message],
            lastActivityAt: message.sentAt,
            isNewMatch: false,
            unreadCount: 0,
          )
        else
          chat,
    ];
    // Always push immediately — do not wait for inbox bootstrap debounce.
    _emitNow();
  }

  void _removeOptimistic(String conversationId, String localMessageId) {
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            messages: [
              for (final message in chat.messages)
                if (message.id != localMessageId) message,
            ],
          )
        else
          chat,
    ];
    _emitNow();
  }

  String _nextLocalId() {
    _localMessageSeq += 1;
    return 'local-$_localMessageSeq';
  }

  @override
  Future<void> toggleMessageLike({
    required String conversationId,
    required String messageId,
  }) async {
    if (currentUserId.isEmpty) {
      return;
    }
    List<String>? previous;
    final existing = _byId(conversationId);
    if (existing != null) {
      for (final message in existing.messages) {
        if (message.id == messageId) {
          previous = List<String>.from(message.likes);
          break;
        }
      }
    }
    final nextLikes = <String>[...(previous ?? const <String>[])];
    final liking = !nextLikes.contains(currentUserId);
    if (!liking) {
      nextLikes.remove(currentUserId);
    } else {
      nextLikes.add(currentUserId);
    }
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            messages: [
              for (final message in chat.messages)
                if (message.id == messageId)
                  message.copyWith(likes: nextLikes)
                else
                  message,
            ],
          )
        else
          chat,
    ];
    _emitNow();
    try {
      await _rooms
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          // Atomic array ops so a concurrent like from the peer is not lost.
          .update({
            'likes': liking
                ? FieldValue.arrayUnion([currentUserId])
                : FieldValue.arrayRemove([currentUserId]),
          });
    } catch (error, stack) {
      if (previous != null) {
        _inbox = [
          for (final chat in _inbox)
            if (chat.id == conversationId)
              chat.copyWith(
                messages: [
                  for (final message in chat.messages)
                    if (message.id == messageId)
                      message.copyWith(likes: previous)
                    else
                      message,
                ],
              )
            else
              chat,
        ];
        _emitNow();
      }
      await _reportWriteFailure('toggleMessageLike', error, stack);
      rethrow;
    }
  }

  @override
  Future<void> respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  }) async {
    WalkInviteStatus? previous;
    final existing = _byId(conversationId);
    if (existing != null) {
      for (final message in existing.messages) {
        if (message.id == messageId) {
          previous = message.status;
          break;
        }
      }
    }
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            messages: [
              for (final message in chat.messages)
                if (message.id == messageId)
                  message.copyWith(status: status)
                else
                  message,
            ],
          )
        else
          chat,
    ];
    _emitNow();
    try {
      await _rooms
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status':
            status == WalkInviteStatus.accepted ? 'accepted' : 'declined',
      });
    } catch (error, stack) {
      developer.log(
        'respondToWalkInvite failed: $error',
        name: 'FirestoreChatRepository',
        stackTrace: stack,
      );
      // Roll back optimistic status if Firestore rejects the write.
      _inbox = [
        for (final chat in _inbox)
          if (chat.id == conversationId)
            chat.copyWith(
              messages: [
                for (final message in chat.messages)
                  if (message.id == messageId)
                    message.copyWith(
                      status: previous ?? WalkInviteStatus.pending,
                    )
                  else
                    message,
              ],
            )
          else
            chat,
      ];
      _emitNow();
      await _reportWriteFailure('respondToWalkInvite', error, stack);
      rethrow;
    }
  }

  @override
  void dispose() {
    _cacheHoldTimer?.cancel();
    _emitDebounce?.cancel();
    _roomsSub?.cancel();
    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    _messageSubs.clear();
    for (final sub in _walkInviteSubs.values) {
      sub.cancel();
    }
    _walkInviteSubs.clear();
    _walkInvites.clear();
    _walkInvitesController.close();
    _roomAttachCounts.clear();
    _pendingMessages.clear();
    _inboxController.close();
    _loadedController.close();
  }

  Future<void> _writeMessage(
    String conversationId,
    Map<String, dynamic> payload,
    String preview, {
    required String localMessageId,
  }) async {
    final senderId = (payload['senderId'] as String? ?? '').trim();
    if (senderId.isEmpty ||
        senderId != currentUserId ||
        currentUserId.isEmpty ||
        currentUserId == 'local-user') {
      final error = StateError(
        'Poruka mora imati senderId ulogovanog korisnika.',
      );
      _removeOptimistic(conversationId, localMessageId);
      await _reportWriteFailure('sendMessage', error, StackTrace.current);
      throw error;
    }
    try {
      await _rooms.doc(conversationId).collection('messages').add(payload);
      final peerId = _byId(conversationId)?.peerUserId ?? '';
      await _rooms.doc(conversationId).set({
        'lastMessage': clipLastMessagePreview(preview),
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'isNewMatch': false,
        // Replying means everything before it was seen.
        'unreadByUser': {
          currentUserId: 0,
          if (peerId.isNotEmpty) peerId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));
    } catch (error, stack) {
      developer.log(
        'chat write failed: $error',
        name: 'FirestoreChatRepository',
        stackTrace: stack,
      );
      _removeOptimistic(conversationId, localMessageId);
      await _reportWriteFailure('sendMessage', error, stack);
      rethrow;
    }
  }

  Future<void> _reportWriteFailure(
    String action,
    Object error,
    StackTrace stack,
  ) async {
    await CrashReporting.log('chat.$action failed');
    if (isNetworkFailure(error)) {
      return;
    }
    await CrashReporting.recordError(
      error,
      stack,
      reason: 'chat.$action',
    );
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
      messages: _messageSubs.containsKey(doc.id)
          ? (_byId(doc.id)?.messages ??
              _pendingMessages[doc.id] ??
              const [])
          : const [],
      lastActivityAt: _date(data['lastMessageTimestamp']) ?? DateTime.now(),
      isNewMatch: data['isNewMatch'] as bool? ?? false,
      unreadCount: _unreadForMe(data),
      lastMessagePreview: data['lastMessage'] as String? ?? '',
    );
  }

  ChatMessage _messageFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final senderId = data['senderId'] as String? ?? '';
    final type = ChatMessage.typeFromKey(data['type'] as String?);
    final status = ChatMessage.statusFromKey(data['status'] as String?) ??
        (type == ChatMessageType.walkInvite ? WalkInviteStatus.pending : null);
    return ChatMessage(
      id: doc.id,
      senderId: senderId,
      receiverId: data['receiverId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sentAt: _date(data['timestamp']) ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      isMine: senderId == currentUserId,
      type: type,
      status: status,
      walkTime: _date(data['walkTime']),
      walkLocationName: data['walkLocationName'] as String?,
      replyToMessageId: data['replyToMessageId'] as String? ?? '',
      replyToText: data['replyToText'] as String? ?? '',
      replyToSenderName: data['replyToSenderName'] as String? ?? '',
      likes: ChatMessage.likesFrom(data['likes']),
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
