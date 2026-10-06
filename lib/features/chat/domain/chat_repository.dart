import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_room.dart';

abstract class ChatRepository {
  List<ChatConversation> get currentInbox;

  /// True after the first usable inbox snapshot is ready for the UI.
  bool get hasLoadedInbox;

  Stream<List<ChatConversation>> watchInbox();

  /// Emits whenever [hasLoadedInbox] flips to true (and the current value).
  Stream<bool> watchInboxLoaded();

  Stream<List<ChatRoom>> watchRooms();

  Stream<List<ChatMessage>> watchMessages(String roomId);

  String openFromMatch({
    required DiscoverProfile profile,
    required String myUserId,
    required String myDogId,
  });

  void markRead(String conversationId);

  void sendMessage(String conversationId, String rawText);

  void sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  });

  void sendLocationPin({
    required String conversationId,
    required String locationName,
  });

  void respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  });

  void dispose();
}
