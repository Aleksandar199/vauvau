import 'partner.dart';

/// Partner shops. Everyone signed in may read them (names on coupons);
/// only the admin writes (firestore.rules).
abstract class PartnersRepository {
  Stream<List<Partner>> watchPartners();

  Stream<Partner?> watchPartner(String id);

  /// Empty [Partner.id] creates a new partner; returns its id.
  Future<String> savePartner(Partner partner);

  Future<void> setPartnerActive(String id, bool active);
}
