import 'package:flutter/material.dart';

import 'support_strings.dart';
import 'widgets/official_contact_links.dart';

Future<void> showAboutAppDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(SupportStrings.aboutTitle),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(SupportStrings.aboutBody),
              SizedBox(height: 8),
              Text(
                SupportStrings.appVersion,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16),
              OfficialContactLinks(),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(SupportStrings.ok),
          ),
        ],
      );
    },
  );
}
