import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/media/picked_video.dart';
import '../../../core/media/video_limits.dart';
import '../../../core/media/video_strings.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../moderation/presentation/block_controller.dart';
import '../data/firestore_moments_repository.dart';
import '../data/local_moments_repository.dart';
import '../domain/moment_model.dart';
import '../domain/moments_repository.dart';
import 'moments_strings.dart';

/// Every moment document (posts and legacy), newest first, live first page
/// plus [loadMore]. Admin moderation reads this; the community feed is
/// [momentFeedProvider].
class MomentsController extends Notifier<AsyncValue<List<MomentModel>>> {
  static const int pageSize = 15;

  var _hasMore = true;
  var _loadingMore = false;
  List<MomentModel> _older = const [];
  Object? _cursor;
  List<MomentModel>? _live;
  List<MomentModel>? _cached;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  @override
  AsyncValue<List<MomentModel>> build() {
    // The local repository (no Firebase) needs no auth token.
    final authReady = !isFirebaseReady ||
        (ref.watch(firestoreAuthReadyProvider).asData?.value ?? false);
    if (!authReady) {
      return _cached != null
          ? AsyncValue.data(_cached!)
          : const AsyncValue.data([]);
    }
    final repo = ref.watch(momentsRepositoryProvider);
    final sub = repo.watchMoments(limit: pageSize).listen(
      (moments) {
        _live = moments;
        if (_older.isEmpty) {
          _hasMore = moments.length >= pageSize;
        }
        final merged = _merged();
        _cached = merged;
        state = AsyncValue.data(merged);
      },
      onError: (Object error, StackTrace stack) {
        if (FirestoreAuthGuard.isPermissionDenied(error)) {
          FirestoreAuthGuard.logPermissionDenied(
            error,
            stack,
            label: 'moments.feed',
          );
          _live = const [];
          _cached = const [];
          state = const AsyncValue.data([]);
          return;
        }
        debugPrint('Moments stream: $error');
        if (_cached == null) {
          state = AsyncValue.error(error, stack);
        }
      },
    );
    ref.onDispose(sub.cancel);
    return _cached != null
        ? AsyncValue.data(_cached!)
        : const AsyncValue.loading();
  }

  List<MomentModel> _merged() {
    final live = _live ?? const <MomentModel>[];
    if (_older.isEmpty) {
      return live;
    }
    final seen = {for (final moment in live) moment.id};
    return [
      ...live,
      for (final moment in _older)
        if (!seen.contains(moment.id)) moment,
    ];
  }

  void reload() {
    _older = const [];
    _cursor = null;
    _hasMore = true;
    _live = null;
    _cached = null;
    ref.invalidateSelf();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) {
      return;
    }
    final shown = state.asData?.value;
    if (shown == null) {
      return;
    }
    _loadingMore = true;
    // Trigger listeners (footer spinner) without clearing the list.
    state = AsyncValue.data(shown);
    try {
      final page = await ref.read(momentsRepositoryProvider).fetchMomentsPage(
            cursor: _cursor,
            limit: pageSize,
          );
      _older = [..._older, ...page.items];
      _cursor = page.nextCursor;
      _hasMore = page.hasMore && page.items.isNotEmpty;
      final merged = _merged();
      _cached = merged;
      state = AsyncValue.data(merged);
    } catch (error, stack) {
      debugPrint('Moments loadMore failed: $error');
      debugPrint('$stack');
    } finally {
      _loadingMore = false;
      final value = _cached ?? state.asData?.value;
      if (value != null) {
        state = AsyncValue.data(value);
      }
    }
  }

  Future<void> toggleLike(String momentId) {
    return ref.read(momentsRepositoryProvider).toggleLike(momentId);
  }

  Future<void> toggleCommentLike(String momentId, String commentId) {
    return ref
        .read(momentsRepositoryProvider)
        .toggleCommentLike(momentId, commentId);
  }

  /// Admin / author delete; the feeds drop the post right away.
  Future<void> delete(String momentId) async {
    await ref.read(momentsRepositoryProvider).deleteMoment(momentId);
    ref.read(momentPatchesProvider.notifier).markDeleted(momentId);
  }
}

