import 'package:flutter/material.dart';

import '../support_content.dart';

class SupportGuideCard extends StatelessWidget {
  const SupportGuideCard({super.key, required this.guide});

  final SupportGuide guide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: guide.color.withValues(alpha: 0.28)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: guide.color.withValues(alpha: 0.16),
              child: Icon(guide.icon, color: guide.color, size: 20),
            ),
            title: Text(
              guide.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              for (final point in guide.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child:
                            Icon(Icons.circle, size: 6, color: guide.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
