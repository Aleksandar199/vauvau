import 'package:flutter/material.dart';

import 'support_content.dart';
import 'support_strings.dart';
import 'widgets/admin_feedback_form.dart';
import 'widgets/support_guide_card.dart';

class RulesAndSupportScreen extends StatelessWidget {
  const RulesAndSupportScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(SupportStrings.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: SupportStrings.rulesTab),
              Tab(text: SupportStrings.tipsTab),
              Tab(text: SupportStrings.contactTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GuideList(
              intro: SupportStrings.rulesIntro,
              guides: SupportContent.rules,
            ),
            _GuideList(
              intro: SupportStrings.tipsIntro,
              guides: SupportContent.tips,
            ),
            AdminFeedbackForm(),
          ],
        ),
      ),
    );
  }
}

class _GuideList extends StatelessWidget {
  const _GuideList({required this.intro, required this.guides});

  final String intro;
  final List<SupportGuide> guides;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(intro, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        for (final guide in guides) SupportGuideCard(guide: guide),
      ],
    );
  }
}
