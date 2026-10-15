import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_strings.dart';
import '../domain/auth_exception.dart';

class FirebaseAuthDatasource {
  FirebaseAuthDatasource(
    this._auth, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: const ['email', 'profile']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await user.updateDisplayName(name);
    await user.reload();
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw AuthException(AuthErrorCode.cancelled,
          AppStrings.authCancelled,
        );
      }
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return _auth.signInWithCredential(credential);
    } on AuthException {
      rethrow;
    } on PlatformException catch (error) {
      if (_isCancelled(error.code)) {
        throw AuthException(AuthErrorCode.cancelled,
          AppStrings.authCancelled,
        );
      }
      throw AuthException(
        AuthErrorCode.unknown,
        error.message ?? AppStrings.authUnknownError,
      );
    }
  }

  Future<void> signOut() async {
    // Clear Firebase session first so AuthGate flips to login immediately.
    await _auth.signOut();
    // Google cleanup can hang on web — never block logout on it.
    unawaited(_clearGoogleSession());
  }

  Future<void> _clearGoogleSession() async {
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Already signed out, unavailable, or hung on web.
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    final normalized = email.trim().toLowerCase();
    debugPrint('FirebaseAuthDatasource: sendPasswordResetEmail → $normalized');
    return _auth.sendPasswordResetEmail(email: normalized);
  }

  /// True when the signed-in user has an email/password credential.
  bool get currentUserHasPassword =>
      _auth.currentUser?.providerData.any(
        (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  /// Refreshes the sign-in so sensitive operations (account delete) do not
  /// fail with `requires-recent-login`. Uses [password] for email accounts,
  /// otherwise the Google flow.
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(AuthErrorCode.unknown);
    }
    if (currentUserHasPassword) {
      final email = user.email ?? '';
      if (email.isEmpty || password == null || password.isEmpty) {
        throw AuthException(
          AuthErrorCode.requiresRecentLogin,
          AppStrings.authRequiresRecentLogin,
        );
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return;
    }
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw AuthException(AuthErrorCode.cancelled, AppStrings.authCancelled);
    }
    final googleAuth = await account.authentication;
    await user.reauthenticateWithCredential(
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
    );
  }

  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(AuthErrorCode.unknown);
    }
    await user.delete();
  }

  bool _isCancelled(String code) {
    final normalized = code.toLowerCase();
    return normalized.contains('cancel') ||
        normalized == 'error_aborted_by_user';
  }
}
