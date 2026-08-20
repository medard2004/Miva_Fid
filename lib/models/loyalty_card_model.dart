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

  /// Construit une carte depuis `GET /merchant/clients*`.
  ///
  /// Le backend expose `stamps_current` (extrait du JSON `progress`) et
  /// imbrique le client sous `client` — les identifiants arrivent en string
  /// pour rester compatibles avec l'ancien format.
  factory LoyaltyCardModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    return LoyaltyCardModel(
      id: json['id'].toString(),
      clientId: json['client_id'].toString(),
      merchantId: json['restaurant_id']?.toString() ??
          json['merchant_id']?.toString() ??
          '',
      stampsCount: json['stamps_current'] as int? ?? 0,
      pointsTotal: json['points_total'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
      client: client == null
          ? null
          : UserModel(
              id: client['id'].toString(),
              name: client['name'] as String? ?? 'Client',
              phone: client['phone'] as String?,
              role: 'client',
              createdAt:
                  DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                      DateTime.now(),
            ),
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
