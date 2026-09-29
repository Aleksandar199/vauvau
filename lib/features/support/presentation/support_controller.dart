import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/firestore_support_repository.dart';
import '../data/local_support_repository.dart';
import '../domain/admin_feedback.dart';
import '../domain/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreSupportRepository(firestore: FirebaseFirestore.instance);
  }
  return LocalSupportRepository();
});

class SupportController {
  SupportController(this._ref);

  final Ref _ref;

  Future<void> sendFeedback({
    required String category,
    required String subject,
    required String message,
  }) async {
    final user = _ref.read(authStateProvider).asData?.value;
    final authUser = isFirebaseReady ? FirebaseAuth.instance.currentUser : null;
    var uid = (user?.uid ?? '').trim();
    if (uid.isEmpty) {
      uid = (authUser?.uid ?? '').trim();
    }
    if (uid.isEmpty) {
      if (isFirebaseReady) {
        throw StateError('Morate biti prijavljeni.');
      }
      uid = 'local-user';
    }
    await _ref.read(supportRepositoryProvider).submitFeedback(
          AdminFeedback(
            userId: uid,
            userName: _firstNonEmpty([
              user?.displayName,
              authUser?.displayName,
              _ref.read(profileControllerProvider).ownerName,
            ], fallback: 'Korisnik'),
            userEmail: _firstNonEmpty([user?.email, authUser?.email]),
            category: category,
            subject: subject.trim(),
            message: message.trim(),
          ),
        );
  }

  String _firstNonEmpty(List<String?> values, {String fallback = ''}) {
    for (final value in values) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }
}

final supportControllerProvider = Provider<SupportController>(
  SupportController.new,
);
