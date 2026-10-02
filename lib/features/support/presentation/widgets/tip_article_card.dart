import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../tips_content.dart';

class TipArticleCard extends StatefulWidget {
  const TipArticleCard({
    super.key,
    required this.article,
    this.onCta,
  });

  final TipArticle article;
  final VoidCallback? onCta;

  @override
  State<TipArticleCard> createState() => _TipArticleCardState();
}

class _TipArticleCardState extends State<TipArticleCard> {
  late var _expanded = widget.article.initiallyExpanded;
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = isDark ? const Color(0xFFE2E8F0) : AppColors.ink;
    final mutedColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: article.accent.withValues(alpha: 0.32)),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: article.initiallyExpanded,
            onExpansionChanged: (value) => setState(() => _expanded = value),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: article.accent.withValues(alpha: 0.16),
              child: Icon(article.icon, color: article.accent, size: 22),
            ),
            title: Text(
              article.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: bodyColor,
                height: 1.25,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                article.summary,
                style: TextStyle(
                  fontSize: 13,
                  color: mutedColor,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: article.accent,
            ),
            children: [
              for (final section in article.sections) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    section.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: article.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (section.isChecklist)
                  for (var i = 0; i < section.bullets.length; i++)
                    _ChecklistRow(
                      label: section.bullets[i],
                      checked: _checked.contains(i),
                      accent: article.accent,
                      textColor: bodyColor,
                      onToggle: () {
                        setState(() {
                          if (_checked.contains(i)) {
                            _checked.remove(i);
                          } else {
                            _checked.add(i);
                          }
                        });
                      },
                    )
                else if (section.steps.isNotEmpty)
                  for (var i = 0; i < section.steps.length; i++)
                    _StepRow(
                      index: i + 1,
                      text: section.steps[i],
                      accent: article.accent,
                      textColor: bodyColor,
                    )
                else
                  for (final bullet in section.bullets)
                    _BulletRow(
                      text: bullet,
                      accent: article.accent,
                      textColor: bodyColor,
                    ),
                if (section.warning != null) ...[
                  const SizedBox(height: 8),
                  _WarningBox(
                    text: section.warning!,
                    accent: article.accent,
                  ),
                ],
                const SizedBox(height: 12),
              ],
              if (article.footerNote != null) ...[
                _WarningBox(
                  text: article.footerNote!,
                  accent: article.accent,
                ),
                const SizedBox(height: 12),
              ],
              if (article.cta != null &&
                  article.ctaLabel != null &&
                  widget.onCta != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: article.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.onCta,
                    child: Text(
                      article.ctaLabel!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.text,
    required this.accent,
    required this.textColor,
  });

  final String text;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
    required this.accent,
    required this.textColor,
  });

  final int index;
  final String text;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.checked,
    required this.accent,
    required this.textColor,
    required this.onToggle,
  });

  final String label;
  final bool checked;
  final Color accent;
  final Color textColor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              color: accent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high_rounded, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: accent.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
