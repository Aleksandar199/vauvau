import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/presentation/home_tab.dart';
import 'support_strings.dart';
import 'tips_content.dart';
import 'widgets/tip_article_card.dart';

class TipsTab extends ConsumerWidget {
  const TipsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.ink;
    final bodyColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          SupportStrings.tipsTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          SupportStrings.tipsIntro,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: bodyColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        Text(
          SupportStrings.tipsDisclaimer,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 16),
        _QuickCheckCard(
          onFindVet: () => _openSosTab(context),
        ),
        SizedBox(height: 20),
        _CategoryBlock(
          label: SupportStrings.tipsCategoryUrgent,
          accent: TipsContent.urgentAccent,
          articles: TipsContent.byCategory(TipCategory.urgent),
          onCta: (kind) => _handleCta(context, ref, kind),
        ),
        SizedBox(height: 18),
        _CategoryBlock(
          label: SupportStrings.tipsCategoryPrevention,
          accent: TipsContent.preventionAccent,
          articles: TipsContent.byCategory(TipCategory.prevention),
          onCta: (kind) => _handleCta(context, ref, kind),
        ),
        SizedBox(height: 18),
        _CategoryBlock(
          label: SupportStrings.tipsCategoryDaily,
          accent: TipsContent.dailyAccent,
          articles: TipsContent.byCategory(TipCategory.daily),
          onCta: (kind) => _handleCta(context, ref, kind),
        ),
        SizedBox(height: 20),
        Text(
          SupportStrings.tipsSourcesNote,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  void _openSosTab(BuildContext context) {
    final controller = DefaultTabController.maybeOf(context);
    controller?.animateTo(0);
  }

  void _handleCta(BuildContext context, WidgetRef ref, TipCtaKind kind) {
    switch (kind) {
      case TipCtaKind.sosVets:
        _openSosTab(context);
      case TipCtaKind.findWalk:
        Navigator.of(context).pop();
        ref.read(homeTabIndexProvider.notifier).showDiscover();
      case TipCtaKind.dogProfile:
        Navigator.of(context).pop();
        ref.read(homeTabIndexProvider.notifier).showProfile();
      case TipCtaKind.writeAdmin:
        DefaultTabController.maybeOf(context)?.animateTo(3);
    }
  }
}

class _QuickCheckCard extends StatelessWidget {
  const _QuickCheckCard({required this.onFindVet});

  final VoidCallback onFindVet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SupportStrings.tipsQuickCheckTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            SupportStrings.tipsQuickCheckBody,
            style: TextStyle(
              color: Color(0xFFFEE2E2),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7F1D1D),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onFindVet,
              child: Text(
                SupportStrings.tipsFindVetCta,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.label,
    required this.accent,
    required this.articles,
    required this.onCta,
  });

  final String label;
  final Color accent;
  final List<TipArticle> articles;
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
        for (final article in articles) ...[
          TipArticleCard(
            article: article,
            onCta: article.cta == null ? null : () => onCta(article.cta!),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
