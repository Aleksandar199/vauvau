import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../chat/domain/story_reference.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../discover/domain/discover_profile.dart';
import '../../follows/data/local_follow_repository.dart';
import '../../follows/domain/follow_repository.dart';
import '../../follows/presentation/follow_controller.dart';
import '../../moderation/presentation/block_controller.dart';
import '../../notifications/data/social_notifications.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/firestore_story_repository.dart';
import '../data/local_story_repository.dart';
import '../domain/story.dart';
import '../domain/story_repository.dart';
import 'stories_strings.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreStoryRepository(FirebaseFirestore.instance);
  }
  final follows = ref.watch(followRepositoryProvider);
  final repo = LocalStoryRepository(
    isFollowing: (a, b) =>
        follows is LocalFollowRepository &&
        follows.edges.contains(FollowRepository.docId(a, b)),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// My active stories (live). Also removes my expired ones once per session.
final myStoriesProvider = StreamProvider<List<Story>>((ref) {
  final me = ref.watch(socialUserIdProvider);
  final repo = ref.watch(storyRepositoryProvider);
  if (me.isNotEmpty) {
    unawaited(repo.cleanupExpired(me));
  }
  return repo.watchMyStories(me);
});

/// Active stories of accounts I follow that I may see. Re-fetched when my
/// follow lists change and every few minutes while watched.
final followedStoriesProvider = FutureProvider<List<Story>>((ref) async {
  final me = ref.watch(socialUserIdProvider);
  final following = ref.watch(followingIdsProvider).value ?? const <String>{};
  final followers = ref.watch(followerIdsProvider).value ?? const <String>{};
  final repo = ref.watch(storyRepositoryProvider);
  final timer = Timer(const Duration(minutes: 5), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  if (me.isEmpty || following.isEmpty) {
    return const [];
  }
  return repo.fetchStoriesOf(
    me: me,
    relations: [
      for (final author in following)
        StoryRelation(
          authorUserId: author,
          iFollowAuthor: true,
          authorFollowsMe: followers.contains(author),
        ),
    ],
  );
});

/// Story ids I have watched (kept on this device until the story expires).
class SeenStoriesStore extends Notifier<Set<String>> {
  static const _key = 'stories.seen.v1';
  final Map<String, int> _expiry = {};

  @override
  Set<String> build() {
    unawaited(_load());
    return const {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in prefs.getStringList(_key) ?? const <String>[]) {
        final parts = entry.split('|');
        final expires = parts.length == 2 ? int.tryParse(parts[1]) : null;
        if (expires != null && expires > now) {
          _expiry[parts[0]] = expires;
        }
      }
      if (ref.mounted) {
        state = {...state, ..._expiry.keys};
      }
    } catch (error) {
      debugPrint('seen stories load: $error');
    }
  }

  void markSeen(Story story) {
    if (state.contains(story.id)) {
      return;
    }
    _expiry[story.id] = story.expiresAt.millisecondsSinceEpoch;
    state = {...state, story.id};
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      _expiry.removeWhere((_, expires) => expires <= now);
      await prefs.setStringList(_key, [
        for (final entry in _expiry.entries) '${entry.key}|${entry.value}',
      ]);
    } catch (error) {
      debugPrint('seen stories save: $error');
    }
  }
}

final seenStoriesStoreProvider =
    NotifierProvider<SeenStoriesStore, Set<String>>(SeenStoriesStore.new);

class StoryBarState {
  const StoryBarState({
    required this.mine,
    required this.groups,
    required this.isLoading,
    required this.followsAnyone,
  });

  /// My active stories (null group when I have none).
  final StoryAuthorGroup? mine;

  /// Accounts I follow, unseen first.
  final List<StoryAuthorGroup> groups;
  final bool isLoading;
  final bool followsAnyone;
}

final storyBarProvider = Provider<StoryBarState>((ref) {
  final me = ref.watch(socialUserIdProvider);
  final mine = ref.watch(myStoriesProvider);
  final followed = ref.watch(followedStoriesProvider);
  final following = ref.watch(followingIdsProvider);
  final seen = ref.watch(seenStoriesStoreProvider);
  final blocked = ref.watch(blockedUserIdsProvider);
  final groups = groupStoriesByAuthor(
    [...?mine.value, ...?followed.value],
    me: me,
    seen: seen,
    now: DateTime.now(),
    blocked: blocked,
  );
  final myGroup = groups.where((g) => g.authorUserId == me).firstOrNull;
  return StoryBarState(
    mine: myGroup,
    groups: [
      for (final group in groups)
        if (group.authorUserId != me) group,
    ],
    isLoading: (followed.isLoading && !followed.hasValue) ||
        (following.isLoading && !following.hasValue),
    followsAnyone: (following.value ?? const <String>{}).isNotEmpty,
  );
});

/// Writes behind the stories UI (publish, like, reply, delete, views).
class StoryActions {
  StoryActions(this._ref);

  final Ref _ref;
  final _random = math.Random();

  StoryRepository get _repo => _ref.read(storyRepositoryProvider);
  String get _me => _ref.read(socialUserIdProvider);

