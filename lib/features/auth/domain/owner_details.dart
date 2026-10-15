/// Optional "about the owner" fields on the public `users/{uid}` doc
/// (part of [AppUser]). Choice fields hold stable keys from
/// [OwnerDetailOptions], never translated labels. Empty string / list /
/// `false` means "not set" and is removed from Firestore on save.
class OwnerDetails {
  const OwnerDetails({
    this.ageGroup = '',
    this.occupation = '',
    this.interests = const [],
    this.languages = const [],
    this.lookingFor = const [],
    this.favoriteActivities = const [],
    this.walkTimes = const [],
    this.walkPace = '',
    this.groupWalks = false,
    this.dogExperience = '',
    this.sharesAdvice = false,
    this.volunteerInterest = false,
    this.favoriteBreed = '',
    this.favoriteWalkSpot = '',
    this.instagram = '',
  });

  static const int occupationMaxLength = 60;
  static const int favoriteBreedMaxLength = 60;
  static const int favoriteWalkSpotMaxLength = 80;

  /// Firestore field names on `users/{uid}`.
  static const String ageGroupField = 'ageGroup';
  static const String occupationField = 'occupation';
  static const String interestsField = 'interests';
  static const String languagesField = 'languages';
  static const String lookingForField = 'lookingFor';
  static const String favoriteActivitiesField = 'favoriteActivities';
  static const String walkTimesField = 'walkTimes';
  static const String walkPaceField = 'walkPace';
  static const String groupWalksField = 'groupWalks';
  static const String dogExperienceField = 'dogExperience';
  static const String sharesAdviceField = 'sharesAdvice';
  static const String volunteerInterestField = 'volunteerInterest';
  static const String favoriteBreedField = 'favoriteBreed';
  static const String favoriteWalkSpotField = 'favoriteWalkSpot';
  static const String instagramField = 'instagram';

  static const List<String> fields = [
    ageGroupField,
    occupationField,
    interestsField,
    languagesField,
    lookingForField,
    favoriteActivitiesField,
    walkTimesField,
    walkPaceField,
    groupWalksField,
    dogExperienceField,
    sharesAdviceField,
    volunteerInterestField,
    favoriteBreedField,
    favoriteWalkSpotField,
    instagramField,
  ];

  /// Key from [OwnerDetailOptions.ageGroups].
  final String ageGroup;
  final String occupation;
  final List<String> interests;
  final List<String> languages;
  final List<String> lookingFor;
  final List<String> favoriteActivities;
  final List<String> walkTimes;

  /// Key from [OwnerDetailOptions.walkPaces].
  final String walkPace;
  final bool groupWalks;

  /// Key from [OwnerDetailOptions.experienceLevels].
  final String dogExperience;
  final bool sharesAdvice;
  final bool volunteerInterest;
  final String favoriteBreed;
  final String favoriteWalkSpot;

  /// Instagram username without `@` (see [normalizeInstagram]).
  final String instagram;

  bool get isEmpty =>
      ageGroup.isEmpty &&
      occupation.isEmpty &&
      interests.isEmpty &&
      languages.isEmpty &&
      lookingFor.isEmpty &&
      favoriteActivities.isEmpty &&
      walkTimes.isEmpty &&
      walkPace.isEmpty &&
      !groupWalks &&
      dogExperience.isEmpty &&
      !sharesAdvice &&
      !volunteerInterest &&
      favoriteBreed.isEmpty &&
      favoriteWalkSpot.isEmpty &&
      instagram.isEmpty;

  String get instagramUrl =>
      instagram.isEmpty ? '' : 'https://www.instagram.com/$instagram/';

  OwnerDetails copyWith({
    String? ageGroup,
    String? occupation,
    List<String>? interests,
    List<String>? languages,
    List<String>? lookingFor,
    List<String>? favoriteActivities,
    List<String>? walkTimes,
    String? walkPace,
    bool? groupWalks,
    String? dogExperience,
    bool? sharesAdvice,
    bool? volunteerInterest,
    String? favoriteBreed,
    String? favoriteWalkSpot,
    String? instagram,
  }) {
    return OwnerDetails(
      ageGroup: ageGroup ?? this.ageGroup,
      occupation: occupation ?? this.occupation,
      interests: interests ?? this.interests,
      languages: languages ?? this.languages,
      lookingFor: lookingFor ?? this.lookingFor,
      favoriteActivities: favoriteActivities ?? this.favoriteActivities,
      walkTimes: walkTimes ?? this.walkTimes,
      walkPace: walkPace ?? this.walkPace,
      groupWalks: groupWalks ?? this.groupWalks,
      dogExperience: dogExperience ?? this.dogExperience,
      sharesAdvice: sharesAdvice ?? this.sharesAdvice,
      volunteerInterest: volunteerInterest ?? this.volunteerInterest,
      favoriteBreed: favoriteBreed ?? this.favoriteBreed,
      favoriteWalkSpot: favoriteWalkSpot ?? this.favoriteWalkSpot,
      instagram: instagram ?? this.instagram,
    );
  }

