import 'package:flutter/material.dart';

import '../../../discover/presentation/discover_image.dart';
import '../../domain/chat_conversation.dart';

class DogAvatar extends StatelessWidget {
  const DogAvatar({
    super.key,
    required this.photoUrl,
    this.size = 56,
  });

  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: photoUrl.isEmpty
            ? ColoredBox(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                child: const Icon(Icons.pets),
              )
            : Image(
                image: discoverImageOf(context, photoUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                    child: const Icon(Icons.pets),
                  );
                },
              ),
      ),
    );
  }
}

class ConversationTitle extends StatelessWidget {
  const ConversationTitle({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Text(conversation.title);
  }
}
