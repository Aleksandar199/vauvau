import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../domain/blocked_users_repository.dart';

class FirestoreBlockedUsersRepository implements BlockedUsersRepository {
  FirestoreBlockedUsersRepository(this._firestore, this._currentUserId);

  final FirebaseFirestore _firestore;
  final String _currentUserId;

  CollectionReference<Map<String, dynamic>> get _blocked => _firestore
      .collection('users')
      .doc(_currentUserId)
      .collection('blocked_users');

  @override
  Stream<Set<String>> watchBlocked() {
    if (_currentUserId.isEmpty) {
      return Stream.value(const <String>{});
    }
    return FirestoreAuthGuard.guardedStream<Set<String>>(
      label: 'blocked.watch',
      empty: const <String>{},
      create: () => _blocked.snapshots().map(
            (snapshot) => {for (final doc in snapshot.docs) doc.id},
          ),
    );
  }

  @override
  Future<void> block(String userId) async {
    if (_currentUserId.isEmpty || userId.isEmpty) {
      return;
    }
    await _blocked.doc(userId).set({
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unblock(String userId) async {
    if (_currentUserId.isEmpty || userId.isEmpty) {
      return;
    }
    await _blocked.doc(userId).delete();
  }
}
