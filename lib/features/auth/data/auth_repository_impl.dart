import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_strings.dart';
import '../domain/app_user.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import 'firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource, {this._firestore});

  final FirebaseAuthDatasource _datasource;
  final FirebaseFirestore? _firestore;

  @override
  Stream<AppUser?> watchUser() {
    return _datasource.authStateChanges().map(_mapUser);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _datasource.signInWithEmail(
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
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _datasource.createUser(
        email: email,
        password: password,
      );
      await _datasource.updateDisplayName(name.trim());
      final user = _requireUser(_datasource.currentUser ?? credential.user);
      await _upsertUser(user, name: name.trim());
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
      await _upsertUser(user);
      return user;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException(
          AuthErrorCode.cancelled,
          AppStrings.authCancelled,
        );
      }
      throw AuthException(AuthErrorCode.unknown, error.description ?? error.code.name);
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

  AppUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  AppUser _requireUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) {
      throw const AuthException(AuthErrorCode.unknown);
    }
    return mapped;
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
        return const AuthException(
          AuthErrorCode.wrongPassword,
          AppStrings.authWrongPassword,
        );
      case 'user-not-found':
        return const AuthException(
          AuthErrorCode.userNotFound,
          AppStrings.authUserNotFound,
        );
      case 'weak-password':
        return const AuthException(
          AuthErrorCode.weakPassword,
          AppStrings.authWeakPassword,
        );
      case 'email-already-in-use':
        return const AuthException(
          AuthErrorCode.emailInUse,
          AppStrings.authEmailInUse,
        );
      case 'network-request-failed':
        return const AuthException(
          AuthErrorCode.network,
          AppStrings.authNetwork,
        );
      default:
        return const AuthException(
          AuthErrorCode.unknown,
          AppStrings.authUnknownError,
        );
    }
  }

  Future<void> _upsertUser(AppUser user, {String? name}) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection('users').doc(user.uid);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final payload = <String, dynamic>{
        'uid': user.uid,
        'name': name ?? user.displayName ?? '',
        'email': user.email ?? '',
      };
      if (!snapshot.exists || snapshot.data()?['createdAt'] == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }
      transaction.set(ref, payload, SetOptions(merge: true));
    });
  }
}
