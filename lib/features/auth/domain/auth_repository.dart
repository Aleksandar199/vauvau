import 'app_user.dart';
import 'user_dog_profile.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String city = '',
    String cityId = '',
    String neighborhoodId = '',
    String neighborhoodName = '',
    String bio = '',
  });

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();

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
  });

  Future<void> saveOwnerCustomPhoto({
    required String uid,
    required String customPhotoUrl,
  });
}
