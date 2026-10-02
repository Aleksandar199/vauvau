import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Thrown when an upload or Firestore write fails due to connectivity.
class NetworkFailure implements Exception {
  const NetworkFailure([this.message = AppStrings.networkProblem]);

  final String message;

  @override
  String toString() => message;
}

bool isNetworkFailure(Object error) {
  if (error is NetworkFailure) {
    return true;
  }
  if (error is TimeoutException) {
    return true;
  }
  if (error is FirebaseException) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'network-request-failed';
  }
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('timed out') ||
      text.contains('network-request-failed');
}

String networkOrFallbackMessage(
  Object error, {
  String fallback = AppStrings.networkProblem,
}) {
  return isNetworkFailure(error) ? AppStrings.networkProblem : fallback;
}

void showNetworkErrorSnackBar(
  BuildContext context,
  Object error, {
  String fallback = AppStrings.networkProblem,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(networkOrFallbackMessage(error, fallback: fallback))),
  );
}
