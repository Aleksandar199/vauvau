/// `partners/{id}` – a shop that accepts VauVau coupons. Admin-managed.
/// Coupons (`reward_coupons.partnerId`), their claims (`coupon_claims.partnerId`)
/// and the shop's accounts (`users/{uid}.role == 'partner'` + `partnerId`)
/// point here. A deactivated partner's accounts can no longer redeem.
class Partner {
  const Partner({
    required this.id,
    required this.name,
    this.isActive = true,
    this.city = '',
    this.address = '',
  });

  factory Partner.fromMap(String id, Map<String, dynamic> data) => Partner(
        id: id,
        name: (data['name'] as String? ?? '').trim(),
        isActive: data['isActive'] == true,
        city: (data['city'] as String? ?? '').trim(),
        address: (data['address'] as String? ?? '').trim(),
      );

  final String id;
  final String name;
  final bool isActive;
  final String city;
  final String address;

  Map<String, Object?> toMap() => {
        'name': name,
        'isActive': isActive,
        'city': city,
        'address': address,
      };

  Partner copyWith({String? name, bool? isActive, String? city, String? address}) {
    return Partner(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      city: city ?? this.city,
      address: address ?? this.address,
    );
  }
}
