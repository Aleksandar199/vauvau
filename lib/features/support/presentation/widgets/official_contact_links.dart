import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/external_link_launcher.dart';
import '../../domain/official_contacts.dart';
import '../support_strings.dart';

class OfficialContactLinks extends ConsumerWidget {
  const OfficialContactLinks({
    super.key,
    this.compact = false,
    this.dark = false,
  });

  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final link in OfficialContacts.all)
            IconButton(
              tooltip: '${link.title} ${link.subtitle}',
              visualDensity: VisualDensity.compact,
              color: dark ? Colors.white : null,
              onPressed: () => openOfficialContact(context, ref, link),
              icon: Icon(_iconFor(link.id)),
            ),
        ],
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SupportStrings.followUs,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final link in OfficialContacts.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ContactCard(
              link: link,
              onTap: () => openOfficialContact(context, ref, link),
            ),
          ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.link, required this.onTap});

  final OfficialContactLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(link.id);
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(_iconFor(link.id), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(link.subtitle),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openOfficialContact(
  BuildContext context,
  WidgetRef ref,
  OfficialContactLink link,
) async {
  try {
    final opened = await ref.read(externalLinkLauncherProvider).open(link.uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupportStrings.linkError)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupportStrings.linkError)),
      );
    }
  }
}

IconData _iconFor(String id) {
  return switch (id) {
    'email' => Icons.email_outlined,
    'instagram' => Icons.camera_alt_outlined,
    _ => Icons.facebook,
  };
}

Color _colorFor(String id) {
  return switch (id) {
    'email' => const Color(0xFFEA580C),
    'instagram' => const Color(0xFFDB2777),
    _ => const Color(0xFF2563EB),
  };
}
