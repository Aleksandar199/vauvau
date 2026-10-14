import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../map/presentation/walk_controller.dart';
import '../domain/auth_exception.dart';
import 'auth_providers.dart';

enum AuthBusy { none, email, google }

class AuthController extends Notifier<AsyncValue<void>> {
  AuthBusy _busy = AuthBusy.none;

  AuthBusy get busy => state.isLoading ? _busy : AuthBusy.none;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _run(
      AuthBusy.email,
      () async {
        await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
              email: email,
              password: password,
            );
        ref.read(sessionSignedOutProvider.notifier).setSignedOut(false);
      },
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String city = '',
    String cityId = '',
    String neighborhoodId = '',
    String neighborhoodName = '',
    String bio = '',
    String customPhotoUrl = '',
  }) {
    return _run(
      AuthBusy.email,
      () async {
        await ref.read(authRepositoryProvider).signUpWithEmailAndPassword(
              email: email,
              password: password,
              name: name,
              city: city,
              cityId: cityId,
              neighborhoodId: neighborhoodId,
              neighborhoodName: neighborhoodName,
              bio: bio,
              customPhotoUrl: customPhotoUrl,
            );
        ref.read(sessionSignedOutProvider.notifier).setSignedOut(false);
      },
    );
  }

  Future<bool> signInWithGoogle() {
    return _run(
      AuthBusy.google,
      () async {
        await ref.read(authRepositoryProvider).signInWithGoogle();
        ref.read(sessionSignedOutProvider.notifier).setSignedOut(false);
      },
    );
  }

  /// Returns success + captured error so UI need not read [ref] after await
  /// (Settings may already be disposed).
  Future<({bool success, Object? error})> signOut() async {
    // Capture dependencies before any await — callers may dispose their
    // WidgetRef while sign-out is in flight; Notifier.ref stays valid.
    final walk = ref.read(walkControllerProvider.notifier);
    final session = ref.read(sessionSignedOutProvider.notifier);
    final repo = ref.read(authRepositoryProvider);

    // Clear walk GPS + Firestore presence while this uid is still valid,
    // otherwise the next account can still see the previous walker on the map.
    try {
      await walk.stopForSignOut();
    } catch (_) {}
    session.setSignedOut(true);
    final ok = await _run(
      AuthBusy.email,
      () => repo.signOut(),
    );
    if (!ok) {
      session.setSignedOut(false);
      return (success: false, error: state.error);
    }
    ref.invalidate(authStateProvider);
    ref.invalidate(walkControllerProvider);
    ref.invalidate(liveWalkingDogsProvider);
    return (success: true, error: null);
  }

  Future<bool> sendPasswordResetEmail(String email) {
    return _run(
      AuthBusy.email,
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
    );
  }

  Future<({bool success, Object? error})> deleteAccount() async {
    try {
      await ref.read(walkControllerProvider.notifier).stopForSignOut();
    } catch (_) {}
    final ok = await _run(
      AuthBusy.email,
      () async {
        await ref.read(authRepositoryProvider).deleteAccount();
        ref.read(sessionSignedOutProvider.notifier).setSignedOut(true);
      },
    );
    if (!ok) {
      return (success: false, error: state.error);
    }
    return (success: true, error: null);
  }

  Future<bool> _run(AuthBusy busy, Future<void> Function() action) async {
    _busy = busy;
    state = const AsyncLoading();
    try {
      await action();
      _busy = AuthBusy.none;
      state = const AsyncData(null);
      return true;
    } on AuthException catch (error, stackTrace) {
      _busy = AuthBusy.none;
      if (error.code == AuthErrorCode.cancelled) {
        state = const AsyncData(null);
        return false;
      }
      state = AsyncError(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      _busy = AuthBusy.none;
      state = AsyncError(
        AuthException(AuthErrorCode.unknown, error.toString()),
        stackTrace,
      );
      return false;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
