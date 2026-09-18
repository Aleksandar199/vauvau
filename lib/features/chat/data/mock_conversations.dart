import '../../discover/data/mock_discover_profiles.dart';
import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';

List<ChatConversation> seedChatConversations(DateTime now) {
  DiscoverProfile dog(String id) {
    return mockDiscoverProfiles.firstWhere((profile) => profile.id == id);
  }

  ChatConversation fromDog({
    required DiscoverProfile profile,
    required List<ChatMessage> messages,
    required DateTime lastActivityAt,
    bool isNewMatch = false,
    int unreadCount = 0,
  }) {
    return ChatConversation(
      id: 'chat-${profile.id}',
      dogId: profile.id,
      dogName: profile.name,
      ownerName: profile.ownerName,
      breed: profile.breed,
      location: profile.location,
      photoUrl: profile.photoUrls.first,
      participantIds: ['local-user', 'owner-${profile.id}'],
      dogIds: ['my-dog', profile.id],
      peerUserId: 'owner-${profile.id}',
      messages: messages,
      lastActivityAt: lastActivityAt,
      isNewMatch: isNewMatch,
      unreadCount: unreadCount,
    );
  }

  final todayEvening = DateTime(now.year, now.month, now.day, 18, 4);
  final yesterday = now.subtract(const Duration(days: 1));
  final yesterdayMorning = DateTime(
    yesterday.year,
    yesterday.month,
    yesterday.day,
    9,
    12,
  );

  return [
    fromDog(
      profile: dog('kiki'),
      messages: const [],
      lastActivityAt: now,
      isNewMatch: true,
    ),
    fromDog(
      profile: dog('nugget'),
      messages: const [],
      lastActivityAt: now.subtract(const Duration(minutes: 8)),
      isNewMatch: true,
    ),
    fromDog(
      profile: dog('lola'),
      lastActivityAt: todayEvening.add(const Duration(minutes: 2)),
      unreadCount: 1,
      messages: [
        ChatMessage(
          id: 'lola-1',
          text: 'Ćao! Luna i Lola bi mogle da se šetaju u Limanskom parku?',
          sentAt: todayEvening.subtract(const Duration(minutes: 12)),
          isMine: false,
        ),
        ChatMessage(
          id: 'lola-2',
          text: 'Super ideja, da li vam odgovara danas u 18h kod spomenika?',
          sentAt: todayEvening.subtract(const Duration(minutes: 8)),
          isMine: true,
        ),
        ChatMessage(
          id: 'lola-3',
          text: 'Vidimo se u Limanskom parku u 18h! Nosim loptu.',
          sentAt: todayEvening,
          isMine: false,
        ),
        ChatMessage(
          id: 'lola-4',
          text: 'Poziv na šetnju: Limanski Park',
          sentAt: todayEvening.add(const Duration(minutes: 2)),
          isMine: false,
          senderId: 'owner-lola',
          receiverId: 'local-user',
          type: ChatMessageType.walkInvite,
          status: WalkInviteStatus.pending,
          walkTime: todayEvening.add(const Duration(days: 1)),
          walkLocationName: 'Limanski Park',
        ),
      ],
    ),
    fromDog(
      profile: dog('rex'),
      lastActivityAt: yesterdayMorning,
      messages: [
        ChatMessage(
          id: 'rex-1',
          text: 'Rex voli Kalemegdan, jeste li u Beogradu ovog vikenda?',
          sentAt: yesterdayMorning.subtract(const Duration(minutes: 20)),
          isMine: false,
        ),
        ChatMessage(
          id: 'rex-2',
          text: 'Jesmo, možemo u subotu ujutru oko 9.',
          sentAt: yesterdayMorning,
          isMine: true,
        ),
      ],
    ),
    fromDog(
      profile: dog('djole'),
      lastActivityAt: yesterdayMorning.subtract(const Duration(hours: 2)),
      messages: [
        ChatMessage(
          id: 'djole-1',
          text: 'Đole je sporiji, kratka šetnja oko Bloka 44 pa kafa?',
          sentAt: yesterdayMorning.subtract(const Duration(hours: 2, minutes: 10)),
          isMine: false,
        ),
        ChatMessage(
          id: 'djole-2',
          text: 'Dogovoreno, sutra u 10 kod pet-friendly kafića.',
          sentAt: yesterdayMorning.subtract(const Duration(hours: 2)),
          isMine: true,
        ),
      ],
    ),
    fromDog(
      profile: dog('bobi'),
      lastActivityAt: todayEvening.subtract(const Duration(hours: 3)),
      messages: [
        ChatMessage(
          id: 'bobi-1',
          text: 'Bobi već trči na istrčavalištu, pridružite se?',
          sentAt: todayEvening.subtract(const Duration(hours: 3, minutes: 6)),
          isMine: false,
        ),
        ChatMessage(
          id: 'bobi-2',
          text: 'Krećemo odmah, Luna je spremna!',
          sentAt: todayEvening.subtract(const Duration(hours: 3)),
          isMine: true,
        ),
      ],
    ),
  ];
}
