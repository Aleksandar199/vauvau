import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/presentation/chat_detail_screen.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../discover/data/load_discover_profile.dart';
import '../../discover/data/mock_discover_profiles.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/discover_controller.dart';
import '../../home/presentation/home_tab.dart';
import '../domain/push_payload.dart';

/// Root navigator used for tap-through from FCM / local notifications.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> openPushDestination(Ref ref, PushPayload payload) async {
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) {
    return;
  }

  if (payload.kind == PushKind.walk) {
    ref.read(homeTabIndexProvider.notifier).showMap();
    return;
  }

  final conversationId = payload.conversationId?.trim() ?? '';
  if (conversationId.isNotEmpty) {
    ref.read(homeTabIndexProvider.notifier).showMessages();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(conversationId: conversationId),
      ),
    );
    return;
  }

  final profile = await _resolveProfile(ref, payload);
  if (!context.mounted) {
    return;
  }
  if (profile != null) {
    final chatId = ref.read(chatInboxProvider.notifier).openFromMatch(profile);
    ref.read(homeTabIndexProvider.notifier).showMessages();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(conversationId: chatId),
      ),
    );
    return;
  }

  ref.read(homeTabIndexProvider.notifier).showMessages();
}

Future<DiscoverProfile?> _resolveProfile(
  Ref ref,
  PushPayload payload,
) async {
  try {
    final loaded = await loadDiscoverProfile(
      dogId: payload.dogId,
      ownerId: payload.peerUserId,
    );
    if (loaded != null) {
      return loaded;
    }
  } catch (_) {}

  final catalog = ref.read(discoverControllerProvider).catalog;
  for (final dog in catalog) {
    if (payload.dogId != null &&
        payload.dogId!.isNotEmpty &&
        dog.id == payload.dogId) {
      return dog;
    }
    if (payload.peerUserId != null &&
        payload.peerUserId!.isNotEmpty &&
        dog.ownerId == payload.peerUserId) {
      return dog;
    }
  }
  for (final dog in mockDiscoverProfiles) {
    if (payload.dogId != null && dog.id == payload.dogId) {
      return dog;
    }
  }
  return null;
}