/// Falls back to the live FirebaseAuth user because the auth stream can still
/// be loading while the create sheet is open.
String _currentUserId(Ref ref, String fallback) {
  final uid = (ref.read(authStateProvider).asData?.value?.uid ?? '').trim();
  if (uid.isNotEmpty) {
    return uid;
  }
  if (isFirebaseReady) {
    return (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
  }
  return fallback;
}

final momentsRepositoryProvider = Provider<MomentsRepository>((ref) {
  // Only recreate when uid changes — avoids tearing down the Firestore stream.
  final uid = ref.watch(
    authStateProvider.select((async) => async.asData?.value?.uid ?? ''),
  );
  final resolvedUid = _currentUserId(ref, uid);
  final displayName = ref.watch(
    authStateProvider.select(
      (async) => async.asData?.value?.displayName?.trim() ?? '',
    ),
  );
  final avatar = ref.watch(
    authStateProvider.select(
      (async) => async.asData?.value?.ownerAvatarUrl ?? '',
    ),
  );
  final name = displayName.isEmpty ? 'Korisnik' : displayName;
  final authReady = ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
  if (isFirebaseReady && resolvedUid.isNotEmpty && authReady) {
    return FirestoreMomentsRepository(
      firestore: FirebaseFirestore.instance,
      currentUserId: resolvedUid,
      authorName: name,
      authorPhotoUrl: avatar,
    );
  }
  // Firebase is configured but the session is not ready yet: an EMPTY local
  // store, never the demo seed (no fake people in production).
  final repo = LocalMomentsRepository(
    currentUserId: resolvedUid.isEmpty ? 'local-user' : resolvedUid,
    authorName: name == 'Korisnik' ? 'Ti' : name,
    authorPhotoUrl: avatar,
    seed: isFirebaseReady ? const [] : null,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final momentsControllerProvider =
    NotifierProvider<MomentsController, AsyncValue<List<MomentModel>>>(
      MomentsController.new,
    );

/// All moments without the ones of blocked authors.
final visibleMomentsProvider = Provider<AsyncValue<List<MomentModel>>>((ref) {
  final blocked = ref.watch(blockedUserIdsProvider);
  return ref.watch(momentsControllerProvider).whenData((moments) {
    if (blocked.isEmpty) {
      return moments;
    }
    return [
      for (final moment in moments)
        if (!blocked.contains(moment.authorUserId)) moment,
    ];
  });
});

/// Latest comments of one moment; [limit] grows with "Prikaži starije".
final momentCommentsProvider = StreamProvider.family<List<MomentComment>,
    ({String momentId, int limit})>((ref, key) {
  return ref
      .watch(momentsRepositoryProvider)
      .watchComments(key.momentId, limit: key.limit);
});

final momentsMemberIdProvider = Provider<String>((ref) {
  final signedIn = ref.watch(
    authStateProvider.select((async) => async.asData?.value?.uid ?? ''),
  );
  final uid = _currentUserId(ref, signedIn);
  if (uid.isNotEmpty) {
    return uid;
  }
  return isFirebaseReady ? '' : 'local-user';
});

final isMomentsAdminProvider = Provider<bool>((ref) {
  return ref.watch(
    authStateProvider.select((auth) => auth.asData?.value?.isAdmin ?? false),
  );
});

// --- Local patches -----------------------------------------------------------

/// Changes made on this device that the loaded feed pages do not show yet:
/// my like state, comments I added / removed, deleted and newly created
/// posts. Every feed tab applies them, so a like in "Za tebe" also shows in
/// "Pratim".
class MomentPatches {
  const MomentPatches({
    this.myLikes = const {},
    this.commentDeltas = const {},
    this.deleted = const {},
    this.created = const [],
  });

  final Map<String, bool> myLikes;

  /// momentId → comments added (+) / deleted (−) since the post was loaded.
  /// Cleared for the posts of every freshly loaded page (the server count
  /// already includes them), so a refresh never counts a comment twice.
  final Map<String, int> commentDeltas;
  final Set<String> deleted;
  final List<MomentModel> created;

  MomentModel apply(MomentModel moment, String me) {
    var result = moment;
    final liked = myLikes[moment.id];
    if (liked != null && me.isNotEmpty && liked != moment.isLikedBy(me)) {
      result = result.copyWith(
        likes: liked
            ? [...moment.likes, me]
            : [
                for (final id in moment.likes)
                  if (id != me) id,
              ],
      );
    }
    final delta = commentDeltas[moment.id] ?? 0;
    if (delta != 0) {
      final count = moment.commentsCount + delta;
      result = result.copyWith(commentsCount: count < 0 ? 0 : count);
    }
    return result;
  }

  MomentPatches _copy({
    Map<String, bool>? myLikes,
    Map<String, int>? commentDeltas,
    Set<String>? deleted,
    List<MomentModel>? created,
  }) {
    return MomentPatches(
      myLikes: myLikes ?? this.myLikes,
      commentDeltas: commentDeltas ?? this.commentDeltas,
      deleted: deleted ?? this.deleted,
      created: created ?? this.created,
    );
  }
}

class MomentPatchesController extends Notifier<MomentPatches> {
  @override
  MomentPatches build() {
    // A different account starts clean.
    ref.watch(momentsMemberIdProvider);
    return const MomentPatches();
  }

  void setLike(String momentId, bool liked) {
    state = state._copy(myLikes: {...state.myLikes, momentId: liked});
  }

  void addComments(String momentId, int delta) {
    state = state._copy(
      commentDeltas: {
        ...state.commentDeltas,
        momentId: (state.commentDeltas[momentId] ?? 0) + delta,
      },
    );
  }

  /// [ids] were just read from the server: their counts are current.
  void loaded(Iterable<String> ids) {
    if (state.commentDeltas.isEmpty) {
      return;
    }
    final next = {...state.commentDeltas};
    var changed = false;
    for (final id in ids) {
      changed = next.remove(id) != null || changed;
    }
    if (changed) {
      state = state._copy(commentDeltas: next);
    }
  }

  void markDeleted(String momentId) {
    state = state._copy(
      deleted: {...state.deleted, momentId},
      created: [
        for (final moment in state.created)
          if (moment.id != momentId) moment,
      ],
    );
  }

  void addCreated(MomentModel moment) {
    state = state._copy(
      created: [
        moment,
        for (final item in state.created)
          if (item.id != moment.id) item,
      ],
    );
  }
}

final momentPatchesProvider =
    NotifierProvider<MomentPatchesController, MomentPatches>(
      MomentPatchesController.new,
    );

// --- Actions -----------------------------------------------------------------

/// Uploads the photo of draft [draftId] and returns its HTTPS URL. The draft
/// id is the object name, so a retry overwrites instead of adding a copy.
typedef MomentPhotoUploader = Future<String> Function(
  XFile photo,
  String draftId,
);

final momentPhotoUploaderProvider = Provider<MomentPhotoUploader>((ref) {
  return (photo, draftId) async {
    final storage = StorageService();
    var url = await storage.uploadXFile(
          file: photo,
          folderName: 'moments',
          fileStem: draftId,
        ) ??
        '';
    if (StorageService.isGsUri(url)) {
      url = await storage.resolveDownloadUrl(url);
    }
    if (!StorageService.isHttpsDownloadUrl(url)) {
      throw StateError(MomentsStrings.publishError);
    }
    return url;
  };
});

class MomentActions {
  MomentActions(this._ref);

  final Ref _ref;

  MomentsRepository get _repo => _ref.read(momentsRepositoryProvider);
  MomentPatchesController get _patches =>
      _ref.read(momentPatchesProvider.notifier);
  String get _me => _ref.read(momentsMemberIdProvider);

  String newMomentId() => _repo.newMomentId();

  String newCommentId(String momentId) => _repo.newCommentId(momentId);

  /// Optimistic like / unlike; reverted when the write fails.
  Future<void> toggleLike(MomentModel shown) async {
    final me = _me;
    if (me.isEmpty) {
      throw StateError(MomentsStrings.signInRequired);
    }
    final liked = !shown.isLikedBy(me);
    _patches.setLike(shown.id, liked);
    try {
      await _repo.setLike(shown.id, liked: liked);
    } catch (error) {
      _patches.setLike(shown.id, !liked);
      rethrow;
    }
  }

  Future<String> addComment(
    MomentModel shown,
    String text, {
    required String commentId,
    MomentComment? replyTo,
  }) async {
    final error = ContentValidationService.validateText(text, minLetters: 0);
    if (error != null) {
      throw StateError(error);
    }
    final root = replyTo == null
        ? null
        : (replyTo.isReply ? replyTo.replyToCommentId : replyTo.id);
    final id = await _repo.addComment(
      shown.id,
      text,
      commentId: commentId,
      replyToCommentId: root ?? '',
      replyToAuthorName: replyTo?.authorName ?? '',
    );
    _patches.addComments(shown.id, 1);
    return id;
  }

  Future<void> deleteComment(MomentModel shown, MomentComment comment) async {
    await _repo.deleteComment(shown.id, comment.id);
    _patches.addComments(shown.id, -1);
  }

  Future<void> toggleCommentLike(String momentId, String commentId) =>
      _repo.toggleCommentLike(momentId, commentId);

  Future<void> delete(MomentModel moment) async {
    await _repo.deleteMoment(moment.id);
    _patches.markDeleted(moment.id);
    _ref.invalidate(myMomentCountProvider);
  }

  Future<String> uploadPhoto(XFile photo, String draftId) async {
    final error = await ContentValidationService.validateImage(photo);
    if (error != null) {
      throw StateError(error);
    }
    return _ref.read(momentPhotoUploaderProvider)(photo, draftId);
  }

  /// Uploads a checked video, same path scheme as photos
  /// (`moments/{uid}/{draftId}.mp4`).
  Future<String> uploadVideo(PickedVideo video, String draftId) async {
    final problem = checkVideo(
      sizeBytes: video.sizeBytes,
      duration: video.duration,
      maxDuration: VideoLimits.maxDuration,
    );
    if (problem != null) {
      throw StateError(
        VideoStrings.problem(problem, VideoLimits.maxDuration),
      );
    }
    return _ref.read(momentPhotoUploaderProvider)(video.file, draftId);
  }

  /// Publishes [draft] (its id and uploaded photo URL set by the sheet).
  /// Retrying the same draft never creates a second post.
  Future<MomentModel> publish(MomentModel draft) async {
    if (draft.momentPhotoUrl.trim().isEmpty) {
      throw StateError(MomentsStrings.photoRequired);
    }
    final caption = draft.caption.trim();
    if (caption.isNotEmpty) {
      final error = ContentValidationService.validateText(
        caption,
        allowEmpty: true,
        minLetters: 0,
      );
      if (error != null) {
        throw StateError(error);
      }
    }
    final id = await _repo.createMoment(draft);
    final created = MomentModel(
      id: id,
      authorUserId: _currentUserId(_ref, _me),
      authorName: draft.authorName,
      authorPhotoUrl: draft.authorPhotoUrl,
      dogId: draft.dogId,
      dogName: draft.dogName,
      dogBreed: draft.dogBreed,
      dogPhotoUrl: draft.dogPhotoUrl,
      momentPhotoUrl: draft.momentPhotoUrl,
      mediaType: draft.mediaType,
      caption: caption,
      locationName: draft.locationName,
      cityId: draft.cityId,
      likes: const [],
      commentsCount: 0,
      createdAt: DateTime.now(),
    );
    _patches.addCreated(created);
    _ref.invalidate(myMomentCountProvider);
    _ref.invalidate(myPostsProvider);
    return created;
  }
}

final momentActionsProvider = Provider<MomentActions>(MomentActions.new);

/// Profile metric: how many moments I published.
final myMomentCountProvider = FutureProvider<int>((ref) async {
  final me = ref.watch(momentsMemberIdProvider);
  if (me.isEmpty) {
    return 0;
  }
  try {
    return await ref.watch(momentsRepositoryProvider).countByAuthor(me);
  } catch (error) {
    debugPrint('moments count: $error');
    return 0;
  }
});

/// My feed posts (`kind: post`), newest first – the profile "Objave" strip.
final myPostsProvider = FutureProvider<List<MomentModel>>((ref) async {
  final me = ref.watch(momentsMemberIdProvider);
  if (me.isEmpty) {
    return const [];
  }
  final deleted = ref.watch(
    momentPatchesProvider.select((patches) => patches.deleted),
  );
  final mine = await ref.watch(momentsRepositoryProvider).fetchByAuthor(me);
  return [
    for (final moment in mine)
      if (moment.isPost && !deleted.contains(moment.id)) moment,
  ];
});
