import '../../../core/l10n/l10n.dart';

abstract final class FollowsStrings {
  static String get follow => L10n.tr('Prati', 'Follow');
  static String get following => L10n.tr('Pratite', 'Following');
  static String get unfollow => L10n.tr('Otprati', 'Unfollow');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String unfollowTitle(String name) => L10n.tr(
        'Prestati da pratite: $name?',
        'Unfollow $name?',
      );
  static String get unfollowBody => L10n.tr(
        'Više nećete videti priče namenjene pratiocima. Lajkovi i mečevi ostaju isti.',
        'You will no longer see follower-only stories. Likes and matches stay the same.',
      );
  static String followedToast(String name) => L10n.tr(
        'Pratite: $name',
        'You follow $name',
      );
  static String get followFailed => L10n.tr(
        'Praćenje nije uspelo. Pokušajte ponovo.',
        'Could not follow. Try again.',
      );
  static String get unfollowFailed => L10n.tr(
        'Otpraćivanje nije uspelo. Pokušajte ponovo.',
        'Could not unfollow. Try again.',
      );
  static String get newFollowerTitle =>
      L10n.tr('Novi pratilac', 'New follower');
  static String newFollowerBody(String name) => L10n.tr(
        '$name vas sada prati.',
        '$name is now following you.',
      );
}
