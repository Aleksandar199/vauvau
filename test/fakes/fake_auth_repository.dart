import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/domain/auth_repository.dart';
import 'package:vauvau/features/auth/domain/user_dog_profile.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});

  AppUser? user;

  @override
  Stream<AppUser?> watchUser() => Stream<AppUser?>.value(user);

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    user = AppUser(uid: 'fake', email: email, displayName: 'Test');
    return user!;
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
    user = AppUser(
      uid: 'fake',
      email: email,
      displayName: name,
      city: city,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      bio: bio,
    );
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

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> deleteAccount() async {
    user = null;
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
    this.user = user.copyWith(
      displayName: name ?? user.displayName,
      city: city ?? user.city,
      cityId: cityId ?? user.cityId,
      neighborhoodId: neighborhoodId ?? user.neighborhoodId,
      neighborhoodName: neighborhoodName ?? user.neighborhoodName,
      bio: bio ?? user.bio,
      dog: writeDog ? (dog ?? user.dog) : user.dog,
    );
  }

  @override
  Future<void> saveOwnerCustomPhoto({
    required String uid,
    required String customPhotoUrl,
  }) async {
    if (user == null || user!.uid != uid) {
      return;
    }
    user = user!.copyWith(customPhotoUrl: customPhotoUrl);
  }
}
