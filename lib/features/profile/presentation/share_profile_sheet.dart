import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/external_link_launcher.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../app_update/domain/app_update.dart';
import '../domain/user_profile.dart';
import 'profile_strings.dart';

/// Text for "Podeli profil": who I am, my dog and where to get the app.
/// There are no profile web links yet, so the Play Store link is shared.
String profileShareText(UserProfile profile) {
  final dogs = [
    for (final dog in profile.dogs)
      if (dog.name.trim().isNotEmpty) dog.name.trim(),
  ];
  return ProfileStrings.shareProfileMessage(
    name: profile.ownerName.trim(),
    dogs: dogs,
    link: kPlayStoreWebUrl,
  );
}

String inviteFriendsText() =>
    ProfileStrings.inviteMessage(link: kPlayStoreWebUrl);

/// Share [text] without a native share plugin: copy, or hand it to
/// WhatsApp / Viber / SMS / email through their links.
Future<void> showShareTextSheet(
  BuildContext context, {
  required String title,
  required String text,
}) {
  return showAppBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ShareTextSheet(title: title, text: text),
  );
}

class ShareTextSheet extends ConsumerWidget {
  const ShareTextSheet({super.key, required this.title, required this.text});

  final String title;
  final String text;

  Future<void> _open(BuildContext context, WidgetRef ref, Uri uri) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    var opened = false;
    try {
      opened = await ref.read(externalLinkLauncherProvider).open(uri);
    } catch (_) {
      opened = false;
    }
    if (opened) {
      navigator.pop();
    } else {
      messenger?.showSnackBar(
        SnackBar(content: Text(ProfileStrings.shareAppMissing)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final encoded = Uri.encodeComponent(text);
    final options = <({Key key, IconData icon, String label, VoidCallback onTap})>[
      (
        key: const ValueKey('share-copy'),
        icon: Icons.copy_rounded,
        label: ProfileStrings.shareCopy,
        onTap: () async {
          final messenger = ScaffoldMessenger.maybeOf(context);
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          messenger?.showSnackBar(
            SnackBar(content: Text(ProfileStrings.shareCopied)),
          );
        },
      ),
      (
        key: const ValueKey('share-whatsapp'),
        icon: Icons.chat_outlined,
        label: 'WhatsApp',
        onTap: () =>
            _open(context, ref, Uri.parse('https://wa.me/?text=$encoded')),
      ),
      (
        key: const ValueKey('share-viber'),
        icon: Icons.phone_in_talk_outlined,
        label: 'Viber',
        onTap: () =>
            _open(context, ref, Uri.parse('viber://forward?text=$encoded')),
      ),
      (
        key: const ValueKey('share-sms'),
        icon: Icons.sms_outlined,
        label: ProfileStrings.shareSms,
        onTap: () => _open(context, ref, Uri.parse('sms:?body=$encoded')),
      ),
      (
        key: const ValueKey('share-email'),
        icon: Icons.mail_outline_rounded,
        label: ProfileStrings.shareEmail,
        onTap: () => _open(
          context,
          ref,
          Uri.parse(
            'mailto:?subject=${Uri.encodeComponent(title)}&body=$encoded',
          ),
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('share-preview'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ActionChip(
                  key: option.key,
                  avatar: Icon(option.icon, size: 18),
                  label: Text(option.label),
                  onPressed: option.onTap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
