import '../../../core/l10n/l10n.dart';

abstract final class NotificationStrings {
  static String get title => L10n.tr('Obaveštenja', 'Notifications');
  static String get tooltip => L10n.tr('Obaveštenja', 'Notifications');
  static String get empty => L10n.tr('Nemate novih obaveštenja.', 'You have no new notifications.');
  static String get emptySubtitle => L10n.tr(
        'Ovde će se pojaviti mečevi, poruke i pozivi na šetnju.',
        'Matches, messages, and walk invites will appear here.',
      );
  static String get markAll => L10n.tr('Označi sve kao pročitano', 'Mark all as read');
  static String get enableTitle => L10n.tr('Omogući obaveštenja', 'Enable notifications');
  static String get enableBody => L10n.tr(
        'VauVau šalje obaveštenja o novim mečevima, porukama i pozivima na šetnju.',
        'VauVau sends notifications about new matches, messages, and walk invites.',
      );
  static String get enableConfirm => L10n.tr('Omogući', 'Enable');
  static String get later => L10n.tr('Kasnije', 'Later');
  static String get pushMatchTitle => L10n.tr('Novi meč!', 'New match!');
  static String get pushMessageTitle => L10n.tr('Nova poruka', 'New message');
  static String get pushWalkTitle => L10n.tr('Poziv na šetnju', 'Walk invite');

  static String pushMatchBody(String dogName, String ownerName) => L10n.isEnglish
      ? '$dogName and $ownerName are a new match.'
      : '$dogName i $ownerName su novi meč.';

  static String pushMessageBody(String senderName, String preview) {
    if (preview.trim().isEmpty) {
      return L10n.tr(
        'Nova poruka od $senderName.',
        'New message from $senderName.',
      );
    }
    return '$senderName: $preview';
  }

  static String pushGroupAlert(String groupTitle, int count) {
    final n = count < 1 ? 1 : count;
    if (L10n.isEnglish) {
      final suffix = n == 1 ? '1 new message' : '$n new messages';
      return '$groupTitle: $suffix';
    }
    final suffix = n == 1 ? '1 nova poruka' : '$n novih poruka';
    return '$groupTitle: $suffix';
  }

  static String pushWalkBody(String dogName, String ownerName) => L10n.isEnglish
      ? '$ownerName invites you for a walk with $dogName.'
      : '$ownerName vas poziva u šetnju sa $dogName.';

  static String timeAgo(DateTime createdAt, [DateTime? now]) {
    final elapsed = (now ?? DateTime.now()).difference(createdAt);
    if (elapsed.inMinutes < 1) {
      return L10n.tr('upravo sada', 'just now');
    }
    if (elapsed.inMinutes < 60) {
      return L10n.tr('pre ${elapsed.inMinutes} min', '${elapsed.inMinutes} min ago');
    }
    if (elapsed.inHours < 24) {
      return L10n.tr('pre ${elapsed.inHours} č', '${elapsed.inHours} h ago');
    }
    return L10n.tr('pre ${elapsed.inDays} d', '${elapsed.inDays} d ago');
  }
}
