import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import 'legal_document_screen.dart';
import 'legal_strings.dart';

/// Compact bilingual consent line with tappable Privacy / Terms links.
class LegalConsentText extends StatefulWidget {
  const LegalConsentText({super.key});

  @override
  State<LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<LegalConsentText> {
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer();
    _termsTap = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _privacyTap.onTap = () => openLegalDocument(
          context,
          kind: LegalDocumentKind.privacy,
        );
    _termsTap.onTap = () => openLegalDocument(
          context,
          kind: LegalDocumentKind.terms,
        );

    final base = Theme.of(context).textTheme.bodySmall?.copyWith(
          height: 1.35,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.75),
        );
    final linkStyle = base?.copyWith(
      color: AppColors.primaryDeep,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primaryDeep,
    );

    final prefix = L10n.tr(
      'Kreiranjem naloga prihvatate ',
      'By creating an account you accept the ',
    );
    final joiner = L10n.tr(' i ', ' and ');

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: LegalStrings.privacyPolicy,
            style: linkStyle,
            recognizer: _privacyTap,
          ),
          TextSpan(text: joiner),
          TextSpan(
            text: LegalStrings.termsOfService,
            style: linkStyle,
            recognizer: _termsTap,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
