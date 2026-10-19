import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../partners/domain/partner.dart';
import '../../domain/admin_models.dart';
import '../admin_controller.dart';
import '../admin_strings.dart';

void _snack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Asks for a reason and suspends; returns true when done.
Future<bool> suspendUserFlow(
  BuildContext context,
  WidgetRef ref,
  String uid,
) async {
  final reason = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(AdminStrings.suspendTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AdminStrings.suspendBody),
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            maxLength: 200,
            decoration: InputDecoration(labelText: AdminStrings.suspendReason),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(AdminStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB91C1C),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(AdminStrings.suspendConfirm),
        ),
      ],
    ),
  );
  // Not disposed here: the dialog still uses it during its exit animation.
  final text = reason.text;
  if (ok != true || !context.mounted) return false;
  try {
    await ref
        .read(adminUserActionsProvider)
        .setSuspended(uid, suspended: true, reason: text);
    if (context.mounted) _snack(context, AdminStrings.suspended);
    return true;
  } catch (error) {
    debugPrint('admin suspend failed: $error');
    if (context.mounted) _snack(context, AdminStrings.actionFailed);
    return false;
  }
}

Future<void> unsuspendUserFlow(
  BuildContext context,
  WidgetRef ref,
  String uid,
) async {
  try {
    await ref
        .read(adminUserActionsProvider)
        .setSuspended(uid, suspended: false);
    if (context.mounted) _snack(context, AdminStrings.unsuspended);
  } catch (error) {
    debugPrint('admin unsuspend failed: $error');
    if (context.mounted) _snack(context, AdminStrings.actionFailed);
  }
}

/// Picks a partner and gives [uid] the partner role.
Future<void> assignPartnerFlow(
  BuildContext context,
  WidgetRef ref,
  String uid,
  List<Partner> partners,
) async {
  if (partners.isEmpty) {
    _snack(context, AdminStrings.noPartners);
    return;
  }
  final chosen = await showDialog<Partner>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(AdminStrings.choosePartner),
      children: [
        for (final p in partners)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(p),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined),
              title: Text(p.name),
              subtitle: Text(
                [p.city, if (!p.isActive) AdminStrings.partnerInactive]
                    .where((v) => v.isNotEmpty)
                    .join(' · '),
              ),
            ),
          ),
      ],
    ),
  );
  if (chosen == null || !context.mounted) return;
  await _setRole(context, ref, uid, AdminRoles.partner, partnerId: chosen.id);
}

Future<void> removePartnerFlow(
  BuildContext context,
  WidgetRef ref,
  String uid,
) {
  return _setRole(context, ref, uid, AdminRoles.user);
}

Future<void> _setRole(
  BuildContext context,
  WidgetRef ref,
  String uid,
  String role, {
  String partnerId = '',
}) async {
  try {
    await ref
        .read(adminUserActionsProvider)
        .setRole(uid, role, partnerId: partnerId);
    if (context.mounted) _snack(context, AdminStrings.roleSaved);
  } catch (error) {
    debugPrint('admin set role failed: $error');
    if (context.mounted) _snack(context, AdminStrings.actionFailed);
  }
}
