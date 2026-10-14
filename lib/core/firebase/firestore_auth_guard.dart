import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crash/crash_reporting.dart';
import '../../features/auth/presentation/auth_providers.dart';
import 'firebase_status.dart';

/// Soft-fail helpers so Firestore `permission-denied` never becomes a fatal crash
/// when Auth is still restoring or the session has ended.
abstract final class FirestoreAuthGuard {
  static User? get currentUser =>
      isFirebaseReady ? FirebaseAuth.instance.currentUser : null;

  static bool get isSignedIn => currentUser != null;

  /// Ensures a signed-in user exists and the ID token is available for Rules.
  static Future<User?> ensureReady({bool forceRefresh = false}) async {
    if (!isFirebaseReady) {
      return null;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    try {
      await user.getIdToken(forceRefresh);
    } catch (error, stack) {
      debugPrint('FirestoreAuthGuard.getIdToken failed: $error');
      unawaited(
        CrashReporting.recordError(
          error,
          stack,
          reason: 'firestore_auth_token',
        ),
      );
      // Token refresh failed — still return the user; callers may retry.
    }
    return FirebaseAuth.instance.currentUser;
  }

  static bool isPermissionDenied(Object error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }
    // FlutterFire EventChannel / pigeon often surfaces PlatformException.
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').toLowerCase();
      final details = '${error.details}'.toLowerCase();
      final deniedText = message.contains('permission-denied') ||
          message.contains('permission_denied') ||
          message.contains('missing or insufficient permissions') ||
          details.contains('permission-denied') ||
          details.contains('permission_denied') ||
          details.contains('missing or insufficient permissions');
      return code == 'permission-denied' ||
          deniedText ||
          (code == 'firebase_firestore' && deniedText);
    }
    final text = error.toString().toLowerCase();
    return text.contains('permission-denied') ||
        text.contains('permission_denied') ||
        text.contains('missing or insufficient permissions');
  }

  /// Soft-failable production noise — never mark these as fatal Crashlytics crashes.
  static bool isSoftFailError(Object error) {
    if (isPermissionDenied(error)) {
      return true;
    }
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('network is unreachable') ||
        text.contains('failed host lookup') ||
        text.contains('connection abort') ||
        text.contains('connection reset') ||
        text.contains('software caused connection abort') ||
        text.contains('connection attempt cancelled');
  }

  static void logPermissionDenied(
    Object error,
    StackTrace? stack, {
    String? label,
  }) {
    final tag = label == null || label.isEmpty ? 'firestore' : label;
    debugPrint('$tag permission-denied: $error');
    unawaited(
      CrashReporting.recordError(
        error,
        stack,
        fatal: false,
        reason: '$tag:permission-denied',
      ),
    );
    unawaited(CrashReporting.log('$tag permission-denied'));
  }

  /// Runs a one-shot Firestore read/write after Auth is ready.
  /// Returns [fallback] when signed out or on `permission-denied`.
  static Future<T> run<T>({
    required Future<T> Function() action,
    required T fallback,
    String label = 'firestore',
  }) async {
    final user = await ensureReady();
    if (user == null) {
      return fallback;
    }
    try {
      return await action();
    } catch (error, stack) {
      if (isPermissionDenied(error)) {
        logPermissionDenied(error, stack, label: label);
        return fallback;
      }
      rethrow;
    }
  }

  /// Wraps a Firestore snapshot stream: waits for Auth, soft-fails on deny.
  static Stream<T> guardedStream<T>({
    required Stream<T> Function() create,
    required T empty,
    String label = 'firestore',
  }) {
    late StreamController<T> controller;
    StreamSubscription<T>? sub;
    var cancelled = false;

    controller = StreamController<T>(
      onListen: () async {
        final user = await ensureReady();
        if (cancelled) {
          return;
        }
        if (user == null) {
          controller.add(empty);
          await controller.close();
          return;
        }
        sub = create().listen(
          controller.add,
          onError: (Object error, StackTrace stack) {
            // Soft-fail all stream errors (permission-denied, offline,
            // EventChannel) so listeners never become fatal crashes.
            if (isPermissionDenied(error)) {
              logPermissionDenied(error, stack, label: label);
            } else {
              debugPrint('$label stream error: $error');
              unawaited(
                CrashReporting.recordError(
                  error,
                  stack,
                  fatal: false,
                  reason: '$label:stream',
                ),
              );
            }
            if (!controller.isClosed) {
              controller.add(empty);
            }
          },
          onDone: () {
            if (!controller.isClosed) {
              controller.close();
            }
          },
          cancelOnError: false,
        );
      },
      onCancel: () async {
        cancelled = true;
        await sub?.cancel();
        sub = null;
      },
    );

    return controller.stream;
  }
}

/// True only when Riverpod auth has a user **and** FirebaseAuth has an ID token.
/// Watch this before opening Discover / Chat / Moments Firestore listeners.
final firestoreAuthReadyProvider = FutureProvider<bool>((ref) async {
  final signedOut = ref.watch(sessionSignedOutProvider);
  if (signedOut || !isFirebaseReady) {
    return false;
  }
  final appUser = ref.watch(authStateProvider).asData?.value;
  if (appUser == null || appUser.uid.isEmpty) {
    return false;
  }
  final user = await FirestoreAuthGuard.ensureReady();
  return user != null && user.uid == appUser.uid;
});
