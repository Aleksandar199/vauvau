import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../moderation/presentation/block_controller.dart';
import '../data/firestore_moments_repository.dart';
import '../data/local_moments_repository.dart';
import '../domain/moment_model.dart';
import '../domain/moments_repository.dart';
import 'moments_strings.dart';

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
    final authReady =
        ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
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

  Future<void> addComment(String momentId, String text) {
    return ref.read(momentsRepositoryProvider).addComment(momentId, text);
  }

  Future<void> delete(String momentId) {
    return ref.read(momentsRepositoryProvider).deleteMoment(momentId);
  }

  Future<String> create({required MomentModel draft, XFile? photo}) async {
    var imageUrl = draft.momentPhotoUrl.trim();
    if (photo != null) {
      final error = await ContentValidationService.validateImage(photo);
      if (error != null) {
        throw StateError(error);
      }
      imageUrl = await StorageService().uploadXFile(
        file: photo,
        folderName: 'moments',
      ) ??
          '';
      if (imageUrl.isEmpty) {
        throw StateError(MomentsStrings.publishError);
      }
      if (StorageService.isGsUri(imageUrl)) {
        imageUrl = await StorageService().resolveDownloadUrl(imageUrl);
      }
      if (!StorageService.isHttpsDownloadUrl(imageUrl)) {
        throw StateError(MomentsStrings.publishError);
      }
    }
    if (imageUrl.isEmpty) {
      throw StateError(MomentsStrings.photoRequired);
    }
    return ref
        .read(momentsRepositoryProvider)
        .createMoment(
          MomentModel(
            id: '',
            authorUserId: _currentUserId(ref, draft.authorUserId),
            authorName: draft.authorName,
            dogId: draft.dogId,
            dogName: draft.dogName,
            dogBreed: draft.dogBreed,
            dogPhotoUrl: draft.dogPhotoUrl,
            momentPhotoUrl: imageUrl,
            caption: draft.caption,
            locationName: draft.locationName,
            likes: const [],
            commentsCount: 0,
            createdAt: DateTime.now(),
          ),
        );
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
  final name = displayName.isEmpty ? 'Korisnik' : displayName;
  final authReady = ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
  if (isFirebaseReady && resolvedUid.isNotEmpty && authReady) {
    return FirestoreMomentsRepository(
      firestore: FirebaseFirestore.instance,
      currentUserId: resolvedUid,
      authorName: name,
    );
  }
  final repo = LocalMomentsRepository(
    currentUserId: resolvedUid.isEmpty ? 'local-user' : resolvedUid,
    authorName: name == 'Korisnik' ? 'Ti' : name,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final momentsControllerProvider =
    NotifierProvider<MomentsController, AsyncValue<List<MomentModel>>>(
      MomentsController.new,
    );

/// Feed without the moments of blocked authors. Admin moderation keeps reading
/// [momentsControllerProvider] so nothing is hidden from moderators.
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

final momentCommentsProvider =
    StreamProvider.family<List<MomentComment>, String>((ref, momentId) {
      return ref.watch(momentsRepositoryProvider).watchComments(momentId);
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
