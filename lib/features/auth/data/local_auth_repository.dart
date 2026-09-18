import 'dart:async';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

const AppUser localDemoUser = AppUser(
  uid: 'local-user',
  email: 'aleksandar@vauvau.local',
  displayName: 'Aleksandar',
);

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({this._user});

  AppUser? _user;
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> watchUser() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _setUser(
      AppUser(uid: 'local-user', email: email, displayName: 'Aleksandar'),
    );
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _setUser(
      AppUser(uid: 'local-user', email: email, displayName: name),
    );
  }

  @override
  Future<AppUser> signInWithGoogle() {
    return _setUser(localDemoUser);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  Future<AppUser> _setUser(AppUser user) async {
    _user = user;
    _controller.add(user);
    return user;
  }
}
