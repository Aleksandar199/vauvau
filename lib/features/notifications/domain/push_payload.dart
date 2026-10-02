enum PushKind { match, message, walk }

class PushPayload {
  const PushPayload({
    required this.kind,
    required this.title,
    required this.body,
    this.dogId,
    this.peerUserId,
    this.conversationId,
  });

  final PushKind kind;
  final String title;
  final String body;
  final String? dogId;
  final String? peerUserId;
  final String? conversationId;

  String get typeName => switch (kind) {
        PushKind.match => 'match',
        PushKind.message => 'message',
        PushKind.walk => 'walk',
      };

  Map<String, String> get data => {
        'type': typeName,
        'title': title,
        'body': body,
        'dogId': ?dogId,
        'peerUserId': ?peerUserId,
        'conversationId': ?conversationId,
      };

  factory PushPayload.fromData(Map<String, dynamic> data) {
    String? read(String key) {
      final value = data[key]?.toString().trim();
      if (value == null || value.isEmpty) {
        return null;
      }
      return value;
    }

    return PushPayload(
      kind: kindFrom(read('type')),
      title: read('title') ?? '',
      body: read('body') ?? '',
      dogId: read('dogId'),
      peerUserId: read('peerUserId') ?? read('fromUserId'),
      conversationId: read('conversationId') ?? read('chatId'),
    );
  }

  static PushKind kindFrom(String? raw) {
    switch (raw) {
      case 'message':
        return PushKind.message;
      case 'walk':
        return PushKind.walk;
      default:
        return PushKind.match;
    }
  }
}
