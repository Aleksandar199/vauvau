import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../rewards/domain/reward_rules.dart';
import '../../../rewards/domain/rewards_models.dart';
import '../../../rewards/domain/rewards_repository.dart';
import '../../../rewards/presentation/rewards_controller.dart';
import '../../../rewards/presentation/rewards_strings.dart';
import '../admin_strings.dart';

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
      length: 4,
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
              Tab(text: AdminStrings.rewardsLedger),
              Tab(text: AdminStrings.rewardsClaims),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ChallengesAdmin(),
                _CouponsAdmin(),
                _LedgerAdmin(),
                _ClaimsAdmin(),
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
              child: ListTile(
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
                    if (v && RewardRules.isPlaceholderPartner(c.partnerName)) {
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
            ),
        ],
      ),
    );
  }

  Future<void> _editCoupon(
    BuildContext context,
    WidgetRef ref,
    Coupon? existing,
  ) async {
    final result = await showDialog<Coupon>(
      context: context,
      builder: (_) => _CouponDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;
    await _guard(
      context,
      () => ref.read(rewardsRepositoryProvider).saveCoupon(result),
    );
  }
}

class _CouponDialog extends StatefulWidget {
  const _CouponDialog({this.existing});

  final Coupon? existing;

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
            subtitle: Text(
              '${e.userId} · ${e.id}'
              '${e.createdAt == null ? '' : ' · ${e.createdAt!.toLocal()}'.split('.').first}',
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

class _ClaimsAdmin extends ConsumerStatefulWidget {
  const _ClaimsAdmin();

  @override
  ConsumerState<_ClaimsAdmin> createState() => _ClaimsAdminState();
}

class _ClaimsAdminState extends ConsumerState<_ClaimsAdmin> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(rewardsRepositoryProvider);
    final now = DateTime.now();
    final query = _search.text.trim().toUpperCase();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: AdminStrings.rewardsSearchCode,
            ),
          ),
        ),
        Expanded(
          child: _asyncList<CouponClaim>(
            ref.watch(_adminClaimsProvider),
            empty: AdminStrings.rewardsNoClaims,
            data: (all) {
              final items = [
                for (final c in all)
                  if (query.isEmpty || c.code.contains(query)) c,
              ];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final c in items)
                    Card(
                      child: ListTile(
                        title: Text('${c.code} · ${c.partnerName}'),
                        subtitle: Text(
                          '${c.discountLabel} · ${c.userId} · '
                          '${RewardsStrings.claimStatus(c.effectiveStatus(now))}',
                        ),
                        trailing: c.status == ClaimStatus.claimed
                            ? PopupMenuButton<ClaimStatus>(
                                onSelected: (status) => _guard(
                                  context,
                                  () => repo.adminSetClaimStatus(c.id, status),
                                ),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: ClaimStatus.redeemed,
                                    child: Text(
                                      RewardsStrings.claimStatus(
                                        ClaimStatus.redeemed,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: ClaimStatus.cancelled,
                                    child: Text(
                                      RewardsStrings.claimStatus(
                                        ClaimStatus.cancelled,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
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
