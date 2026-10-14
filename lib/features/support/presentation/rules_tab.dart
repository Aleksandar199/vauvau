import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'rules_content.dart';
import 'support_strings.dart';
import 'tips_content.dart';
import 'widgets/tip_article_card.dart';

class RulesTab extends StatelessWidget {
  const RulesTab({super.key});

  static const int _writeAdminTabIndex = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.ink;
    final bodyColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    void onCta(TipCtaKind kind) {
      if (kind == TipCtaKind.writeAdmin) {
        DefaultTabController.maybeOf(context)?.animateTo(_writeAdminTabIndex);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          SupportStrings.rulesTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          SupportStrings.rulesIntro,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: bodyColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.place_outlined, size: 16, color: mutedColor),
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                SupportStrings.rulesLocalNote,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: mutedColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        _RulesBlock(
          label: SupportStrings.rulesCategoryDaily,
          accent: RulesContent.dailyAccent,
          rules: RulesContent.daily,
          onCta: onCta,
        ),
        SizedBox(height: 18),
        _RulesBlock(
          label: SupportStrings.rulesCategoryCommunity,
          accent: RulesContent.communityAccent,
          rules: RulesContent.community,
          onCta: onCta,
        ),
        SizedBox(height: 18),
        _RulesBlock(
          label: SupportStrings.rulesCategoryImportant,
          accent: RulesContent.importantAccent,
          rules: RulesContent.important,
          onCta: onCta,
        ),
        SizedBox(height: 22),
        _OutroCard(titleColor: titleColor, bodyColor: bodyColor),
        SizedBox(height: 12),
        Text(
          SupportStrings.rulesUpdateNote,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.4, color: mutedColor),
        ),
      ],
    );
  }
}

class _RulesBlock extends StatelessWidget {
  const _RulesBlock({
    required this.label,
    required this.accent,
    required this.rules,
    required this.onCta,
  });

  final String label;
  final Color accent;
  final List<TipArticle> rules;
  final void Function(TipCtaKind kind) onCta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final rule in rules) ...[
          TipArticleCard(
            article: rule,
            onCta: rule.cta == null ? null : () => onCta(rule.cta!),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OutroCard extends StatelessWidget {
  const _OutroCard({required this.titleColor, required this.bodyColor});

  final Color titleColor;
  final Color bodyColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.pets, color: AppColors.primary, size: 26),
          SizedBox(height: 8),
          Text(
            SupportStrings.rulesOutroTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            SupportStrings.rulesOutroBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: bodyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
