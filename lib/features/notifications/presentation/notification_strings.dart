abstract final class NotificationStrings {
  static const String title = 'Obaveštenja';
  static const String tooltip = 'Obaveštenja';
  static const String empty = 'Nemate novih obaveštenja.';
  static const String markAll = 'Označi sve kao pročitano';
  static const String enableTitle = 'Omogući obaveštenja';
  static const String enableBody =
      'VauVau šalje obaveštenja o novim mečevima, porukama i pozivima na šetnju.';
  static const String enableConfirm = 'Omogući';
  static const String later = 'Kasnije';
  static const String pushMatchTitle = 'Novi meč!';
  static const String pushMessageTitle = 'Nova poruka';
  static const String pushWalkTitle = 'Poziv na šetnju';

  static String pushMatchBody(String dogName, String ownerName) =>
      '$dogName i $ownerName su novi meč.';

  static String pushMessageBody(String senderName, String preview) =>
      preview.trim().isEmpty
          ? 'Nova poruka od $senderName.'
          : '$senderName: $preview';

  static String pushWalkBody(String dogName, String ownerName) =>
      '$ownerName vas poziva u šetnju sa $dogName.';

  static String timeAgo(DateTime createdAt, [DateTime? now]) {
    final elapsed = (now ?? DateTime.now()).difference(createdAt);
    if (elapsed.inMinutes < 1) {
      return 'upravo sada';
    }
    if (elapsed.inMinutes < 60) {
      return 'pre ${elapsed.inMinutes} min';
    }
    if (elapsed.inHours < 24) {
      return 'pre ${elapsed.inHours} č';
    }
    return 'pre ${elapsed.inDays} d';
  }
}
