import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../domain/partner.dart';
import '../domain/partners_repository.dart';

class FirestorePartnersRepository implements PartnersRepository {
  FirestorePartnersRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _partners =>
      _db.collection('partners');

  @override
  Stream<List<Partner>> watchPartners() {
    return FirestoreAuthGuard.guardedStream<List<Partner>>(
      label: 'partners',
      empty: const [],
      create: () => _partners.snapshots().map((snap) {
        final items = [
          for (final doc in snap.docs) Partner.fromMap(doc.id, doc.data()),
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return items;
      }),
    );
  }

  @override
  Stream<Partner?> watchPartner(String id) {
    if (id.isEmpty) return Stream.value(null);
    return FirestoreAuthGuard.guardedStream<Partner?>(
      label: 'partners.one',
      empty: null,
      create: () => _partners.doc(id).snapshots().map(
            (doc) => doc.exists ? Partner.fromMap(doc.id, doc.data()!) : null,
          ),
    );
  }

  @override
  Future<String> savePartner(Partner partner) async {
    if (partner.id.isEmpty) {
      final ref = _partners.doc();
      await ref.set({
        ...partner.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    }
    await _partners.doc(partner.id).set({
      ...partner.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return partner.id;
  }

  @override
  Future<void> setPartnerActive(String id, bool active) {
    return _partners.doc(id).update({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
