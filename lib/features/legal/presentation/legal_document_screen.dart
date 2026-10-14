import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/external_link_launcher.dart';
import '../domain/legal_urls.dart';
import 'legal_document_bodies.dart';
import 'legal_strings.dart';

enum LegalDocumentKind { privacy, terms }

Future<void> openLegalDocument(
  BuildContext context, {
  required LegalDocumentKind kind,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LegalDocumentScreen(kind: kind),
    ),
  );
}

class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivacy = kind == LegalDocumentKind.privacy;
    final title =
        isPrivacy ? LegalStrings.privacyPolicy : LegalStrings.termsOfService;
    final sections =
        isPrivacy ? PrivacyPolicyBody.sections() : TermsOfServiceBody.sections();
    final webUri =
        isPrivacy ? LegalUrls.privacyPolicy : LegalUrls.termsOfService;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: LegalStrings.openInBrowser,
            onPressed: () => _openWeb(context, ref, webUri),
            icon: const Icon(Icons.open_in_browser_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            LegalStrings.lastUpdated,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            Text(
              section.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            LegalStrings.contactUs,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _openWeb(context, ref, webUri),
            icon: const Icon(Icons.open_in_new),
            label: Text(LegalStrings.openInBrowser),
          ),
        ],
      ),
    );
  }

  Future<void> _openWeb(
    BuildContext context,
    WidgetRef ref,
    Uri uri,
  ) async {
    try {
      final opened = await ref.read(externalLinkLauncherProvider).open(uri);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LegalStrings.linkError)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LegalStrings.linkError)),
        );
      }
    }
  }
}
