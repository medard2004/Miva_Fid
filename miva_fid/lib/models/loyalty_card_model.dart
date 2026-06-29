import 'merchant_model.dart';
import 'user_model.dart';

class LoyaltyCardModel {
  const LoyaltyCardModel({
    required this.id,
    required this.clientId,
    required this.merchantId,
    this.stampsCount = 0,
    this.pointsTotal = 0,
    this.status = 'active',
    required this.createdAt,
    this.merchant,
    this.client,
  });

  final String id;
  final String clientId;
  final String merchantId;
  final int stampsCount;
  final int pointsTotal;
  final String status; // 'active' | 'reward_available'
  final DateTime createdAt;
  final MerchantModel? merchant;
  final UserModel? client;

  bool get hasRewardAvailable => status == 'reward_available';

  double progressRatio(int stampsRequired) {
    if (stampsRequired == 0) return 0;
    return (stampsCount / stampsRequired).clamp(0.0, 1.0);
  }

  int stampsRemaining(int stampsRequired) {
    final rem = stampsRequired - stampsCount;
    return rem < 0 ? 0 : rem;
  }

  factory LoyaltyCardModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyCardModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      merchantId: json['merchant_id'] as String,
      stampsCount: json['stamps_count'] as int? ?? 0,
      pointsTotal: json['points_total'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      merchant: json['merchants'] != null
          ? MerchantModel.fromJson(json['merchants'] as Map<String, dynamic>)
          : null,
      client: json['users'] != null
          ? UserModel.fromJson(json['users'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'merchant_id': merchantId,
      'stamps_count': stampsCount,
      'points_total': pointsTotal,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LoyaltyCardModel copyWith({
    String? id,
    String? clientId,
    String? merchantId,
    int? stampsCount,
    int? pointsTotal,
    String? status,
    DateTime? createdAt,
    MerchantModel? merchant,
    UserModel? client,
  }) {
    return LoyaltyCardModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      merchantId: merchantId ?? this.merchantId,
      stampsCount: stampsCount ?? this.stampsCount,
      pointsTotal: pointsTotal ?? this.pointsTotal,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      merchant: merchant ?? this.merchant,
      client: client ?? this.client,
    );
  }
}
