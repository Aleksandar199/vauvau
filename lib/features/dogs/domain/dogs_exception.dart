class DogsException implements Exception {
  const DogsException([this.message = 'Could not save the dog profile.']);

  final String message;

  @override
  String toString() => message;
}
