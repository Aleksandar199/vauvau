import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/firebase/firebase_status.dart';
import '../data/auth_repository_impl.dart';
import '../data/firebase_auth_datasource.dart';
import '../data/local_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!isFirebaseReady) {
    return LocalAuthRepository(user: localDemoUser);
  }
  return AuthRepositoryImpl(
    FirebaseAuthDatasource(
      FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(scopes: const ['email', 'profile']),
    ),
    firestore: FirebaseFirestore.instance,
  );
});

/// Set to `true` at the start of logout so AuthGate shows login immediately,
/// even while Firebase / route cleanup is still finishing.
class SessionSignedOut extends Notifier<bool> {
  @override
  bool build() => false;

  void setSignedOut(bool value) => state = value;
}

final sessionSignedOutProvider =
    NotifierProvider<SessionSignedOut, bool>(SessionSignedOut.new);

final authStateProvider = StreamProvider<AppUser?>((ref) {
  if (ref.watch(sessionSignedOutProvider)) {
    return Stream<AppUser?>.value(null);
  }
  return ref.watch(authRepositoryProvider).watchUser();
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).asData?.value?.isAdmin ?? false;
});

/// `partners/{id}` of a signed-in partner shop; empty for everyone else.
final partnerIdProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  return user != null && user.isPartner ? user.partnerId : '';
});

final isPartnerProvider = Provider<bool>((ref) {
  return ref.watch(partnerIdProvider).isNotEmpty;
});

final isSuspendedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).asData?.value?.isSuspended ?? false;
});
