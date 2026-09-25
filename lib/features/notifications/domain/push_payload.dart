enum PushKind { match, message, walk }

class PushPayload {
  const PushPayload({
    required this.kind,
    required this.title,
    required this.body,
    this.dogId,
    this.peerUserId,
  });

  final PushKind kind;
  final String title;
  final String body;
  final String? dogId;
  final String? peerUserId;

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
      };

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
