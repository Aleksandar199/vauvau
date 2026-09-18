import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});

  AppUser? user;

  @override
  Stream<AppUser?> watchUser() => Stream<AppUser?>.value(user);

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    user = AppUser(uid: 'fake', email: email, displayName: name);
    return user!;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    user = AppUser(uid: 'fake', email: email, displayName: 'Test');
    return user!;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    user = const AppUser(uid: 'google', email: 'google@example.com');
    return user!;
  }

  @override
  Future<void> signOut() async {
    user = null;
  }
}
