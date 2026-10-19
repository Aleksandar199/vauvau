import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../rewards/domain/rewards_models.dart';
import '../../rewards/presentation/rewards_controller.dart';
import '../data/firestore_partners_repository.dart';
import '../data/local_partners_repository.dart';
import '../domain/partner.dart';
import '../domain/partners_repository.dart';

final partnersRepositoryProvider = Provider<PartnersRepository>((ref) {
  if (isFirebaseReady) {
    return FirestorePartnersRepository(FirebaseFirestore.instance);
  }
  final repo = LocalPartnersRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// All partners (admin: coupon form, role assignment, partners list).
final partnersProvider = StreamProvider<List<Partner>>((ref) {
  return ref.watch(partnersRepositoryProvider).watchPartners();
});

/// The signed-in partner account's shop (null for everyone else).
final currentPartnerProvider = StreamProvider<Partner?>((ref) {
  final id = ref.watch(partnerIdProvider);
  if (id.isEmpty) return Stream.value(null);
  return ref.watch(partnersRepositoryProvider).watchPartner(id);
});

/// Latest claims of the signed-in partner's coupons.
final partnerClaimsProvider = StreamProvider.autoDispose<List<CouponClaim>>((
  ref,
) {
  final id = ref.watch(partnerIdProvider);
  if (id.isEmpty) return Stream.value(const []);
  return ref.watch(rewardsRepositoryProvider).watchPartnerClaims(id);
});
