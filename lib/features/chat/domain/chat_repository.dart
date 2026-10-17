import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_room.dart';
import 'story_reference.dart';

abstract class ChatRepository {
  List<ChatConversation> get currentInbox;

  /// True after the first usable inbox snapshot is ready for the UI.
  bool get hasLoadedInbox;

  Stream<List<ChatConversation>> watchInbox();

  /// Emits whenever [hasLoadedInbox] flips to true (and the current value).
  Stream<bool> watchInboxLoaded();

  Stream<List<ChatRoom>> watchRooms();

  Stream<List<ChatMessage>> watchMessages(String roomId);

  /// Walk invites per conversation id, kept live for every room — not only
  /// rooms opened in ChatDetail — so scheduled walks stay visible.
  Map<String, List<ChatMessage>> get currentWalkInvites;

  Stream<Map<String, List<ChatMessage>>> watchWalkInvites();

  /// Starts a limited messages listener for an open conversation.
  void attachRoom(String roomId);

  /// Cancels the messages listener when leaving the conversation screen.
  void detachRoom(String roomId);

  String openFromMatch({
    required DiscoverProfile profile,
    required String myUserId,
    required String myDogId,
  });

  void markRead(String conversationId);

  /// [story] marks the message as a reply to that story (Inbox shows it).
  Future<void> sendMessage(
    String conversationId,
    String rawText, {
    ChatMessage? replyTo,
    StoryReference? story,
  });

  Future<void> sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  });

  Future<void> sendLocationPin({
    required String conversationId,
    required String locationName,
  });

  Future<void> sendPhoto({
    required String conversationId,
    required String imageUrl,
    ChatMessage? replyTo,
  });

  Future<void> respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  });

  /// ❤️ on / off (same as [setMessageReaction] with ❤️ or null).
  Future<void> toggleMessageLike({
    required String conversationId,
    required String messageId,
  });

  /// Sets my emoji reaction on a message; null removes it.
  Future<void> setMessageReaction({
    required String conversationId,
    required String messageId,
    String? emoji,
  });

  void dispose();
}
