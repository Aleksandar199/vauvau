import 'package:flutter/material.dart';

import '../../legal/presentation/legal_document_screen.dart';
import '../../legal/presentation/legal_strings.dart';
import 'support_strings.dart';
import 'widgets/official_contact_links.dart';

Future<void> showAboutAppDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(SupportStrings.aboutTitle),
        content: SingleChildScrollView(
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
              SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  openLegalDocument(
                    context,
                    kind: LegalDocumentKind.privacy,
                  );
                },
                child: Text(LegalStrings.privacyPolicy),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  openLegalDocument(
                    context,
                    kind: LegalDocumentKind.terms,
                  );
                },
                child: Text(LegalStrings.termsOfService),
              ),
              SizedBox(height: 8),
              OfficialContactLinks(),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(SupportStrings.ok),
          ),
        ],
      );
    },
  );
}
