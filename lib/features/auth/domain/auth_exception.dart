enum AuthErrorCode {
  invalidEmail,
  wrongPassword,
  userNotFound,
  weakPassword,
  emailInUse,
  cancelled,
  network,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.code, [this.message = 'Prijava nije uspela.']);

  final AuthErrorCode code;
  final String message;

  @override
  String toString() => message;
}
