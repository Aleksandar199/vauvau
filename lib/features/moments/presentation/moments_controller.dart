import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/firestore_moments_repository.dart';
import '../data/local_moments_repository.dart';
import '../domain/moment_model.dart';
import '../domain/moments_repository.dart';

class MomentsController extends Notifier<AsyncValue<List<MomentModel>>> {
  @override
  AsyncValue<List<MomentModel>> build() {
    final repo = ref.watch(momentsRepositoryProvider);
    final sub = repo.watchMoments().listen(
      (moments) => state = AsyncValue.data(moments),
      onError: (Object error, StackTrace stack) {
        debugPrint('Moments stream: $error');
        state = AsyncValue.error(error, stack);
      },
    );
    ref.onDispose(sub.cancel);
    return const AsyncValue.loading();
  }

  void reload() => ref.invalidateSelf();

  Future<void> toggleLike(String momentId) {
    return ref.read(momentsRepositoryProvider).toggleLike(momentId);
  }

  Future<void> addComment(String momentId, String text) {
    return ref.read(momentsRepositoryProvider).addComment(momentId, text);
  }

  Future<void> delete(String momentId) {
    return ref.read(momentsRepositoryProvider).deleteMoment(momentId);
  }

  Future<String> create({
    required MomentModel draft,
    XFile? photo,
  }) async {
    var imageUrl = draft.momentPhotoUrl.trim();
    if (photo != null) {
      try {
        final error = await ContentValidationService.validateImage(photo);
        if (error == null) {
          imageUrl = await ImageUploadService.upload(await photo.readAsBytes());
        }
      } catch (error, stack) {
        debugPrint('Moment photo upload failed: $error');
        debugPrint('$stack');
      }
    }
    if (imageUrl.isEmpty) {
      imageUrl = kFallbackDogPhotoUrl;
    }
    return ref.read(momentsRepositoryProvider).createMoment(
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
  final user = ref.watch(authStateProvider).asData?.value;
  final uid = _currentUserId(ref, user?.uid ?? '');
  final name = (user?.displayName ?? '').trim().isEmpty
      ? 'Korisnik'
      : user!.displayName!.trim();
  if (isFirebaseReady) {
    return FirestoreMomentsRepository(
      firestore: FirebaseFirestore.instance,
      currentUserId: uid,
      authorName: name,
    );
  }
  final repo = LocalMomentsRepository(
    currentUserId: uid.isEmpty ? 'local-user' : uid,
    authorName: name == 'Korisnik' ? 'Ti' : name,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final momentsControllerProvider =
    NotifierProvider<MomentsController, AsyncValue<List<MomentModel>>>(
  MomentsController.new,
);

final momentCommentsProvider =
    StreamProvider.family<List<MomentComment>, String>((ref, momentId) {
  return ref.watch(momentsRepositoryProvider).watchComments(momentId);
});

final momentsMemberIdProvider = Provider<String>((ref) {
  final signedIn = ref.watch(authStateProvider).asData?.value?.uid ?? '';
  final uid = _currentUserId(ref, signedIn);
  if (uid.isNotEmpty) {
    return uid;
  }
  return isFirebaseReady ? '' : 'local-user';
});
