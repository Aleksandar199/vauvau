import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../../../partners/domain/partner.dart';
import '../../../partners/presentation/partner_providers.dart';
import '../../../dogs/presentation/health/reminder_strings.dart';
import '../../../rewards/data/birthday_reward_source.dart';
import '../../../rewards/domain/birthday_reward.dart';
import '../../../rewards/domain/reward_rules.dart';
import '../../../rewards/domain/rewards_models.dart';
import '../../../rewards/domain/rewards_repository.dart';
import '../../../rewards/presentation/rewards_controller.dart';
import '../../../rewards/presentation/rewards_strings.dart';
import '../admin_controller.dart';
import '../admin_strings.dart';
import '../widgets/admin_ref_widgets.dart';

final _adminChallengesProvider = StreamProvider.autoDispose<List<Challenge>>(
  (ref) =>
      ref.watch(rewardsRepositoryProvider).watchChallenges(activeOnly: false),
);

final _adminCouponsProvider = StreamProvider.autoDispose<List<Coupon>>(
  (ref) => ref.watch(rewardsRepositoryProvider).watchCoupons(activeOnly: false),
);

final _adminLedgerProvider = StreamProvider.autoDispose<List<LedgerEntry>>(
  (ref) => ref.watch(rewardsRepositoryProvider).watchAllLedger(),
);

final _adminClaimsProvider = StreamProvider.autoDispose<List<CouponClaim>>(
  (ref) => ref.watch(rewardsRepositoryProvider).watchAllClaims(),
);

/// Admin: challenges, coupons, points log and claimed coupons. Writes are
/// allowed by the rules only for `isAdmin()` (users/{uid}.role == 'admin').
class AdminRewardsTab extends StatelessWidget {
  const AdminRewardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: primary,
            indicatorColor: primary,
            tabs: [
              Tab(text: AdminStrings.rewardsChallenges),
              Tab(text: AdminStrings.rewardsCoupons),
              Tab(text: AdminStrings.rewardsPartners),
              Tab(text: AdminStrings.rewardsLedger),
              Tab(text: AdminStrings.rewardsClaims),
              Tab(text: AdminStrings.birthdayTab),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ChallengesAdmin(),
                _CouponsAdmin(),
                _PartnersAdmin(),
                _LedgerAdmin(),
                _ClaimsAdmin(),
                _BirthdayRewardAdmin(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _asyncList<T>(
  AsyncValue<List<T>> async, {
  required String empty,
  required Widget Function(List<T> items) data,
}) {
  return async.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => Center(child: Text(AdminStrings.loadError)),
    data: (items) => items.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(empty, textAlign: TextAlign.center),
            ),
          )
        : data(items),
  );
}

Future<void> _guard(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(AdminStrings.rewardsSaved)));
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('${AdminStrings.rewardsSaveFailed} ($error)')),
    );
  }
}

