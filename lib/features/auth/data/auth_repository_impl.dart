import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../domain/app_user.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user_dog_profile.dart';
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
      return firestore
          .collection(userCollection)
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) => _mapAuthUser(firebaseUser, doc.data()));
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
  }) async {
    try {
      final credential = await _datasource.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _datasource.updateDisplayName(name.trim());
      final user = _requireUser(_datasource.currentUser ?? credential.user)
          .copyWith(
            displayName: name.trim(),
            city: city.trim(),
            cityId: cityId.trim(),
            neighborhoodId: neighborhoodId.trim(),
            neighborhoodName: neighborhoodName.trim(),
            bio: bio.trim(),
          );
      await _upsertUser(
        user,
        name: name.trim(),
        city: city.trim(),
        cityId: cityId.trim(),
        neighborhoodId: neighborhoodId.trim(),
        neighborhoodName: neighborhoodName.trim(),
        bio: bio.trim(),
      );
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
  Future<void> deleteAccount() async {
    final uid = _datasource.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthException(AuthErrorCode.unknown);
    }
    try {
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
    await _deleteQuery(firestore.collection('dogs').where('ownerId', isEqualTo: uid));
    await _deleteQuery(
      firestore.collection('adoption_dogs').where('uploaderUserId', isEqualTo: uid),
    );
    await _deleteQuery(
      firestore.collection('lost_dogs').where('uploaderUserId', isEqualTo: uid),
    );
    await _deleteQuery(
      firestore.collection('users').doc(uid).collection('fcmInbox'),
    );
    await firestore.collection(userCollection).doc(uid).delete();
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      return;
    }
    final store = query.firestore;
    var batch = store.batch();
    var count = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;
      if (count == 400) {
        await batch.commit();
        batch = store.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
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
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    await firestore.collection(userCollection).doc(uid).set(
      {
        'photoUrl': customPhotoUrl,
        'customPhotoUrl': customPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
      throw const AuthException(AuthErrorCode.unknown);
    }
    return _mapAuthUser(user);
  }

  AuthException _mapFirebase(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return const AuthException(
          AuthErrorCode.invalidEmail,
          AppStrings.authInvalidEmail,
        );
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      case 'INVALID_LOGIN_CREDENTIALS':
        return const AuthException(
          AuthErrorCode.wrongPassword,
          AppStrings.authWrongPassword,
        );
      case 'weak-password':
        return const AuthException(
          AuthErrorCode.weakPassword,
          AppStrings.authWeakPassword,
        );
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return const AuthException(
          AuthErrorCode.emailInUse,
          AppStrings.authEmailInUse,
        );
      case 'network-request-failed':
        return const AuthException(
          AuthErrorCode.network,
          AppStrings.authNetwork,
        );
      case 'requires-recent-login':
        return const AuthException(
          AuthErrorCode.requiresRecentLogin,
          AppStrings.authRequiresRecentLogin,
        );
      default:
        return const AuthException(
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
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection(userCollection).doc(user.uid);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final existing = snapshot.data();
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
        customPhotoUrl: (existing?['customPhotoUrl'] as String?)?.trim().isNotEmpty ==
                true
            ? (existing!['customPhotoUrl'] as String)
            : user.customPhotoUrl,
        role: UserRoleX.fromString(existing?['role'] as String?),
        dog: existing == null
            ? user.dog
            : UserDogProfile.fromMap(existing['dog']),
      );
      final payload = userDocumentPayload(
        next,
        includeCreatedAt: existing == null || existing['createdAt'] == null,
        includeRole: existing == null,
        includeDog: existing == null,
        includeOwnerPhoto: false,
      );
      if (existing != null) {
        payload.remove('role');
      }
      transaction.set(ref, payload, SetOptions(merge: true));
    });
  }

  Future<void> _createDefaultProfileIfNew(AppUser user) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection(userCollection).doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return;
    }
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
}
