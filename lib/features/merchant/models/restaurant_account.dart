/// Compte marchand — construit depuis la charge utile `restaurant` renvoyée
/// par l'API Laravel (`RestaurantAuthController::restaurantData()`).
class RestaurantAccount {
  final String id;
  final String uuid;
  final String? name;
  final String? category;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? description;
  final String? logoUrl;
  final String? whatsapp;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final String? qrToken;

  /// Vrai une fois le step1 (nom + catégorie) renseigné côté backend.
  final bool hasBusinessInfo;

  const RestaurantAccount({
    required this.id,
    required this.uuid,
    this.name,
    this.category,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.description,
    this.logoUrl,
    this.whatsapp,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.qrToken,
    this.hasBusinessInfo = false,
  });

  factory RestaurantAccount.fromJson(Map<String, dynamic> json) {
    return RestaurantAccount(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString() ?? '',
      name: json['name'] as String?,
      category: json['category'] as String?,
      email: json['email']?.toString() ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      whatsapp: json['whatsapp'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      tiktok: json['tiktok'] as String?,
      qrToken: json['qr_token'] as String?,
      hasBusinessInfo: json['has_business_info'] as bool? ?? false,
    );
  }
}
