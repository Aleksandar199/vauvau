import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/app_user.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import 'firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

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
      return _requireUser(credential.user);
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
      return _requireUser(_datasource.currentUser ?? credential.user);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final credential = await _datasource.signInWithGoogle();
      return _requireUser(credential.user);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException(
          AuthErrorCode.cancelled,
          'Google Sign-In was cancelled.',
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
          'Enter a valid email address.',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          AuthErrorCode.wrongPassword,
          'Incorrect email or password.',
        );
      case 'user-not-found':
        return const AuthException(
          AuthErrorCode.userNotFound,
          'No account exists for this email.',
        );
      case 'weak-password':
        return const AuthException(
          AuthErrorCode.weakPassword,
          'Password must be at least 6 characters.',
        );
      case 'email-already-in-use':
        return const AuthException(
          AuthErrorCode.emailInUse,
          'An account already exists for this email.',
        );
      case 'network-request-failed':
        return const AuthException(
          AuthErrorCode.network,
          'Check your connection and try again.',
        );
      default:
        return AuthException(
          AuthErrorCode.unknown,
          error.message ?? 'Authentication failed.',
        );
    }
  }
}
