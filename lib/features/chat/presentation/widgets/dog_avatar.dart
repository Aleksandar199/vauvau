import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../domain/chat_conversation.dart';
import 'chat_ui.dart';

class DogAvatar extends StatelessWidget {
  const DogAvatar({
    super.key,
    required this.photoUrl,
    this.size = ChatUiTokens.avatarSize,
  });

  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: buildDogImage(
          photoUrl,
          seed: photoUrl,
          width: size,
          height: size,
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
