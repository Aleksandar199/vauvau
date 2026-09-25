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

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchUser();
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).asData?.value?.isAdmin ?? false;
});