class _ChallengesAdmin extends ConsumerWidget {
  const _ChallengesAdmin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(rewardsRepositoryProvider);
    final async = ref.watch(_adminChallengesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-challenge-add',
        onPressed: () => _editChallenge(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(AdminStrings.rewardsNewChallenge),
      ),
      body: Column(
        children: [
          if ((async.value ?? const []).isEmpty && !async.isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _guard(context, () async {
                  for (final c in RewardRules.defaultChallenges) {
                    await repo.saveChallenge(c.copyWith(isActive: false));
                  }
                }),
                icon: const Icon(Icons.playlist_add),
                label: Text(AdminStrings.rewardsSeedChallenges),
              ),
            ),
          Expanded(
            child: _asyncList<Challenge>(
              async,
              empty: AdminStrings.rewardsNoChallenges,
              data: (items) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  for (final c in items)
                    Card(
                      child: ListTile(
                        title: Text(c.title),
                        subtitle: Text(
                          '${c.period == ChallengePeriod.daily ? AdminStrings.rewardsDaily : AdminStrings.rewardsWeekly}'
                          ' · ${c.metric == ChallengeMetric.distance ? '${c.target} km' : '${c.target.round()} ${AdminStrings.rewardsWalksUnit}'}'
                          ' · ${RewardsStrings.reward(c.rewardXp, c.rewardPoints)}',
                        ),
                        onTap: () => _editChallenge(context, ref, c),
                        trailing: Switch(
                          value: c.isActive,
                          onChanged: (v) => _guard(
                            context,
                            () => repo.setChallengeActive(c.id, v),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editChallenge(
    BuildContext context,
    WidgetRef ref,
    Challenge? existing,
  ) async {
    final result = await showDialog<Challenge>(
      context: context,
      builder: (_) => _ChallengeDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;
    await _guard(
      context,
      () => ref.read(rewardsRepositoryProvider).saveChallenge(result),
    );
  }
}

class _ChallengeDialog extends StatefulWidget {
  const _ChallengeDialog({this.existing});

  final Challenge? existing;

  @override
  State<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<_ChallengeDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );
  late final _target = TextEditingController(
    text: widget.existing?.target.toString() ?? '2',
  );
  late final _xp = TextEditingController(
    text: '${widget.existing?.rewardXp ?? RewardRules.dailyChallengeXp}',
  );
  late final _points = TextEditingController(
    text:
        '${widget.existing?.rewardPoints ?? RewardRules.dailyChallengePoints}',
  );
  late final _sort = TextEditingController(
    text: '${widget.existing?.sortOrder ?? 10}',
  );
  late var _period = widget.existing?.period ?? ChallengePeriod.daily;
  late var _metric = widget.existing?.metric ?? ChallengeMetric.distance;
  late var _active = widget.existing?.isActive ?? false;

  @override
  void dispose() {
    for (final c in [_title, _description, _target, _xp, _points, _sort]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? AdminStrings.rewardsNewChallenge
            : AdminStrings.rewardsEditChallenge,
      ),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _text(_title, AdminStrings.rewardsTitleField, max: 80),
              _text(
                _description,
                AdminStrings.rewardsDescriptionField,
                max: 200,
                required: false,
              ),
              DropdownButtonFormField<ChallengePeriod>(
                initialValue: _period,
                decoration: InputDecoration(
                  labelText: AdminStrings.rewardsPeriod,
                ),
                items: [
                  DropdownMenuItem(
                    value: ChallengePeriod.daily,
                    child: Text(AdminStrings.rewardsDaily),
                  ),
                  DropdownMenuItem(
                    value: ChallengePeriod.weekly,
                    child: Text(AdminStrings.rewardsWeekly),
                  ),
                ],
                onChanged: (v) => setState(() => _period = v ?? _period),
              ),
              DropdownButtonFormField<ChallengeMetric>(
                initialValue: _metric,
                decoration: InputDecoration(
                  labelText: AdminStrings.rewardsMetric,
                ),
                items: [
                  DropdownMenuItem(
                    value: ChallengeMetric.distance,
                    child: Text(AdminStrings.rewardsMetricKm),
                  ),
                  DropdownMenuItem(
                    value: ChallengeMetric.walks,
                    child: Text(AdminStrings.rewardsMetricWalks),
                  ),
                ],
                onChanged: (v) => setState(() => _metric = v ?? _metric),
              ),
              _number(_target, AdminStrings.rewardsTarget, decimal: true),
              _number(_xp, 'XP', max: 100),
              _number(_points, AdminStrings.rewardsPointsField, max: 100),
              _number(
                _sort,
                AdminStrings.rewardsSort,
                max: 999,
                allowZero: true,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AdminStrings.rewardsActive),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AdminStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(
              Challenge(
                id: widget.existing?.id ?? '',
                title: _title.text.trim(),
                description: _description.text.trim(),
                period: _period,
                metric: _metric,
                target: double.parse(_target.text.replaceAll(',', '.')),
                rewardXp: int.parse(_xp.text),
                rewardPoints: int.parse(_points.text),
                isActive: _active,
                sortOrder: int.parse(_sort.text),
              ),
            );
          },
          child: Text(AdminStrings.save),
        ),
      ],
    );
  }
}

Widget _text(
  TextEditingController controller,
  String label, {
  int max = 120,
  bool required = true,
}) {
  return TextFormField(
    controller: controller,
    maxLength: max,
    decoration: InputDecoration(labelText: label),
    validator: (v) => required && (v ?? '').trim().isEmpty
        ? AdminStrings.rewardsRequired
        : null,
  );
}

Widget _number(
  TextEditingController controller,
  String label, {
  bool decimal = false,
  int max = 100000,
  bool allowZero = false,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: decimal ? null : [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    validator: (v) {
      final value = double.tryParse((v ?? '').replaceAll(',', '.'));
      if (value == null) return AdminStrings.rewardsNumber;
      if (value < 0 || (!allowZero && value == 0) || value > max) {
        return AdminStrings.rewardsRange(max);
      }
      return null;
    },
  );
}

class _CouponsAdmin extends ConsumerWidget {
  const _CouponsAdmin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(rewardsRepositoryProvider);
    final now = DateTime.now();
    // Keeps the partner list loaded for the coupon form.
    ref.watch(partnersProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-coupon-add',
        onPressed: () => _editCoupon(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(AdminStrings.rewardsNewCoupon),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => _addTemplates(context, ref),
              icon: const Icon(Icons.playlist_add),
              label: Text(AdminStrings.rewardsSeedCoupons),
            ),
          ),
          Expanded(child: _list(context, ref, repo, now)),
        ],
      ),
    );
  }

  /// Adds the missing templates (fixed ids, so nothing is duplicated and
  /// edited coupons are not overwritten).
  Future<void> _addTemplates(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(rewardsRepositoryProvider);
    final existing = {
      for (final c in ref.read(_adminCouponsProvider).value ?? const <Coupon>[])
        c.id,
    };
    final missing = [
      for (final c in RewardRules.defaultCoupons(DateTime.now()))
        if (!existing.contains(c.id)) c,
    ];
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminStrings.rewardsTemplatesExist)),
      );
      return;
    }
    await _guard(context, () async {
      for (final c in missing) {
        await repo.saveCoupon(c);
      }
    });
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    RewardsRepository repo,
    DateTime now,
  ) {
    return _asyncList<Coupon>(
      ref.watch(_adminCouponsProvider),
      empty: AdminStrings.rewardsNoCoupons,
      data: (items) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          for (final c in items)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text('${c.partnerName} · ${c.discountLabel}'),
                    subtitle: Text(
                      '${RewardsStrings.cost(c.pointsCost)} · '
                      '${c.claimedCount}/${c.maxQuantity} · '
                      '${RewardsStrings.validUntil(c.expiresAt)} · '
                      '${RewardsStrings.availability(c.availability(now))}',
                    ),
                    onTap: () => _editCoupon(context, ref, c),
                    trailing: Switch(
                      value: c.isActive,
                      onChanged: (v) {
                        if (v &&
                            RewardRules.isPlaceholderPartner(c.partnerName)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AdminStrings.rewardsNeedPartner),
                            ),
                          );
                          return;
                        }
                        _guard(context, () => repo.setCouponActive(c.id, v));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AdminStrings.rewardsRemaining(
                              c.remaining,
                              c.claimedCount,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton.icon(
                          key: ValueKey('coupon-remaining-${c.id}'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          onPressed: () => _editRemaining(context, repo, c),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(AdminStrings.rewardsChangeRemaining),
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

  Future<void> _editRemaining(
    BuildContext context,
    RewardsRepository repo,
    Coupon coupon,
  ) async {
    final remaining = await showDialog<int>(
      context: context,
      builder: (_) => _RemainingDialog(coupon: coupon),
    );
    if (remaining == null || !context.mounted) return;
    await _guard(context, () => repo.setCouponRemaining(coupon.id, remaining));
  }

  Future<void> _editCoupon(
    BuildContext context,
    WidgetRef ref,
    Coupon? existing,
  ) async {
    final result = await showDialog<Coupon>(
      context: context,
      builder: (_) => _CouponDialog(
        existing: existing,
        partners: ref.read(partnersProvider).value ?? const [],
      ),
    );
    if (result == null || !context.mounted) return;
    await _guard(
      context,
      () => ref.read(rewardsRepositoryProvider).saveCoupon(result),
    );
  }
}

class _CouponDialog extends StatefulWidget {
  const _CouponDialog({this.existing, this.partners = const []});

  final Coupon? existing;
  final List<Partner> partners;

  @override
  State<_CouponDialog> createState() => _CouponDialogState();
}

class _CouponDialogState extends State<_CouponDialog> {
  final _form = GlobalKey<FormState>();
  late final _partner = TextEditingController(
    text: widget.existing?.partnerName,
  );
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );
  late final _discount = TextEditingController(
    text: widget.existing?.discountLabel,
  );
  late final _cost = TextEditingController(
    text: '${widget.existing?.pointsCost ?? 100}',
  );
  late final _quantity = TextEditingController(
    text: '${widget.existing?.maxQuantity ?? 50}',
  );
  late final _terms = TextEditingController(text: widget.existing?.terms);
  late var _startsAt = widget.existing?.startsAt ?? DateTime.now();
  late var _expiresAt =
      widget.existing?.expiresAt ??
      DateTime.now().add(const Duration(days: 30));
  late var _partnerId = widget.existing?.partnerId ?? '';
  late var _active = widget.existing?.isActive ?? false;

  @override
  void dispose() {
    for (final c in [
      _partner,
      _title,
      _description,
      _discount,
      _cost,
      _quantity,
      _terms,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final initial = start ? _startsAt : _expiresAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startsAt = DateTime(picked.year, picked.month, picked.day);
      } else {
        // Valid through the whole chosen day.
        _expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final claimed = widget.existing?.claimedCount ?? 0;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? AdminStrings.rewardsNewCoupon
            : AdminStrings.rewardsEditCoupon,
      ),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: const ValueKey('coupon-partner'),
                initialValue: widget.partners.any((p) => p.id == _partnerId)
                    ? _partnerId
                    : '',
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AdminStrings.couponPartner,
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(AdminStrings.couponNoPartner),
                  ),
                  for (final p in widget.partners)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (id) => setState(() {
                  _partnerId = id ?? '';
                  for (final p in widget.partners) {
                    if (p.id == _partnerId) _partner.text = p.name;
                  }
                }),
              ),
              _text(_partner, AdminStrings.rewardsPartner, max: 60),
              _text(_discount, AdminStrings.rewardsDiscount, max: 40),
              _text(
                _title,
                AdminStrings.rewardsTitleField,
                max: 80,
                required: false,
              ),
              _text(
                _description,
                AdminStrings.rewardsDescriptionField,
                max: 300,
                required: false,
              ),
              _number(_cost, AdminStrings.rewardsCost, max: 100000),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: AdminStrings.rewardsQuantity,
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return AdminStrings.rewardsNumber;
                  if (n < claimed) {
                    return AdminStrings.rewardsBelowClaimed(claimed);
                  }
                  return null;
                },
              ),
              _text(
                _terms,
                AdminStrings.rewardsTerms,
                max: 400,
                required: false,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AdminStrings.rewardsStart),
                subtitle: Text(RewardsStrings.startsOn(_startsAt)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () => _pick(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AdminStrings.rewardsEnd),
                subtitle: Text(RewardsStrings.validUntil(_expiresAt)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () => _pick(false),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AdminStrings.rewardsActive),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AdminStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            if (_active && RewardRules.isPlaceholderPartner(_partner.text)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AdminStrings.rewardsNeedPartner)),
              );
              return;
            }
            if (!_expiresAt.isAfter(_startsAt)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AdminStrings.rewardsDates)),
              );
              return;
            }
            Navigator.of(context).pop(
              Coupon(
                id: widget.existing?.id ?? '',
                partnerName: _partner.text.trim(),
                title: _title.text.trim(),
                description: _description.text.trim(),
                discountLabel: _discount.text.trim(),
                pointsCost: int.parse(_cost.text),
                startsAt: _startsAt,
                expiresAt: _expiresAt,
                maxQuantity: int.parse(_quantity.text),
                claimedCount: claimed,
                terms: _terms.text.trim(),
                isActive: _active,
                partnerId: _partnerId,
              ),
            );
          },
          child: Text(AdminStrings.save),
        ),
      ],
    );
  }
}

