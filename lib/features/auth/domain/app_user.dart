import 'user_dog_profile.dart';

import '../../../core/constants/serbia_locations.dart';

enum UserRole { user, admin }

extension UserRoleX on UserRole {
  String get firestoreValue => name;

  static UserRole fromString(String? value) {
    if (value == 'admin') {
      return UserRole.admin;
    }
    return UserRole.user;
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl = '',
    this.customPhotoUrl = '',
    this.city = '',
    this.cityId = '',
    this.neighborhoodId = '',
    this.neighborhoodName = '',
    this.bio = '',
    this.role = UserRole.user,
    this.dog = const UserDogProfile(),
  });

  final String uid;
  final String? email;
  final String? displayName;
  /// Firebase Auth / Google avatar. Never written over a custom owner photo.
  final String photoUrl;
  /// Owner-uploaded profile photo from Firestore (`photoUrl`/`customPhotoUrl`).
  final String customPhotoUrl;
  final String city;
  final String cityId;
  final String neighborhoodId;
  final String neighborhoodName;
  final String bio;
  final UserRole role;
  final UserDogProfile dog;

  bool get isAdmin => role == UserRole.admin;

  String get cityName => city;

  String get locationLabel =>
      SerbiaLocations.formatPlace(cityName, neighborhoodName);

  String get ownerAvatarUrl {
    final custom = customPhotoUrl.trim();
    if (custom.isNotEmpty) {
      return custom;
    }
    return photoUrl.trim();
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? customPhotoUrl,
    String? city,
    String? cityId,
    String? neighborhoodId,
    String? neighborhoodName,
    String? bio,
    UserRole? role,
    UserDogProfile? dog,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      customPhotoUrl: customPhotoUrl ?? this.customPhotoUrl,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      dog: dog ?? this.dog,
    );
  }

  /// Resolves the owner avatar stored on the user document.
  /// Prefers `customPhotoUrl`, then Firestore `photoUrl` when it is not just
  /// mirroring the Firebase Auth / Google avatar.
  static String ownerPhotoFromDocument(
    Map<String, dynamic>? data, {
    String authPhotoUrl = '',
  }) {
    final doc = data ?? const <String, dynamic>{};
    final authPhoto = authPhotoUrl.trim();
    final docCustom = (doc['customPhotoUrl'] as String?)?.trim() ?? '';
    if (docCustom.isNotEmpty) {
      return docCustom;
    }
    final docPhoto = (doc['photoUrl'] as String?)?.trim() ?? '';
    if (docPhoto.isEmpty) {
      return '';
    }
    // Email/password users have no Auth photo — treat Firestore photoUrl as
    // the owner upload. Google users: only use it when it differs from Auth.
    if (authPhoto.isEmpty || docPhoto != authPhoto) {
      return docPhoto;
    }
    return '';
  }

  static AppUser fromAuthAndDocument({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? data,
  }) {
    final doc = data ?? const <String, dynamic>{};
    final authPhoto = photoUrl?.trim() ?? '';
    final storedPhoto = ownerPhotoFromDocument(doc, authPhotoUrl: authPhoto);
    return AppUser(
      uid: uid,
      email: (doc['email'] as String?)?.trim().isNotEmpty == true
          ? doc['email'] as String
          : email,
      displayName: (doc['name'] as String?)?.trim().isNotEmpty == true
          ? doc['name'] as String
          : displayName,
      photoUrl: authPhoto,
      customPhotoUrl: storedPhoto,
      city: (doc['cityName'] as String?)?.trim().isNotEmpty == true
          ? (doc['cityName'] as String).trim()
          : (doc['city'] as String? ?? ''),
      cityId: doc['cityId'] as String? ?? '',
      neighborhoodId: doc['neighborhoodId'] as String? ?? '',
      neighborhoodName: doc['neighborhoodName'] as String? ?? '',
      bio: doc['bio'] as String? ?? '',
      role: UserRoleX.fromString(doc['role'] as String?),
      dog: UserDogProfile.fromMap(doc['dog']),
    );
  }
}
