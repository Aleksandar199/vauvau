import 'app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}
