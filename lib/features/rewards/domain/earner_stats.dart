import 'reward_rules.dart';
import 'rewards_models.dart';

/// One user's walk rewards over the last days (admin review).
class EarnerSummary {
  const EarnerSummary({
    required this.userId,
    required this.points,
    required this.km,
    required this.walks,
    required this.daysAtCap,
    required this.activeDays,
  });

  final String userId;

  /// Points from walks (km only, no challenge bonuses).
  final int points;
  final int km;

  /// Walk entries that paid at least 1 km.
  final int walks;

  /// Days where the daily km points limit was reached.
  final int daysAtCap;
  final int activeDays;

  /// Hits the daily limit almost every day: possible farming (or a very
  /// dedicated walker) – the admin decides.
  bool get looksSuspicious => daysAtCap >= EarnerStats.suspiciousDaysAtCap;
}

abstract final class EarnerStats {
  /// Days at the limit (of 7) that raise the flag.
  static const int suspiciousDaysAtCap = 5;

  /// Users with the most walk points in the last [days] days.
  static List<EarnerSummary> top(
    List<LedgerEntry> entries, {
    required DateTime now,
    int days = 7,
    int limit = 8,
  }) {
    final since = now.subtract(Duration(days: days));
    final byUser = <String, List<LedgerEntry>>{};
    for (final entry in entries) {
      final at = entry.createdAt;
      if (entry.type != LedgerType.walk ||
          entry.userId.isEmpty ||
          at == null ||
          at.isBefore(since)) {
        continue;
      }
      byUser.putIfAbsent(entry.userId, () => []).add(entry);
    }
    final result = <EarnerSummary>[];
    for (final item in byUser.entries) {
      final pointsByDay = <int, int>{};
      var points = 0;
      var km = 0;
      var walks = 0;
      for (final entry in item.value) {
        points += entry.points;
        km += entry.km;
        if (entry.km >= RewardRules.minRewardKm) walks++;
        pointsByDay.update(
          entry.periodKey,
          (sum) => sum + entry.points,
          ifAbsent: () => entry.points,
        );
      }
      if (points <= 0) continue;
      result.add(
        EarnerSummary(
          userId: item.key,
          points: points,
          km: km,
          walks: walks,
          daysAtCap: pointsByDay.values
              .where((sum) => sum >= RewardRules.dailyKmPointsCap)
              .length,
          activeDays: pointsByDay.length,
        ),
      );
    }
    result.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0 ? byPoints : b.daysAtCap.compareTo(a.daysAtCap);
    });
    return result.take(limit).toList();
  }
}
