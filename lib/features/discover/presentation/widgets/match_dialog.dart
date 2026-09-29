import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../chat/presentation/chat_inbox.dart';
import '../../../chat/presentation/chat_screen.dart';
import '../../domain/discover_profile.dart';
import '../discover_controller.dart';
import '../discover_strings.dart';
import 'compatibility_card.dart';

Future<void> showMatchDialogIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required DiscoverProfile matched,
  required bool isMatch,
}) async {
  if (!isMatch || !context.mounted) {
    return;
  }
  final myDog = ref.read(discoverControllerProvider).myDog;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return MatchDialog(
        myDog: myDog,
        matched: matched,
        onSendMessage: () {
          Navigator.of(dialogContext).pop();
          final chatId =
              ref.read(chatInboxProvider.notifier).openFromMatch(matched);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChatScreen(conversationId: chatId),
            ),
          );
        },
        onKeepSearching: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}

class MatchDialog extends StatelessWidget {
  const MatchDialog({
    super.key,
    required this.myDog,
    required this.matched,
    required this.onSendMessage,
    required this.onKeepSearching,
  });

  final DiscoverProfile myDog;
  final DiscoverProfile matched;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSearching;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60F172A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.favorite, color: AppColors.primary, size: 48),
              const SizedBox(height: 12),
              Text(
                DiscoverStrings.newMatch,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${myDog.name} + ${matched.name}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(child: _MatchPhoto(profile: myDog)),
                    const SizedBox(width: 12),
                    Expanded(child: _MatchPhoto(profile: matched)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CompatibilityCard(other: matched, light: true),
              const Spacer(),
              FilledButton(
                onPressed: onSendMessage,
                child: const Text(DiscoverStrings.sendMessage),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                onPressed: onKeepSearching,
                child: const Text(DiscoverStrings.keepSearching),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchPhoto extends StatelessWidget {
  const _MatchPhoto({required this.profile});

  final DiscoverProfile profile;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildDogImage(profile.photoUrl, seed: profile.id),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ColoredBox(
                    color: const Color(0x990F172A),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        profile.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          FallbackIllustrationCaption(url: profile.photoUrl),
        ],
      ),
    );
  }
}
