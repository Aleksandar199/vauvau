import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../domain/app_user.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user_dog_profile.dart';
import 'account_deletion_service.dart';
import 'firebase_auth_datasource.dart';
import 'user_document.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource, {this._firestore});

  final FirebaseAuthDatasource _datasource;
  final FirebaseFirestore? _firestore;

  @override
  Stream<AppUser?> watchUser() {
    return _datasource.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream<AppUser?>.value(null);
      }
      final firestore = _firestore;
      if (firestore == null) {
        return Stream<AppUser?>.value(_mapAuthUser(firebaseUser));
      }

      // Emit Auth user immediately, then enrich from Firestore.
      // Swallow permission errors during logout so the auth stream stays healthy.
      return Stream<AppUser?>.multi((controller) {
        controller.add(_mapAuthUser(firebaseUser));
        final sub = firestore
            .collection(userCollection)
            .doc(firebaseUser.uid)
            .snapshots()
            .listen(
          (doc) {
            if (_datasource.currentUser?.uid != firebaseUser.uid) {
              return;
            }
            final data = doc.data();
            if (data != null && userPrivateFields.any(data.containsKey)) {
              // Sessions restored without sign-in still move legacy fields.
              unawaited(_syncPrivateDoc(firebaseUser.uid, firebaseUser.email));
            }
            controller.add(_mapAuthUser(firebaseUser, data));
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('User profile stream: $error');
            if (_datasource.currentUser == null) {
              controller.add(null);
            }
          },
        );
        controller.onCancel = sub.cancel;
      });
    });
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _datasource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _requireUser(credential.user);
      await _upsertUser(user);
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String city = '',
    String cityId = '',
    String neighborhoodId = '',
    String neighborhoodName = '',
    String bio = '',
    String customPhotoUrl = '',
  }) async {
    try {
      final credential = await _datasource.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _datasource.updateDisplayName(name.trim());
      final ownerPhoto = customPhotoUrl.trim();
      final user = _requireUser(_datasource.currentUser ?? credential.user)
          .copyWith(
            displayName: name.trim(),
            city: city.trim(),
            cityId: cityId.trim(),
            neighborhoodId: neighborhoodId.trim(),
            neighborhoodName: neighborhoodName.trim(),
            bio: bio.trim(),
            customPhotoUrl: ownerPhoto,
          );
      await _upsertUser(
        user,
        name: name.trim(),
        city: city.trim(),
        cityId: cityId.trim(),
        neighborhoodId: neighborhoodId.trim(),
        neighborhoodName: neighborhoodName.trim(),
        bio: bio.trim(),
        writeOwnerPhoto: ownerPhoto.isNotEmpty,
      );
      if (ownerPhoto.isNotEmpty) {
        // Best-effort Auth avatar sync so all surfaces that read photoURL
        // stay aligned with the uploaded owner photo.
        try {
          await _datasource.currentUser?.updatePhotoURL(ownerPhoto);
        } catch (error) {
          debugPrint('Auth photoURL sync skipped: $error');
        }
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final credential = await _datasource.signInWithGoogle();
      final user = _requireUser(credential.user);
      await _createDefaultProfileIfNew(user);
      return user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _datasource.signOut();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _datasource.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  bool get deleteAccountRequiresPassword => _datasource.currentUserHasPassword;

  @override
  Future<void> deleteAccount({String? password}) async {
    final uid = _datasource.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw AuthException(AuthErrorCode.unknown);
    }
    try {
      // Re-auth first: otherwise user.delete() can fail with
      // requires-recent-login after the data is already gone.
      await _datasource.reauthenticate(password: password);
      await _deleteOwnedData(uid);
      await _datasource.deleteCurrentUser();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  Future<void> _deleteOwnedData(String uid) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    await AccountDeletionService(firestore: firestore).deleteAllUserData(uid);
  }

  @override
  Future<void> saveUserProfile({
    required AppUser user,
    UserDogProfile? dog,
    String? city,
    String? name,
    String? bio,
    String? cityId,
    String? neighborhoodId,
    String? neighborhoodName,
    bool writeDog = true,
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final next = user.copyWith(
      displayName: name ?? user.displayName,
      city: city ?? user.city,
      cityId: cityId ?? user.cityId,
      neighborhoodId: neighborhoodId ?? user.neighborhoodId,
      neighborhoodName: neighborhoodName ?? user.neighborhoodName,
      bio: bio ?? user.bio,
      dog: dog ?? user.dog,
    );
    await firestore.collection(userCollection).doc(user.uid).set(
          userDocumentPayload(
            next,
            includeCreatedAt: false,
            // Never clobber Firestore admin role during profile edits.
            includeRole: false,
            includeDog: writeDog,
            includeOwnerPhoto: false,
          ),
          SetOptions(merge: true),
        );
    if (!writeDog) {
      return;
    }
    final dogId = next.dog.id;
    if (dogId.isEmpty) {
      return;
    }
    await firestore.collection('dogs').doc(dogId).set(
      {
        'id': dogId,
        'ownerId': user.uid,
        'name': next.dog.name,
        'breed': next.dog.breed,
        'age': next.dog.age,
        'ageYears': next.dog.age,
        'gender': next.dog.gender,
        'bio': next.dog.bio,
        ...firestorePhotoFields(next.dog.photoUrls),
        'size': next.dog.size,
        'temperament': next.dog.temperament,
        'ownerName': next.displayName ?? '',
        'location': next.locationLabel,
        'cityId': next.cityId,
        'cityName': next.cityName,
        'neighborhoodId': next.neighborhoodId,
        'neighborhoodName': next.neighborhoodName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> saveOwnerCustomPhoto({
    required String uid,
    required String customPhotoUrl,
  }) async {
    final trimmed = customPhotoUrl.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection(userCollection).doc(uid);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        transaction.set(ref, {
          'uid': uid,
          'role': UserRole.user.firestoreValue,
          'photoUrl': trimmed,
          'customPhotoUrl': trimmed,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      // Partial update keeps role and other fields untouched for security rules.
      transaction.update(ref, {
        'photoUrl': trimmed,
        'customPhotoUrl': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    final authUser = _datasource.currentUser;
    if (authUser != null && authUser.uid == uid) {
      try {
        await authUser.updatePhotoURL(trimmed);
        await authUser.reload();
      } catch (error) {
        debugPrint('Auth photoURL sync skipped: $error');
      }
    }
  }

  AppUser _mapAuthUser(User user, [Map<String, dynamic>? data]) {
    return AppUser.fromAuthAndDocument(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      data: data,
    );
  }

  AppUser _requireUser(User? user) {
    if (user == null) {
      throw AuthException(AuthErrorCode.unknown);
    }
    return _mapAuthUser(user);
  }

  AuthException _mapFirebase(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return AuthException(
          AuthErrorCode.invalidEmail,
          AppStrings.authInvalidEmail,
        );
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      case 'INVALID_LOGIN_CREDENTIALS':
        return AuthException(
          AuthErrorCode.wrongPassword,
          AppStrings.authWrongPassword,
        );
      case 'weak-password':
        return AuthException(
          AuthErrorCode.weakPassword,
          AppStrings.authWeakPassword,
        );
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return AuthException(
          AuthErrorCode.emailInUse,
          AppStrings.authEmailInUse,
        );
      case 'network-request-failed':
        return AuthException(
          AuthErrorCode.network,
          AppStrings.authNetwork,
        );
      case 'requires-recent-login':
        return AuthException(
          AuthErrorCode.requiresRecentLogin,
          AppStrings.authRequiresRecentLogin,
        );
      default:
        return AuthException(
          AuthErrorCode.unknown,
          AppStrings.authUnknownError,
        );
    }
  }

  Future<void> _upsertUser(
    AppUser user, {
    String? name,
    String? city,
    String? cityId,
    String? neighborhoodId,
    String? neighborhoodName,
    String? bio,
    bool writeOwnerPhoto = false,
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection(userCollection).doc(user.uid);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final existing = snapshot.data();
      final preservedPhoto = AppUser.ownerPhotoFromDocument(
        existing,
        authPhotoUrl: user.photoUrl,
      );
      final next = user.copyWith(
        displayName: name ?? user.displayName,
        city: (city != null && city.isNotEmpty)
            ? city
            : (existing?['cityName'] as String? ??
                existing?['city'] as String? ??
                user.city),
        cityId: (cityId != null && cityId.isNotEmpty)
            ? cityId
            : (existing?['cityId'] as String? ?? user.cityId),
        neighborhoodId: (neighborhoodId != null && neighborhoodId.isNotEmpty)
            ? neighborhoodId
            : (existing?['neighborhoodId'] as String? ?? user.neighborhoodId),
        neighborhoodName:
            (neighborhoodName != null && neighborhoodName.isNotEmpty)
                ? neighborhoodName
                : (existing?['neighborhoodName'] as String? ??
                    user.neighborhoodName),
        bio: bio ?? (existing?['bio'] as String? ?? user.bio),
        customPhotoUrl: user.customPhotoUrl.trim().isNotEmpty
            ? user.customPhotoUrl.trim()
            : preservedPhoto,
        role: UserRoleX.fromString(existing?['role'] as String?),
        dog: existing == null
            ? user.dog
            : UserDogProfile.fromMap(existing['dog']),
      );
      final shouldWritePhoto =
          writeOwnerPhoto || next.customPhotoUrl.trim().isNotEmpty;
      final payload = userDocumentPayload(
        next,
        includeCreatedAt: existing == null || existing['createdAt'] == null,
        includeRole: existing == null,
        includeDog: existing == null,
        includeOwnerPhoto: shouldWritePhoto,
      );
      if (existing != null) {
        payload.remove('role');
      }
      transaction.set(ref, payload, SetOptions(merge: true));
    });
    await _syncPrivateDoc(user.uid, user.email);
  }

  bool _privateSyncRunning = false;

  /// Keeps email in `users/{uid}/private/account` and moves legacy private
  /// fields off the public profile. Best-effort: never blocks sign-in.
  Future<void> _syncPrivateDoc(String uid, String? email) async {
    final firestore = _firestore;
    if (firestore == null || _privateSyncRunning) {
      return;
    }
    _privateSyncRunning = true;
    try {
      final trimmed = (email ?? '').trim();
      if (trimmed.isNotEmpty) {
        await userPrivateDoc(firestore, uid).set(
          {'email': trimmed},
          SetOptions(merge: true),
        );
      }
      await moveUserPrivateFields(firestore, uid, authEmail: email);
    } catch (error) {
      debugPrint('User private sync skipped: $error');
    } finally {
      _privateSyncRunning = false;
    }
  }

  Future<void> _createDefaultProfileIfNew(AppUser user) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection(userCollection).doc(user.uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      await ref.set(
        userDocumentPayload(
          user,
          includeCreatedAt: true,
          includeRole: true,
          includeDog: true,
          includeOwnerPhoto: false,
        ),
      );
    }
    await _syncPrivateDoc(user.uid, user.email);
  }
}
