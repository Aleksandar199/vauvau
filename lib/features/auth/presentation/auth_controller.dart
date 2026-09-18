import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_exception.dart';
import 'auth_providers.dart';

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _run(
      () => ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          ),
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
          ),
    );
  }

  Future<bool> signInWithGoogle() {
    return _run(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<void> signOut() async {
    await _run(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return true;
    } on AuthException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
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
