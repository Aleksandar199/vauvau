enum PushKind { match, message, walk, group, event }

class PushPayload {
  const PushPayload({
    required this.kind,
    required this.title,
    required this.body,
    this.dogId,
    this.peerUserId,
    this.conversationId,
    this.groupId,
    this.eventId,
  });

  final PushKind kind;
  final String title;
  final String body;
  final String? dogId;
  final String? peerUserId;
  final String? conversationId;
  final String? groupId;
  final String? eventId;

  String get typeName => switch (kind) {
        PushKind.match => 'match',
        PushKind.message => 'message',
        PushKind.walk => 'walk',
        PushKind.group => 'group',
        PushKind.event => 'event',
      };

  /// Chat messages (1:1, group, event) are announced only as a phone
  /// notification; they never go to the in-app notifications list.
  bool get showsInApp => switch (kind) {
        PushKind.message || PushKind.group || PushKind.event => false,
        PushKind.match || PushKind.walk => true,
      };

  Map<String, String> get data => {
        'type': typeName,
        'title': title,
        'body': body,
        'dogId': ?dogId,
        'peerUserId': ?peerUserId,
        'conversationId': ?conversationId,
        'groupId': ?groupId,
        'eventId': ?eventId,
      };

  factory PushPayload.fromData(Map<String, dynamic> data) {
    String? read(String key) {
      final value = data[key]?.toString().trim();
      if (value == null || value.isEmpty) {
        return null;
      }
      return value;
    }

    final nested = data['data'];
    if (nested is Map) {
      for (final entry in nested.entries) {
        data.putIfAbsent(entry.key.toString(), () => entry.value);
      }
    }

    return PushPayload(
      kind: kindFrom(read('type')),
      title: read('title') ?? '',
      body: read('body') ?? '',
      dogId: read('dogId') ?? read('senderDogId') ?? read('fromDogId'),
      peerUserId: read('peerUserId') ?? read('fromUserId') ?? read('senderUserId'),
      conversationId: read('conversationId') ?? read('chatId') ?? read('matchId'),
      groupId: read('groupId'),
      eventId: read('eventId'),
    );
  }

  static PushKind kindFrom(String? raw) {
    switch (raw) {
      case 'message':
        return PushKind.message;
      case 'walk':
        return PushKind.walk;
      case 'group':
        return PushKind.group;
      case 'event':
        return PushKind.event;
      default:
        return PushKind.match;
    }
  }
}
