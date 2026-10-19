import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_cards.dart';
import '../../../core/widgets/feed_state.dart';
import '../../map/domain/walk_record.dart';
import '../../map/presentation/walk_history_controller.dart';
import '../domain/belgrade_calendar.dart';
import '../domain/reward_rules.dart';
import '../domain/rewards_models.dart';
import 'rewards_controller.dart';
import 'rewards_strings.dart';
import 'widgets/walk_result_dialog.dart';

/// "Dnevni VauVau izazov": level, challenges, history and coupons.
class ChallengeHubScreen extends ConsumerStatefulWidget {
  const ChallengeHubScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<ChallengeHubScreen> createState() => _ChallengeHubScreenState();
}

class _ChallengeHubScreenState extends ConsumerState<ChallengeHubScreen> {
  @override
  void initState() {
    super.initState();
    // Pay walks saved offline and challenges met but not yet credited.
    Future<void>.microtask(() async {
      final paid = await ref.read(walkRewardsServiceProvider).syncPending();
      if (paid.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(RewardsStrings.synced(paid.length))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = RewardsPalette.of(context);
    ref.listen<AsyncValue<RewardSummary>>(rewardSummaryProvider, (prev, next) {
      final before = prev?.value;
      final after = next.value;
      if (before == null || after == null) return;
      final unlocked = LevelRules.unlocked(before.xp, after.xp);
      if (unlocked != null) showLevelUpDialog(context, unlocked);
    });
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.background,
          foregroundColor: palette.text,
          title: Text(
            RewardsStrings.hubTitle,
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
          ),
          bottom: TabBar(
            indicatorColor: palette.accent,
            labelColor: palette.accent,
            unselectedLabelColor: palette.muted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: RewardsStrings.tabChallenges),
              Tab(text: RewardsStrings.tabHistory),
              Tab(text: RewardsStrings.tabRewards),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ChallengesTab(), _HistoryTab(), _RewardsTab()],
        ),
      ),
    );
  }
}

class RewardsCard extends StatelessWidget {
  const RewardsCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = RewardsPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppCardTokens.softShadow(0.06),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = RewardsPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
        ],
      ),
    );
  }
}