  Future<Story> publish({
    required StoryDraft draft,
    required Uint8List bytes,
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final user = _ref.read(authStateProvider).value;
    final profile = _ref.read(profileControllerProvider);
    final dog = profile.dogs.isEmpty ? null : profile.dog;
    final story = await _repo.publish(
      me: _me,
      authorName: _ref.read(socialUserNameProvider),
      authorPhotoUrl: user?.ownerAvatarUrl ?? '',
      draft: StoryDraft(
        audience: draft.audience,
        caption: draft.caption,
        dogId: dog?.id ?? draft.dogId,
        dogName: dog?.name ?? draft.dogName,
        dogPhotoUrl: (dog?.photoUrls.isNotEmpty ?? false)
            ? dog!.photoUrls.first
            : draft.dogPhotoUrl,
      ),
      bytes: bytes,
      mimeType: mimeType,
      onProgress: onProgress,
    );
    return story;
  }

  Future<void> delete(Story story) async {
    await _repo.delete(story);
  }

  void markViewed(Story story) {
    _ref.read(seenStoriesStoreProvider.notifier).markSeen(story);
    unawaited(_repo.markViewed(story, _me));
  }

  Future<bool> isLiked(Story story) => _repo.isLiked(story, _me);

  /// Likes or unlikes; the author gets one notification per user and story
  /// (deterministic id), however often the like is toggled or retried.
  Future<void> setLiked(Story story, {required bool liked}) async {
    final me = _me;
    if (_ref.read(blockedUserIdsProvider).contains(story.authorUserId)) {
      throw const StoryAccessException('Korisnik je blokiran.');
    }
    if (!liked) {
      await _repo.unlike(story, me);
      return;
    }
    final created = await _repo.like(story, me);
    if (created) {
      await _ref.read(socialNotificationWriterProvider).send(
            SocialNotification(
              id: 'storylike_${story.id}_$me',
              type: SocialNotificationType.storyLike,
              fromUserId: me,
              toUserId: story.authorUserId,
              title: StoriesStrings.storyLikeTitle,
              body: StoriesStrings.storyLikeBody(
                _ref.read(socialUserNameProvider),
              ),
              storyId: story.id,
            ),
          );
    }
  }

  /// A fresh id per reply attempt; pass the same one when retrying so the
  /// author never gets the notification twice.
  String newReplyNonce() =>
      '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 20)}';

  /// Sends [text] to the author through the existing Inbox (same room as
  /// "Pošalji poruku"), marked as a reply to [story].
  Future<String> reply(Story story, String text, {required String nonce}) async {
    final me = _me;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const StoryAccessException('Prazan odgovor.');
    }
    if (me.isEmpty || me == story.authorUserId) {
      throw const StoryAccessException('Ne možete odgovoriti na svoju priču.');
    }
    if (_ref.read(blockedUserIdsProvider).contains(story.authorUserId)) {
      throw const StoryAccessException('Korisnik je blokiran.');
    }
    final inbox = _ref.read(chatInboxProvider.notifier);
    final chatId = inbox.openFromMatch(
      DiscoverProfile(
        id: story.dogId,
        name: story.dogName.isEmpty ? story.authorName : story.dogName,
        ownerName: story.authorName,
        ownerId: story.authorUserId,
        breed: '',
        ageYears: 1,
        gender: '',
        size: '',
        location: '',
        bio: '',
        photoUrls: [
          if (story.dogPhotoUrl.isNotEmpty) story.dogPhotoUrl
          else if (story.authorPhotoUrl.isNotEmpty) story.authorPhotoUrl,
        ],
      ),
    );
    await inbox.sendMessage(
      chatId,
      trimmed,
      story: StoryReference(
        storyId: story.id,
        authorUserId: story.authorUserId,
        caption: story.caption,
      ),
    );
    await _ref.read(socialNotificationWriterProvider).send(
          SocialNotification(
            id: 'storyreply_${story.id}_${me}_$nonce',
            type: SocialNotificationType.storyReply,
            fromUserId: me,
            toUserId: story.authorUserId,
            title: StoriesStrings.storyReplyTitle,
            body: StoriesStrings.storyReplyBody(
              _ref.read(socialUserNameProvider),
              trimmed,
            ),
            storyId: story.id,
            conversationId: chatId,
          ),
        );
    return chatId;
  }

  Future<List<StoryViewer>> viewers(Story story) => _repo.fetchViewers(story);

  Future<Story?> fetch(String storyId) => _repo.fetchStory(storyId);

  void refreshFeed() => _ref.invalidate(followedStoriesProvider);
}

final storyActionsProvider = Provider<StoryActions>(StoryActions.new);

/// Media bytes per story (the request itself is checked by storage.rules).
/// No automatic retry: a denied / deleted story stays unavailable.
final storyMediaProvider = FutureProvider.autoDispose.family<Uint8List, Story>(
  (ref, story) => ref.read(storyRepositoryProvider).loadMedia(story),
  retry: (_, _) => null,
);

/// One story by id for chat context; null when gone / not visible to me.
final storyByIdProvider = FutureProvider.autoDispose.family<Story?, String>((
  ref,
  storyId,
) {
  return ref.read(storyRepositoryProvider).fetchStory(storyId);
});

/// Active stories of one owner that I may see (owner profile entry point;
/// works for public stories of people I do not follow too).
final ownerStoriesProvider = FutureProvider.autoDispose
    .family<List<Story>, String>((ref, ownerId) async {
      final me = ref.watch(socialUserIdProvider);
      if (me.isEmpty || ownerId.isEmpty) {
        return const [];
      }
      if (ownerId == me) {
        return ref.watch(myStoriesProvider).value ?? const [];
      }
      final following =
          ref.watch(followingIdsProvider).value ?? const <String>{};
      final followers =
          ref.watch(followerIdsProvider).value ?? const <String>{};
      final stories = await ref.read(storyRepositoryProvider).fetchStoriesOf(
            me: me,
            relations: [
              StoryRelation(
                authorUserId: ownerId,
                iFollowAuthor: following.contains(ownerId),
                authorFollowsMe: followers.contains(ownerId),
              ),
            ],
          );
      final now = DateTime.now();
      return [
        for (final story in stories)
          if (story.isActive(now)) story,
      ];
    });
