import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Thrown when an upload or Firestore write fails due to connectivity.
class NetworkFailure implements Exception {
  NetworkFailure([String? message])
      : message = message ?? AppStrings.networkProblem;

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
  String? fallback,
}) {
  if (isNetworkFailure(error)) {
    return AppStrings.networkProblem;
  }
  if (error is StateError) {
    final message = error.message.trim();
    if (message.isNotEmpty) {
      return message;
    }
  }
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return fallback ?? AppStrings.networkProblem;
    }
    final message = (error.message ?? '').trim();
    if (message.isNotEmpty) {
      return '${error.code}: $message';
    }
    return error.code;
  }
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isNotEmpty && text != error.runtimeType.toString()) {
    return text;
  }
  return fallback ?? AppStrings.networkProblem;
}

void showNetworkErrorSnackBar(
  BuildContext context,
  Object error, {
  String? fallback,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(networkOrFallbackMessage(error, fallback: fallback)),
      duration: const Duration(seconds: 5),
    ),
  );
}