/// Level badge, XP bar and points balance.
class LevelCard extends ConsumerWidget {
  const LevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = RewardsPalette.of(context);
    final async = ref.watch(rewardSummaryProvider);
    final summary = async.value ?? RewardSummary.empty;
    final level = LevelRules.levelFor(summary.xp);
    final next = LevelRules.nextLevel(summary.xp);
    return RewardsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: palette.accentSoft,
                child: Icon(level.icon, size: 30, color: palette.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RewardsStrings.levelLabel(level),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      RewardsStrings.xpTotal(summary.xp),
                      style: TextStyle(color: palette.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${summary.points}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: palette.accent,
                    ),
                  ),
                  Text(
                    RewardsStrings.pointsBalance,
                    style: TextStyle(fontSize: 11, color: palette.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: LevelRules.progress(summary.xp),
              minHeight: 10,
              backgroundColor: palette.accentSoft,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? RewardsStrings.topLevel
                : RewardsStrings.xpToNext(
                    LevelRules.xpToNext(summary.xp),
                    next,
                  ),
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            RewardsStrings.xpExplain,
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          if (async.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                RewardsStrings.loadError,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChallengesTab extends ConsumerWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = RewardsPalette.of(context);
    final challengesAsync = ref.watch(activeChallengesProvider);
    final progress = ref.watch(rewardProgressProvider).value;
    final ledger = ref.watch(rewardLedgerProvider).value ?? const [];
    final paidIds = {for (final e in ledger) e.id};
    final now = DateTime.now();

    Widget challengeList(ChallengePeriod period) {
      final items = (challengesAsync.value ?? const <Challenge>[])
          .where((c) => c.period == period)
          .toList();
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            period == ChallengePeriod.daily
                ? RewardsStrings.dailySection
                : RewardsStrings.weeklySection,
            subtitle: period == ChallengePeriod.daily
                ? RewardsStrings.dailyReset(BelgradeCalendar.nextMidnight(now))
                : RewardsStrings.weeklyReset(
                    BelgradeCalendar.nextWeekStart(now),
                  ),
          ),
          for (final c in items)
            ChallengeCard(
              challenge: c,
              progress: progress,
              completed:
                  progress != null &&
                  paidIds.contains(
                    LedgerEntry.challengeEntryId(c.id, c.periodKey(progress)),
                  ),
            ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const LevelCard(),
        if (challengesAsync.isLoading && !challengesAsync.hasValue)
          FeedStateView.loadingBody()
        else if (challengesAsync.hasError && !challengesAsync.hasValue)
          FeedStateView(
            icon: Icons.cloud_off,
            title: RewardsStrings.loadError,
            onRetry: () => ref.invalidate(activeChallengesProvider),
            retryLabel: RewardsStrings.retry,
            padding: const EdgeInsets.all(24),
          )
        else if ((challengesAsync.value ?? const []).isEmpty)
          FeedStateView(
            icon: Icons.flag_outlined,
            title: RewardsStrings.noChallenges,
            subtitle: RewardsStrings.noChallengesBody,
            padding: const EdgeInsets.all(24),
          )
        else ...[
          challengeList(ChallengePeriod.daily),
          challengeList(ChallengePeriod.weekly),
        ],
        _SectionTitle(RewardsStrings.howItWorks),
        RewardsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in RewardsStrings.rulesLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.pets, size: 14, color: palette.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(color: palette.text, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.progress,
    required this.completed,
  });

  final Challenge challenge;
  final RewardProgress? progress;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final palette = RewardsPalette.of(context);
    final p = progress;
    final fraction = completed
        ? 1.0
        : (p == null ? 0.0 : challenge.fraction(p));
    final current = p == null ? 0.0 : challenge.currentValue(p);
    final progressText = challenge.metric == ChallengeMetric.distance
        ? RewardsStrings.progressKm(current, challenge.target)
        : RewardsStrings.progressWalks(
            current.round(),
            challenge.target.round(),
          );
    return RewardsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.emoji_events : Icons.flag,
                color: palette.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFDCFCE7)
                      : palette.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  completed
                      ? RewardsStrings.completed
                      : RewardsStrings.inProgress,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: completed ? const Color(0xFF15803D) : palette.text,
                  ),
                ),
              ),
            ],
          ),
          if (challenge.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              challenge.description,
              style: TextStyle(color: palette.muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: palette.accentSoft,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                progressText,
                style: TextStyle(color: palette.text, fontSize: 12),
              ),
              const Spacer(),
              Text(
                RewardsStrings.reward(
                  challenge.rewardXp,
                  challenge.rewardPoints,
                ),
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = RewardsPalette.of(context);
    final walksAsync = ref.watch(walkHistoryProvider);
    final ledgerAsync = ref.watch(rewardLedgerProvider);
    return RefreshIndicator(
      color: palette.accent,
      onRefresh: () async {
        ref.invalidate(walkHistoryProvider);
        await ref
            .read(walkHistoryProvider.future)
            .catchError((_) => <WalkRecord>[]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionTitle(RewardsStrings.walksSection),
          walksAsync.when(
            loading: FeedStateView.loadingBody,
            error: (_, _) => _Empty(text: RewardsStrings.loadError),
            data: (walks) => walks.isEmpty
                ? _Empty(text: RewardsStrings.noWalks)
                : Column(
                    children: [
                      for (final walk in walks)
                        RewardsCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_walk,
                                color: palette.accent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_dateTime(walk.endedAt)} · ${walk.durationLabel}',
                                  style: TextStyle(color: palette.text),
                                ),
                              ),
                              Text(
                                walk.distanceLabel,
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          _SectionTitle(RewardsStrings.ledgerSection),
          ledgerAsync.when(
            loading: FeedStateView.loadingBody,
            error: (_, _) => _Empty(text: RewardsStrings.loadError),
            data: (entries) => entries.isEmpty
                ? _Empty(text: RewardsStrings.noLedger)
                : Column(
                    children: [
                      for (final entry in entries)
                        RewardsCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(switch (entry.type) {
                                LedgerType.walk => Icons.directions_walk,
                                LedgerType.challenge => Icons.emoji_events,
                                LedgerType.coupon => Icons.local_offer,
                                LedgerType.other => Icons.star,
                              }, color: palette.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.reason,
                                      style: TextStyle(color: palette.text),
                                    ),
                                    if (entry.createdAt != null)
                                      Text(
                                        _dateTime(entry.createdAt!),
                                        style: TextStyle(
                                          color: palette.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                RewardsStrings.ledgerAmount(entry),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: entry.points < 0
                                      ? const Color(0xFFB91C1C)
                                      : palette.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RewardsTab extends ConsumerWidget {
  const _RewardsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(activeCouponsProvider);
    final claimsAsync = ref.watch(myCouponClaimsProvider);
    final summary =
        ref.watch(rewardSummaryProvider).value ?? RewardSummary.empty;
    final now = DateTime.now();
    final claimedIds = {
      for (final c in claimsAsync.value ?? const <CouponClaim>[]) c.couponId,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const LevelCard(),
        _SectionTitle(RewardsStrings.myCoupons),
        claimsAsync.when(
          loading: FeedStateView.loadingBody,
          error: (_, _) => _Empty(text: RewardsStrings.loadError),
          data: (claims) => claims.isEmpty
              ? _Empty(text: RewardsStrings.noMyCoupons)
              : Column(
                  children: [
                    for (final claim in claims)
                      ClaimCard(claim: claim, now: now),
                  ],
                ),
        ),
        _SectionTitle(RewardsStrings.couponsSection),
        couponsAsync.when(
          loading: FeedStateView.loadingBody,
          error: (_, _) => FeedStateView(
            icon: Icons.cloud_off,
            title: RewardsStrings.loadError,
            onRetry: () => ref.invalidate(activeCouponsProvider),
            retryLabel: RewardsStrings.retry,
            padding: const EdgeInsets.all(24),
          ),
          data: (coupons) => coupons.isEmpty
              ? FeedStateView(
                  icon: Icons.local_offer_outlined,
                  title: RewardsStrings.noCoupons,
                  subtitle: RewardsStrings.noCouponsBody,
                  padding: const EdgeInsets.all(24),
                )
              : Column(
                  children: [
                    for (final coupon in coupons)
                      CouponCard(
                        coupon: coupon,
                        now: now,
                        balance: summary.points,
                        alreadyClaimed: claimedIds.contains(coupon.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class CouponCard extends ConsumerStatefulWidget {
  const CouponCard({
    super.key,
    required this.coupon,
    required this.now,
    required this.balance,
    required this.alreadyClaimed,
  });

  final Coupon coupon;
  final DateTime now;
  final int balance;
  final bool alreadyClaimed;

  @override
  ConsumerState<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends ConsumerState<CouponCard> {
  var _busy = false;

  Future<void> _claim() async {
    final coupon = widget.coupon;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(RewardsStrings.claimConfirmTitle(coupon)),
        content: Text(RewardsStrings.claimConfirmBody(coupon)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(RewardsStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(RewardsStrings.claim),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final claim = await ref
          .read(walkRewardsServiceProvider)
          .claimCoupon(coupon.id);
      messenger.showSnackBar(
        SnackBar(content: Text(RewardsStrings.claimed(claim.code))),
      );
    } on RewardsException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(RewardsStrings.error(error.code))),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(RewardsStrings.error(RewardsErrorCode.unknown))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = RewardsPalette.of(context);
    final coupon = widget.coupon;
    final availability = coupon.availability(widget.now);
    final canClaim =
        availability == CouponAvailability.available &&
        !widget.alreadyClaimed &&
        widget.balance >= coupon.pointsCost &&
        !_busy;
    return RewardsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  coupon.partnerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
              ),
              Text(
                RewardsStrings.availability(availability),
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            coupon.discountLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: palette.accent,
            ),
          ),
          if (coupon.title.isNotEmpty)
            Text(coupon.title, style: TextStyle(color: palette.text)),
          if (coupon.description.isNotEmpty)
            Text(
              coupon.description,
              style: TextStyle(color: palette.muted, fontSize: 13),
            ),
          if (coupon.terms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${RewardsStrings.terms}: ${coupon.terms}',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              Text(
                availability == CouponAvailability.notStarted
                    ? RewardsStrings.startsOn(coupon.startsAt)
                    : RewardsStrings.validUntil(coupon.expiresAt),
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              Text(
                RewardsStrings.remaining(coupon.remaining),
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                RewardsStrings.cost(coupon.pointsCost),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: palette.accent),
                onPressed: canClaim ? _claim : null,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.alreadyClaimed
                            ? RewardsStrings.claimStatus(ClaimStatus.claimed)
                            : RewardsStrings.claim,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ClaimCard extends ConsumerWidget {
  const ClaimCard({super.key, required this.claim, required this.now});

  final CouponClaim claim;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = RewardsPalette.of(context);
    final status = claim.effectiveStatus(now);
    final active = status == ClaimStatus.claimed;
    return RewardsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${claim.partnerName} · ${claim.discountLabel}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
              ),
              Text(
                RewardsStrings.claimStatus(status),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: active ? const Color(0xFF15803D) : palette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onLongPress: () =>
                Clipboard.setData(ClipboardData(text: claim.code)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? palette.accentSoft : palette.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.accent,
                  width: active ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                claim.code,
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                  color: active ? palette.text : palette.muted,
                  decoration: active ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
          if (claim.expiresAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                RewardsStrings.validUntil(claim.expiresAt!),
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ),
          if (active) ...[
            const SizedBox(height: 6),
            Text(
              RewardsStrings.showAtShop,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = RewardsPalette.of(context);
    return RewardsCard(
      child: Text(text, style: TextStyle(color: palette.muted)),
    );
  }
}

String _dateTime(DateTime d) {
  final l = d.toLocal();
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day}.${l.month}. ${l.hour}:$mm';
}