  /// Reads the fields from a `users/{uid}` doc. Missing, null, wrongly typed
  /// or unknown values are ignored (old profiles have none of them).
  factory OwnerDetails.fromMap(Map<String, dynamic>? data) {
    final doc = data ?? const <String, dynamic>{};
    return OwnerDetails(
      ageGroup: _key(doc[ageGroupField], OwnerDetailOptions.ageGroups),
      occupation: _text(doc[occupationField], occupationMaxLength),
      interests: _keys(doc[interestsField], OwnerDetailOptions.interests),
      languages: _keys(doc[languagesField], OwnerDetailOptions.languages),
      lookingFor: _keys(doc[lookingForField], OwnerDetailOptions.lookingFor),
      favoriteActivities: _keys(
        doc[favoriteActivitiesField],
        OwnerDetailOptions.activities,
      ),
      walkTimes: _keys(doc[walkTimesField], OwnerDetailOptions.walkTimes),
      walkPace: _key(doc[walkPaceField], OwnerDetailOptions.walkPaces),
      groupWalks: doc[groupWalksField] == true,
      dogExperience: _key(
        doc[dogExperienceField],
        OwnerDetailOptions.experienceLevels,
      ),
      sharesAdvice: doc[sharesAdviceField] == true,
      volunteerInterest: doc[volunteerInterestField] == true,
      favoriteBreed: _text(doc[favoriteBreedField], favoriteBreedMaxLength),
      favoriteWalkSpot: _text(
        doc[favoriteWalkSpotField],
        favoriteWalkSpotMaxLength,
      ),
      instagram: normalizeInstagram(doc[instagramField] as Object?) ?? '',
    );
  }

  /// Values to write; unset ones are null (the caller deletes those fields).
  Map<String, Object?> toMap() {
    String? text(String value) => value.trim().isEmpty ? null : value.trim();
    List<String>? list(List<String> value) =>
        value.isEmpty ? null : List.unmodifiable(value);
    return {
      ageGroupField: text(ageGroup),
      occupationField: text(occupation),
      interestsField: list(interests),
      languagesField: list(languages),
      lookingForField: list(lookingFor),
      favoriteActivitiesField: list(favoriteActivities),
      walkTimesField: list(walkTimes),
      walkPaceField: text(walkPace),
      groupWalksField: groupWalks ? true : null,
      dogExperienceField: text(dogExperience),
      sharesAdviceField: sharesAdvice ? true : null,
      volunteerInterestField: volunteerInterest ? true : null,
      favoriteBreedField: text(favoriteBreed),
      favoriteWalkSpotField: text(favoriteWalkSpot),
      instagramField: text(instagram),
    };
  }

  static String _key(Object? value, List<String> allowed) {
    final key = value is String ? value.trim() : '';
    return allowed.contains(key) ? key : '';
  }

  static List<String> _keys(Object? value, List<String> allowed) {
    if (value is! List) {
      return const [];
    }
    final picked = <String>{
      for (final item in value)
        if (item is String && allowed.contains(item.trim())) item.trim(),
    };
    // Keep the option order so the profile always reads the same.
    return [
      for (final key in allowed)
        if (picked.contains(key)) key,
    ];
  }

  static String _text(Object? value, int maxLength) {
    final text = value is String ? value.trim() : '';
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  static final RegExp _instagramUser = RegExp(r'^[A-Za-z0-9._]{1,30}$');
  static final RegExp _instagramUrl = RegExp(
    r'^(?:https?://)?(?:www\.|m\.)?(?:instagram\.com|instagr\.am)/([^/?#]+)/?(?:[?#].*)?$',
    caseSensitive: false,
  );

  /// Returns the bare username for `@name`, `name` or an
  /// `instagram.com/name` link; `''` for empty input; null when invalid.
  static String? normalizeInstagram(Object? raw) {
    var value = raw is String ? raw.trim() : '';
    if (value.isEmpty) {
      return '';
    }
    final link = _instagramUrl.firstMatch(value);
    if (link != null) {
      value = link.group(1)!;
    } else if (value.contains('/') || value.contains(':')) {
      return null;
    }
    if (value.startsWith('@')) {
      value = value.substring(1);
    }
    if (!_instagramUser.hasMatch(value) ||
        value.startsWith('.') ||
        value.endsWith('.') ||
        value.contains('..')) {
      return null;
    }
    const reserved = {'p', 'reel', 'reels', 'explore', 'stories', 'accounts'};
    if (reserved.contains(value.toLowerCase())) {
      return null;
    }
    return value.toLowerCase();
  }
}

/// Stable keys for the choice fields (labels: `ProfileStrings.ownerOption`).
abstract final class OwnerDetailOptions {
  static const List<String> ageGroups = [
    '18_24',
    '25_34',
    '35_44',
    '45_54',
    '55_64',
    '65_plus',
  ];

  static const List<String> interests = [
    'nature',
    'sport',
    'travel',
    'photography',
    'music',
    'books',
    'movies',
    'cooking',
    'art',
    'technology',
    'gaming',
    'volunteering',
  ];

  static const List<String> languages = [
    'sr',
    'en',
    'de',
    'hu',
    'ru',
    'fr',
    'it',
    'es',
    'sk',
    'ro',
    'other',
  ];

  static const List<String> lookingFor = [
    'walk_buddy',
    'dog_playdates',
    'new_friends',
  ];

  static const List<String> activities = [
    'walks',
    'parks',
    'hiking',
    'cafes',
    'training',
    'swimming',
    'dog_sports',
    'travel',
    'other',
  ];

  static const List<String> walkTimes = [
    'morning',
    'afternoon',
    'evening',
    'weekend',
  ];

  static const List<String> walkPaces = ['easy', 'moderate', 'active'];

  static const List<String> experienceLevels = [
    'beginner',
    'intermediate',
    'experienced',
  ];
}
