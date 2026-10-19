import 'owner_details.dart';
import 'user_dog_profile.dart';

import '../../../core/constants/serbia_locations.dart';

/// `partner` = a shop that accepts VauVau coupons (`users/{uid}.partnerId`
/// → `partners/{id}`); only the admin assigns it (firestore.rules).
enum UserRole { user, admin, partner }

extension UserRoleX on UserRole {
  String get firestoreValue => name;

  static UserRole fromString(String? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      'partner' => UserRole.partner,
      _ => UserRole.user,
    };
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
    this.details = const OwnerDetails(),
    this.partnerId = '',
    this.isSuspended = false,
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
  /// Optional public "about me" fields (age group, interests, walks...).
  final OwnerDetails details;
  /// `partners/{id}` for [UserRole.partner]; set only by the admin.
  final String partnerId;
  /// Admin suspension (`users/{uid}.isSuspended`); the owner cannot clear it.
  final bool isSuspended;

  bool get isAdmin => role == UserRole.admin;

  bool get isPartner => role == UserRole.partner && partnerId.isNotEmpty;

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
    OwnerDetails? details,
    String? partnerId,
    bool? isSuspended,
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
      details: details ?? this.details,
      partnerId: partnerId ?? this.partnerId,
      isSuspended: isSuspended ?? this.isSuspended,
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
      details: OwnerDetails.fromMap(doc),
      partnerId: (doc['partnerId'] as String? ?? '').trim(),
      isSuspended: doc['isSuspended'] == true,
    );
  }
}
