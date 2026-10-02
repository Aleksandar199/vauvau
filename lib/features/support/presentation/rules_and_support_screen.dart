import 'package:flutter/material.dart';

import 'rules_tab.dart';
import 'sos_tab.dart';
import 'support_strings.dart';
import 'tips_tab.dart';
import 'widgets/admin_feedback_form.dart';

class RulesAndSupportScreen extends StatelessWidget {
  const RulesAndSupportScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(SupportStrings.title),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'SOS'),
              Tab(text: SupportStrings.tipsTab),
              Tab(text: SupportStrings.rulesTab),
              Tab(text: SupportStrings.contactTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SosTab(),
            TipsTab(),
            RulesTab(),
            AdminFeedbackForm(),
          ],
        ),
      ),
    );
  }
}
