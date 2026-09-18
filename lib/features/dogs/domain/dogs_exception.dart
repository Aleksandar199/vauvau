import '../../../core/constants/app_strings.dart';

class DogsException implements Exception {
  const DogsException([this.message = AppStrings.dogSaveFailed]);

  final String message;

  @override
  String toString() => message;
}
