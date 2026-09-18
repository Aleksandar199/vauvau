import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/discover_profile.dart';
import '../discover_strings.dart';
import 'swipe_dog_card.dart';

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
                    Expanded(child: SwipeDogCard(profile: myDog, compact: true)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwipeDogCard(profile: matched, compact: true),
                    ),
                  ],
                ),
              ),
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
