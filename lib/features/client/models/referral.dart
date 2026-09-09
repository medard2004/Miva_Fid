enum ReferralStatus { pending, validated }

/// Un parrainage fait par le client — voir `GET /api/referrals`
/// (`ReferralController::mine`). Reste [ReferralStatus.pending] tant que le
/// filleul n'a pas effectué sa première opération de fidélité ; la
/// récompense n'apparaît qu'une fois [ReferralStatus.validated].
class Referral {
  final String id;
  final String restaurantName;
  final String referredName;
  final ReferralStatus status;
  final DateTime? validatedAt;
  final String? rewardTitle;
  final DateTime? createdAt;

  const Referral({
    required this.id,
    required this.restaurantName,
    required this.referredName,
    required this.status,
    this.validatedAt,
    this.rewardTitle,
    this.createdAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'] as Map<String, dynamic>?;
    final referredClient = json['referred_client'] as Map<String, dynamic>?;
    final reward = json['reward'] as Map<String, dynamic>?;

    return Referral(
      id: json['id'].toString(),
      restaurantName: restaurant?['name'] as String? ?? '',
      referredName: referredClient?['first_name'] as String? ?? '',
      status: json['status'] == 'validated'
          ? ReferralStatus.validated
          : ReferralStatus.pending,
      validatedAt: json['validated_at'] != null
          ? DateTime.tryParse(json['validated_at'].toString())
          : null,
      rewardTitle: reward?['title'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
