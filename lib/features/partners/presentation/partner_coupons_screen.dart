import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../rewards/domain/rewards_models.dart';
import '../../rewards/presentation/rewards_controller.dart';
import '../domain/partner_coupon_check.dart';
import 'partner_providers.dart';
import 'partner_strings.dart';

final _partnerOffersProvider = StreamProvider.autoDispose<List<Coupon>>((ref) {
  final id = ref.watch(partnerIdProvider);
  return ref
      .watch(rewardsRepositoryProvider)
      .watchCoupons(activeOnly: false)
      .map((all) => [for (final c in all) if (c.partnerId == id) c]);
});

String _date(DateTime? d) {
  if (d == null) return '–';
  final l = d.toLocal();
  return '${l.day}.${l.month}.${l.year}. '
      '${l.hour}:${l.minute.toString().padLeft(2, '0')}';
}

/// Partner shop: type the customer's code, see whether it is valid for this
/// shop and mark it used. Nothing else of the admin panel is reachable.
class PartnerCouponsScreen extends ConsumerStatefulWidget {
  const PartnerCouponsScreen({super.key});

  @override
  ConsumerState<PartnerCouponsScreen> createState() =>
      _PartnerCouponsScreenState();
}

class _PartnerCouponsScreenState extends ConsumerState<PartnerCouponsScreen> {
  final _code = TextEditingController();
  PartnerCheckResult? _result;
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final partnerId = ref.read(partnerIdProvider);
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await checkPartnerCoupon(
        repository: ref.read(rewardsRepositoryProvider),
        partnerId: partnerId,
        input: _code.text,
        now: ref.read(rewardsClockProvider)(),
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      debugPrint('partner coupon check failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PartnerStrings.checkFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    _code.text = text;
    await _check();
  }

  Future<void> _redeem(CouponClaim claim) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(claim.code),
        content: Text(PartnerStrings.redeemConfirm(claim.code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(PartnerStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(PartnerStrings.redeem),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(rewardsRepositoryProvider).partnerRedeem(
            claim.id,
            byUid: uid,
            now: ref.read(rewardsClockProvider)(),
          );
      messenger.showSnackBar(SnackBar(content: Text(PartnerStrings.redeemed)));
      await _check();
    } catch (error) {
      debugPrint('partner redeem failed: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(PartnerStrings.redeemFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isPartnerProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(PartnerStrings.title)),
        body: Center(child: Text(PartnerStrings.denied)),
      );
    }
    final partner = ref.watch(currentPartnerProvider).value;
    final active = partner?.isActive ?? true;
    final theme = Theme.of(context);
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          partner == null || partner.name.isEmpty
              ? PartnerStrings.title
              : '${PartnerStrings.title} · ${partner.name}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!active)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  PartnerStrings.inactivePartner,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          TextField(
            key: const ValueKey('partner-code-field'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            onSubmitted: (_) => _check(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              labelText: PartnerStrings.codeLabel,
              hintText: PartnerStrings.codeHint,
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              suffixIcon: IconButton(
                tooltip: PartnerStrings.paste,
                onPressed: _busy ? null : _paste,
                icon: const Icon(Icons.content_paste),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(PartnerStrings.scanTodo, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _check,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(PartnerStrings.check),
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(
              result: result,
              canRedeem: active && !_busy && result.canRedeem,
              onRedeem: () => _redeem(result.claim!),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            PartnerStrings.offers,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ..._offers(context),
          const SizedBox(height: 24),
          Text(
            PartnerStrings.recent,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ..._recent(context),
        ],
      ),
    );
  }

  List<Widget> _offers(BuildContext context) {
    final offers = ref.watch(_partnerOffersProvider).value ?? const <Coupon>[];
    if (offers.isEmpty) return [Text(PartnerStrings.noOffers)];
    return [
      for (final c in offers)
        Card(
          child: ListTile(
            dense: true,
            title: Text(
              c.title.isEmpty ? c.discountLabel : '${c.discountLabel} · ${c.title}',
            ),
            subtitle: Text(
              '${c.claimedCount}/${c.maxQuantity} · '
              '${PartnerStrings.validUntil(_date(c.expiresAt))}',
            ),
          ),
        ),
    ];
  }

  List<Widget> _recent(BuildContext context) {
    final claims =
        ref.watch(partnerClaimsProvider).value ?? const <CouponClaim>[];
    if (claims.isEmpty) return [Text(PartnerStrings.noRecent)];
    final now = ref.read(rewardsClockProvider)();
    return [
      for (final c in claims)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            c.code,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          subtitle: Text(
            c.redeemedAt != null
                ? PartnerStrings.redeemedAt(_date(c.redeemedAt))
                : '${c.discountLabel} · '
                    '${PartnerStrings.validUntil(_date(c.expiresAt))}',
          ),
          trailing: Text(PartnerStrings.status(c.effectiveStatus(now))),
          onTap: () {
            _code.text = c.code;
            _check();
          },
        ),
    ];
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.canRedeem,
    required this.onRedeem,
  });

  final PartnerCheckResult result;
  final bool canRedeem;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final valid = result.status == PartnerCheckStatus.valid;
    final color = valid ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final claim = result.claim;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  valid ? Icons.check_circle : Icons.cancel,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PartnerStrings.result(result.status),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (claim != null) ...[
              const SizedBox(height: 8),
              Text(
                claim.code,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                claim.title.isEmpty
                    ? claim.discountLabel
                    : '${claim.discountLabel} · ${claim.title}',
              ),
              Text(PartnerStrings.validUntil(_date(claim.expiresAt))),
              if (claim.redeemedAt != null)
                Text(PartnerStrings.redeemedAt(_date(claim.redeemedAt))),
            ],
            if (valid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canRedeem ? onRedeem : null,
                  icon: const Icon(Icons.check),
                  label: Text(PartnerStrings.redeem),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
