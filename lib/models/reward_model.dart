class RewardModel {
  const RewardModel({
    required this.id,
    required this.cardId,
    required this.clientId,
    required this.merchantId,
    required this.unlockedAt,
    this.redeemedAt,
    this.expiresAt,
    this.status = 'available',
    required this.redemptionCode,
  });

  final String id;
  final String cardId;
  final String clientId;
  final String merchantId;
  final DateTime unlockedAt;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;
  final String status; // 'available' | 'used' | 'expired'
  final String redemptionCode;

  bool get isAvailable => status == 'available';
  bool get isUsed => status == 'used';
  bool get isExpired =>
      status == 'expired' ||
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String,
      cardId: json['card_id'] as String,
      clientId: json['client_id'] as String,
      merchantId: json['merchant_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.parse(json['redeemed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      status: json['status'] as String? ?? 'available',
      redemptionCode: json['redemption_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_id': cardId,
      'client_id': clientId,
      'merchant_id': merchantId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'redeemed_at': redeemedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'status': status,
      'redemption_code': redemptionCode,
    };
  }
}
