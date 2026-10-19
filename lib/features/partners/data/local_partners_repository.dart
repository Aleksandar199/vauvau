import 'dart:async';

import '../domain/partner.dart';
import '../domain/partners_repository.dart';

/// In-memory partners (local runs and tests).
class LocalPartnersRepository implements PartnersRepository {
  LocalPartnersRepository({List<Partner>? partners})
      : _partners = {for (final p in partners ?? const <Partner>[]) p.id: p};

  final Map<String, Partner> _partners;
  final _changes = StreamController<void>.broadcast();
  var _seq = 0;

  void dispose() => _changes.close();

  List<Partner> _sorted() => _partners.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Stream<List<Partner>> watchPartners() async* {
    yield _sorted();
    yield* _changes.stream.map((_) => _sorted());
  }

  @override
  Stream<Partner?> watchPartner(String id) async* {
    yield _partners[id];
    yield* _changes.stream.map((_) => _partners[id]);
  }

  @override
  Future<String> savePartner(Partner partner) async {
    final id = partner.id.isEmpty ? 'partner${++_seq}' : partner.id;
    _partners[id] = Partner(
      id: id,
      name: partner.name,
      isActive: partner.isActive,
      city: partner.city,
      address: partner.address,
    );
    _changes.add(null);
    return id;
  }

  @override
  Future<void> setPartnerActive(String id, bool active) async {
    final p = _partners[id];
    if (p == null) return;
    _partners[id] = p.copyWith(isActive: active);
    _changes.add(null);
  }
}
