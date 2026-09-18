import 'package:flutter/material.dart';

import 'chat_detail_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return ChatDetailScreen(conversationId: conversationId);
  }
}
