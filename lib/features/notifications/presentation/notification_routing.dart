import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../chat/presentation/chat_detail_screen.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../discover/data/load_discover_profile.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/discover_controller.dart';
import '../../discover/presentation/widgets/swipe_dog_card.dart';
import '../../events/presentation/events_controller.dart';
import '../../groups/presentation/group_chat_screen.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../home/presentation/home_tab.dart';
import '../domain/app_notification.dart';
import '../domain/push_payload.dart';
import 'push_navigation.dart';

Future<void> openAppNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification item,
) {
  return _open(
    context,
    ref,
    kind: item.kind,
    dogId: item.dogId,
    fromUserId: item.fromUserId,
    conversationId: item.conversationId,
    groupId: item.groupId,
    eventId: item.eventId,
  );
}

Future<void> openPushDestination(Ref ref, PushPayload payload) async {
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) {
    return;
  }
  await _open(
    context,
    ref,
    kind: switch (payload.kind) {
      PushKind.match => NotificationKind.match,
      PushKind.message => NotificationKind.chatMessage,
      PushKind.walk => NotificationKind.walkRequest,
      PushKind.group => NotificationKind.groupMessage,
      PushKind.event => NotificationKind.eventMessage,
    },
    dogId: payload.dogId,
    fromUserId: payload.peerUserId,
    conversationId: payload.conversationId,
    groupId: payload.groupId,
    eventId: payload.eventId,
  );
}

Future<void> _open(
  BuildContext context,
  dynamic ref, {
  required NotificationKind kind,
  String? dogId,
  String? fromUserId,
  String? conversationId,
  String? groupId,
  String? eventId,
}) async {
  T read<T>(dynamic provider) => ref.read(provider) as T;

  switch (kind) {
    case NotificationKind.walkRequest:
      read<HomeTabIndex>(homeTabIndexProvider.notifier).showMap();
      _popSheetIfNeeded(context);
      return;
    case NotificationKind.groupMessage:
      final id = groupId?.trim() ?? '';
      _popSheetIfNeeded(context);
      if (id.isEmpty) {
        read<HomeTabIndex>(homeTabIndexProvider.notifier).showMessages();
        return;
      }
      unawaited(
        read<GroupsController>(groupsControllerProvider.notifier).markRead(id),
      );
      await _pushRoute(context, GroupChatScreen(groupId: id));
      return;
    case NotificationKind.eventMessage:
      final id = eventId?.trim() ?? '';
      _popSheetIfNeeded(context);
      if (id.isEmpty) {
        read<HomeTabIndex>(homeTabIndexProvider.notifier).showMessages();
        return;
      }
      unawaited(
        read<EventsController>(eventsControllerProvider.notifier).markRead(id),
      );
      await _pushRoute(context, GroupChatScreen(eventId: id));
      return;
    case NotificationKind.like:
    case NotificationKind.superLike:
      final host = appNavigatorKey.currentContext ?? context;
      _popSheetIfNeeded(context);
      final profile = await _resolveProfile(
        ref,
        dogId: dogId,
        ownerId: fromUserId,
      );
      if (!host.mounted || profile == null) {
        read<HomeTabIndex>(homeTabIndexProvider.notifier).showDiscover();
        return;
      }
      await showModalBottomSheet<void>(
        context: host,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DogDetailSheet(profile: profile),
      );
      return;
    case NotificationKind.match:
    case NotificationKind.chatMessage:
      final chatId = await _resolveConversationId(
        ref,
        conversationId: conversationId,
        fromUserId: fromUserId,
        dogId: dogId,
      );
      final navContext = appNavigatorKey.currentContext ?? context;
      if (!navContext.mounted) {
        return;
      }
      _popSheetIfNeeded(navContext);
      read<HomeTabIndex>(homeTabIndexProvider.notifier).showMessages();
      if (chatId == null || chatId.isEmpty) {
        return;
      }
      await _pushRoute(navContext, ChatDetailScreen(conversationId: chatId));
      return;
  }
}

Future<String?> _resolveConversationId(
  dynamic ref, {
  String? conversationId,
  String? fromUserId,
  String? dogId,
}) async {
  final explicit = conversationId?.trim() ?? '';
  if (explicit.isNotEmpty) {
    return explicit;
  }

  final me =
      (ref.read(authStateProvider) as AsyncValue<dynamic>).asData?.value?.uid
          as String? ??
      '';
  final peer = fromUserId?.trim() ?? '';
  if (me.isNotEmpty && peer.isNotEmpty) {
    final ids = [me, peer]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  final profile = await _resolveProfile(ref, dogId: dogId, ownerId: peer);
  if (profile == null || profile.ownerId.isEmpty) {
    return null;
  }
  return (ref.read(chatInboxProvider.notifier) as ChatInboxController)
      .openFromMatch(profile);
}

Future<DiscoverProfile?> _resolveProfile(
  dynamic ref, {
  String? dogId,
  String? ownerId,
}) async {
  try {
    final loaded = await loadDiscoverProfile(
      dogId: dogId,
      ownerId: ownerId,
    );
    if (loaded != null) {
      return loaded;
    }
  } catch (_) {}

  final catalog =
      (ref.read(discoverControllerProvider) as DiscoverState).catalog;
  for (final dog in catalog) {
    if (dogId != null && dogId.isNotEmpty && dog.id == dogId) {
      return dog;
    }
    if (ownerId != null && ownerId.isNotEmpty && dog.ownerId == ownerId) {
      return dog;
    }
  }
  return null;
}

void _popSheetIfNeeded(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}

Future<void> _pushRoute(BuildContext context, Widget page) async {
  final navContext = appNavigatorKey.currentContext ?? context;
  if (!navContext.mounted) {
    return;
  }
  await Navigator.of(navContext).push(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}
