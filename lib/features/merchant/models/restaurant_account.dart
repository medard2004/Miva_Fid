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
  final String? country;
  final String? description;
  final String? logoUrl;
  final String? whatsapp;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final String? qrToken;
  final String? shortCode;
  final double? latitude;
  final double? longitude;

  /// Vrai une fois le step1 (nom + catégorie) renseigné côté backend.
  final bool hasBusinessInfo;

  /// Vrai une fois le restaurant positionné sur la carte (étape localisation).
  final bool hasLocation;

  /// Vrai une fois le programme de fidélité créé (step2/step3) — seul
  /// signal fiable d'un onboarding réellement terminé ([hasBusinessInfo]
  /// ne couvre que step1).
  final bool hasLoyaltyProgram;

  /// `type` du programme (`stamps`/`points`/`spend`), `null` tant que
  /// l'onboarding n'a pas atteint step2.
  final String? loyaltyType;

  /// Config du programme telle qu'enregistrée à l'onboarding (couleurs,
  /// objectif, style de tampon, motif de carte, logo).
  final Map<String, dynamic> loyaltyConfig;

  /// Slug de la formule d'abonnement (`free`, `pro`...).
  final String plan;

  /// Crédit SMS restant, décrémenté à chaque campagne envoyée.
  final int smsCredits;

  const RestaurantAccount({
    required this.id,
    required this.uuid,
    this.name,
    this.category,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.description,
    this.logoUrl,
    this.whatsapp,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.qrToken,
    this.shortCode,
    this.latitude,
    this.longitude,
    this.hasBusinessInfo = false,
    this.hasLocation = false,
    this.hasLoyaltyProgram = false,
    this.loyaltyType,
    this.loyaltyConfig = const {},
    this.plan = 'free',
    this.smsCredits = 0,
  });

  factory RestaurantAccount.fromJson(Map<String, dynamic> json) {
    final program = json['loyalty_program'] as Map<String, dynamic>?;
    return RestaurantAccount(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString() ?? '',
      name: json['name'] as String?,
      category: json['category'] as String?,
      email: json['email']?.toString() ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      whatsapp: json['whatsapp'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      tiktok: json['tiktok'] as String?,
      qrToken: json['qr_token'] as String?,
      shortCode: json['short_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hasBusinessInfo: json['has_business_info'] as bool? ?? false,
      hasLocation: json['has_location'] as bool? ?? false,
      hasLoyaltyProgram: json['has_loyalty_program'] as bool? ?? false,
      loyaltyType: program?['type'] as String?,
      loyaltyConfig:
          (program?['config'] as Map?)?.cast<String, dynamic>() ?? const {},
      plan: json['plan'] as String? ?? 'free',
      smsCredits: json['sms_credits'] as int? ?? 0,
    );
  }
}
