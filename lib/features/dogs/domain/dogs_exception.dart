import '../../../core/constants/app_strings.dart';

class DogsException implements Exception {
  DogsException([String? message])
      : message = message ?? AppStrings.dogSaveFailed;

  final String message;

  @override
  String toString() => message;
}
