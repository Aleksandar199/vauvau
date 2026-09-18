enum DogGender {
  female,
  male,
  unknown;

  String get firestoreValue => name;
}

enum DogSize {
  small,
  medium,
  large,
  xlarge;

  String get firestoreValue => name;
}

enum DogEnergyLevel {
  low,
  moderate,
  high;

  String get firestoreValue => name;
}

enum DogTemperament {
  friendly,
  playful,
  calm,
  shy,
  protective,
  social;

  String get firestoreValue => name;
}
