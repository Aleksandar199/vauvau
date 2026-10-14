import 'package:flutter/material.dart';

import '../admin_strings.dart';

Future<bool> confirmAdminDelete(
  BuildContext context, {
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(AdminStrings.confirmDeleteTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(AdminStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(AdminStrings.confirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
