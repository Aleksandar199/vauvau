import 'dart:async';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/user_dog_profile.dart';

const AppUser localDemoUser = AppUser(
  uid: 'local-user',
  email: 'aleksandar@vauvau.local',
  displayName: 'Aleksandar',
  city: 'Novi Sad',
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
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _setUser(
      AppUser(
        uid: 'local-user',
        email: email,
        displayName: 'Aleksandar',
        city: 'Novi Sad',
      ),
    );
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
  }) {
    return _setUser(
      AppUser(
        uid: 'local-user',
        email: email,
        displayName: name,
        city: city,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        neighborhoodName: neighborhoodName,
        bio: bio,
      ),
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

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> deleteAccount() async {
    _user = null;
    _controller.add(null);
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
    if (_user == null || _user!.uid != user.uid) {
      return;
    }
    _user = _user!.copyWith(
      displayName: name ?? _user!.displayName,
      city: city ?? _user!.city,
      cityId: cityId ?? _user!.cityId,
      neighborhoodId: neighborhoodId ?? _user!.neighborhoodId,
      neighborhoodName: neighborhoodName ?? _user!.neighborhoodName,
      bio: bio ?? _user!.bio,
      dog: writeDog ? (dog ?? _user!.dog) : _user!.dog,
    );
    _controller.add(_user);
  }

  @override
  Future<void> saveOwnerCustomPhoto({
    required String uid,
    required String customPhotoUrl,
  }) async {
    if (_user == null || _user!.uid != uid) {
      return;
    }
    _user = _user!.copyWith(customPhotoUrl: customPhotoUrl);
    _controller.add(_user);
  }

  Future<AppUser> _setUser(AppUser user) async {
    _user = user;
    _controller.add(user);
    return user;
  }
}