class _LedgerAdmin extends ConsumerWidget {
  const _LedgerAdmin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _asyncList<LedgerEntry>(
      ref.watch(_adminLedgerProvider),
      empty: AdminStrings.rewardsNoLedger,
      data: (items) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final e = items[i];
          return ListTile(
            dense: true,
            title: Text(e.reason),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminUserLabel(uid: e.userId, avatarSize: 18),
                if (e.createdAt != null)
                  Text(AdminStrings.timestamp(e.createdAt!.toLocal())),
              ],
            ),
            trailing: Text(
              RewardsStrings.ledgerAmount(e),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }
}

/// Coupons users claimed. The admin marks a coupon used when the partner
/// confirms the purchase (or cancels it); the user then sees it crossed out.
class _ClaimsAdmin extends ConsumerStatefulWidget {
  const _ClaimsAdmin();

  @override
  ConsumerState<_ClaimsAdmin> createState() => _ClaimsAdminState();
}

class _ClaimsAdminState extends ConsumerState<_ClaimsAdmin> {
  final _search = TextEditingController();
  var _activeOnly = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setStatus(CouponClaim claim, ClaimStatus status) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(claim.code),
        content: Text(
          status == ClaimStatus.redeemed
              ? AdminStrings.rewardsConfirmRedeem(claim)
              : AdminStrings.rewardsConfirmCancel(claim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AdminStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(RewardsStrings.claimStatus(status)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _guard(
      context,
      () => ref
          .read(rewardsRepositoryProvider)
          .adminSetClaimStatus(
            claim.id,
            status,
            byUid: ref.read(authStateProvider).value?.uid ?? '',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final query = _search.text.trim().toUpperCase();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _search,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: AdminStrings.rewardsSearchCode,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              ChoiceChip(
                label: Text(AdminStrings.rewardsFilterActive),
                selected: _activeOnly,
                onSelected: (_) => setState(() => _activeOnly = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(AdminStrings.rewardsFilterAll),
                selected: !_activeOnly,
                onSelected: (_) => setState(() => _activeOnly = false),
              ),
            ],
          ),
        ),
        Expanded(
          child: _asyncList<CouponClaim>(
            ref.watch(_adminClaimsProvider),
            empty: AdminStrings.rewardsNoClaims,
            data: (all) {
              final items = [
                for (final c in all)
                  if ((query.isEmpty || c.code.contains(query)) &&
                      (!_activeOnly ||
                          c.effectiveStatus(now) == ClaimStatus.claimed))
                    c,
              ];
              if (items.isEmpty) {
                return Center(child: Text(AdminStrings.rewardsNoMatch));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (final c in items)
                    _ClaimAdminCard(
                      claim: c,
                      now: now,
                      onRedeem: () => _setStatus(c, ClaimStatus.redeemed),
                      onCancel: () => _setStatus(c, ClaimStatus.cancelled),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClaimAdminCard extends StatelessWidget {
  const _ClaimAdminCard({
    required this.claim,
    required this.now,
    required this.onRedeem,
    required this.onCancel,
  });

  final CouponClaim claim;
  final DateTime now;
  final VoidCallback onRedeem;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final status = claim.effectiveStatus(now);
    final active = status == ClaimStatus.claimed;
    final color = switch (status) {
      ClaimStatus.claimed => const Color(0xFF15803D),
      ClaimStatus.redeemed => const Color(0xFF475569),
      ClaimStatus.expired => const Color(0xFFB45309),
      ClaimStatus.cancelled => const Color(0xFFB91C1C),
    };
    String date(DateTime? d) {
      if (d == null) return '–';
      final l = d.toLocal();
      return '${l.day}.${l.month}.${l.year}. '
          '${l.hour}:${l.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    claim.code,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    RewardsStrings.claimStatus(status),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${claim.partnerName} · ${claim.discountLabel}'),
            AdminUserLabel(
              uid: claim.userId,
              prefix: AdminStrings.userLabel,
              avatarSize: 20,
            ),
            Text(
              AdminStrings.rewardsClaimDates(
                date(claim.claimedAt),
                date(claim.expiresAt),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (claim.redeemedAt != null)
              Text(
                AdminStrings.rewardsRedeemedAt(date(claim.redeemedAt)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (claim.redeemedBy.isNotEmpty)
              AdminUserLabel(
                uid: claim.redeemedBy,
                prefix: AdminStrings.redeemedByLabel,
                avatarSize: 18,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (active) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onRedeem,
                      icon: const Icon(Icons.check),
                      label: Text(AdminStrings.rewardsMarkRedeemed),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onCancel,
                    child: Text(AdminStrings.rewardsCancelClaim),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Partner shops (`partners`). Their accounts are assigned in Korisnici.
class _PartnersAdmin extends ConsumerWidget {
  const _PartnersAdmin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider).value ?? const [];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-partner-add',
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add_business_outlined),
        label: Text(AdminStrings.newPartner),
      ),
      body: _asyncList<Partner>(
        ref.watch(partnersProvider),
        empty: AdminStrings.noPartnersYet,
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final p in items)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(p.name),
                  subtitle: Text(
                    [
                      if (p.city.isNotEmpty) p.city,
                      if (p.address.isNotEmpty) p.address,
                      AdminStrings.partnerAccounts(
                        users.where((u) => u.partnerId == p.id).length,
                      ),
                    ].join(' · '),
                  ),
                  onTap: () => _edit(context, ref, p),
                  trailing: Switch(
                    value: p.isActive,
                    onChanged: (v) => _guard(
                      context,
                      () => ref
                          .read(partnersRepositoryProvider)
                          .setPartnerActive(p.id, v),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Partner? existing,
  ) async {
    final name = TextEditingController(text: existing?.name);
    final city = TextEditingController(text: existing?.city);
    final address = TextEditingController(text: existing?.address);
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          existing == null ? AdminStrings.newPartner : AdminStrings.editPartner,
        ),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _text(name, AdminStrings.partnerName, max: 60),
              _text(city, AdminStrings.partnerCity, max: 40, required: false),
              _text(
                address,
                AdminStrings.partnerAddress,
                max: 120,
                required: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AdminStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(AdminStrings.save),
          ),
        ],
      ),
    );
    final partner = Partner(
      id: existing?.id ?? '',
      name: name.text.trim(),
      city: city.text.trim(),
      address: address.text.trim(),
      isActive: existing?.isActive ?? true,
    );
    if (ok != true || !context.mounted) return;
    await _guard(
      context,
      () => ref.read(partnersRepositoryProvider).savePartner(partner),
    );
  }
}

/// How many coupons of an offer can still be claimed (any time, also while
/// the offer is active). Returns the new remaining count.
class _RemainingDialog extends StatefulWidget {
  const _RemainingDialog({required this.coupon});

  final Coupon coupon;

  @override
  State<_RemainingDialog> createState() => _RemainingDialogState();
}

class _RemainingDialogState extends State<_RemainingDialog> {
  static const _max = 100000;
  final _form = GlobalKey<FormState>();
  late final _value = TextEditingController(text: '${widget.coupon.remaining}');

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _add(int delta) {
    final current = int.tryParse(_value.text) ?? 0;
    final next = (current + delta).clamp(0, _max);
    setState(() => _value.text = '$next');
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coupon;
    return AlertDialog(
      title: Text(AdminStrings.rewardsRemainingTitle),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c.partnerName} · ${c.discountLabel}'),
            const SizedBox(height: 4),
            Text(
              AdminStrings.rewardsClaimedSoFar(c.claimedCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('coupon-remaining-field'),
              controller: _value,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: AdminStrings.rewardsRemainingField,
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null) return AdminStrings.rewardsNumber;
                if (n > _max) return AdminStrings.rewardsRange(_max);
                return null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in const [-10, -1, 1, 10, 50])
                  ActionChip(
                    label: Text(d > 0 ? '+$d' : '$d'),
                    onPressed: () => _add(d),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AdminStrings.rewardsRemainingHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AdminStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(int.parse(_value.text));
          },
          child: Text(AdminStrings.save),
        ),
      ],
    );
  }
}

/// Nagrade → Rođendanski poklon: `app_config/birthday` (enabled, couponId,
/// partnerName). Turning it on only makes the birthday greeting announce
/// the gift; claiming still follows the coupon (points price).
class _BirthdayRewardAdmin extends ConsumerStatefulWidget {
  const _BirthdayRewardAdmin();

  @override
  ConsumerState<_BirthdayRewardAdmin> createState() =>
      _BirthdayRewardAdminState();
}

class _BirthdayRewardAdminState extends ConsumerState<_BirthdayRewardAdmin> {
  final _partner = TextEditingController();
  BirthdayRewardConfig? _draft;
  var _saving = false;

  @override
  void dispose() {
    _partner.dispose();
    super.dispose();
  }

  void _start(BirthdayRewardConfig stored) {
    if (_draft != null) {
      return;
    }
    _draft = stored;
    _partner.text = stored.partnerName;
  }

  void _set({bool? enabled, String? couponId, String? partnerName}) {
    final d = _draft ?? BirthdayRewardConfig.disabled;
    setState(() {
      _draft = BirthdayRewardConfig(
        enabled: enabled ?? d.enabled,
        couponId: couponId ?? d.couponId,
        partnerName: partnerName ?? d.partnerName,
      );
    });
  }

  Future<void> _save() async {
    final d = _draft ?? BirthdayRewardConfig.disabled;
    if (d.enabled && d.couponId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminStrings.birthdayNeedsCoupon)),
      );
      return;
    }
    setState(() => _saving = true);
    await _guard(context, () async {
      await ref.read(adminRepositoryProvider).saveBirthdayReward(
        BirthdayRewardConfig(
          enabled: d.enabled,
          couponId: d.couponId,
          partnerName: _partner.text.trim(),
        ),
      );
      ref.invalidate(adminBirthdayRewardProvider);
      ref.invalidate(birthdayRewardConfigProvider);
    });
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stored = ref.watch(adminBirthdayRewardProvider);
    final coupons = ref.watch(_adminCouponsProvider).value ?? const <Coupon>[];
    return stored.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(AdminStrings.loadError)),
      data: (config) {
        _start(config);
        final d = _draft!;
        final known = coupons.any((c) => c.id == d.couponId);
        final preview = BirthdayRewardConfig(
          enabled: d.enabled,
          couponId: d.couponId,
          partnerName: _partner.text,
        );
        return ListView(
          key: const ValueKey('admin-birthday-reward'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(AdminStrings.birthdayIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const ValueKey('admin-birthday-enabled'),
              contentPadding: EdgeInsets.zero,
              title: Text(AdminStrings.birthdayEnabled),
              value: d.enabled,
              onChanged: (value) => _set(enabled: value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // Rebuilt when the coupon list arrives (initialValue is read once).
              key: ValueKey('admin-birthday-coupon-${coupons.length}'),
              initialValue: known ? d.couponId : '',
              isExpanded: true,
              decoration: InputDecoration(
                labelText: AdminStrings.birthdayCoupon,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(AdminStrings.birthdayNoCoupon),
                ),
                for (final c in coupons)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      [c.title, c.partnerName]
                          .where((s) => s.trim().isNotEmpty)
                          .join(' · '),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                final picked = coupons.where((c) => c.id == id).firstOrNull;
                if (picked != null && _partner.text.trim().isEmpty) {
                  _partner.text = picked.partnerName;
                }
                _set(
                  couponId: id ?? '',
                  enabled: (id ?? '').isEmpty ? false : null,
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('admin-birthday-partner'),
              controller: _partner,
              maxLength: 60,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: AdminStrings.birthdayPartner,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AdminStrings.birthdayPreview,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Container(
              key: const ValueKey('admin-birthday-preview'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ReminderStrings.birthdayGreetingTitle('Dzeki'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ReminderStrings.birthdayGreetingBody(
                      'Dzeki',
                      hasReward: preview.isActive,
                      rewardPartner: preview.partnerName,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AdminStrings.birthdayNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('admin-birthday-save'),
              onPressed: _saving ? null : _save,
              child: Text(AdminStrings.save),
            ),
          ],
        );
      },
    );
  }
}
