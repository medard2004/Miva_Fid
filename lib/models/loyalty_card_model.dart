import 'merchant_model.dart';
import 'user_model.dart';

class LoyaltyCardModel {
  const LoyaltyCardModel({
    required this.id,
    required this.clientId,
    required this.merchantId,
    this.stampsCount = 0,
    this.pointsTotal = 0,
    this.cashbackBalanceFcfa = 0,
    this.status = 'active',
    required this.createdAt,
    this.lastActivityAt,
    this.merchant,
    this.client,
    this.levelName,
    this.levelKey,
    this.levelPercentToNext,
    this.isMaxLevel = false,
    this.levelPosition,
    this.levelIconKey,
    this.cyclesCompleted = 0,
  });

  final String id;
  final String clientId;
  final String merchantId;
  final int stampsCount;
  final int pointsTotal;
  final double cashbackBalanceFcfa;
  final String status; // 'active' | 'reward_available'
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final MerchantModel? merchant;
  final UserModel? client;

  /// Niveau de fidélité du client (Bronze/Argent/Or...) — indépendant du
  /// cycle en cours, voir `LoyaltyCard::level` côté API. `null` si le
  /// programme n'a pas encore été résolu côté serveur.
  final String? levelName;

  /// Clé canonique du niveau (`bronze|silver|gold|platinum|custom`),
  /// dérivée côté serveur du libellé libre configuré par le marchand —
  /// source de vérité pour l'affichage et le filtrage, voir
  /// [LoyaltyLevel.fromKey]. `null` si pas de niveau résolu.
  final String? levelKey;
  final int? levelPercentToNext;
  final bool isMaxLevel;

  /// Rang 1-based du palier courant — pilote l'icône fixe pour les
  /// positions 1 à 5 (voir `LoyaltyLevel.forPosition`). `null` si pas de
  /// niveau résolu, ou si aucun palier n'est encore atteint.
  final int? levelPosition;

  /// Icône choisie par le marchand pour un palier custom (position > 5,
  /// voir `TierIconPalette`) — `null` pour les positions 1 à 5.
  final String? levelIconKey;

  /// Nombre de cycles complets terminés à vie (programme bouclé N fois) —
  /// sert au filtrage marchand (« a déjà terminé le programme »).
  final int cyclesCompleted;

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
    final level = json['level'] as Map<String, dynamic>?;
    return LoyaltyCardModel(
      id: json['id'].toString(),
      clientId: json['client_id'].toString(),
      merchantId: json['restaurant_id']?.toString() ??
          json['merchant_id']?.toString() ??
          '',
      stampsCount: _asInt(json['stamps_current']),
      pointsTotal: _asInt(json['points_total']),
      cashbackBalanceFcfa:
          double.tryParse(json['cashback_balance_fcfa']?.toString() ?? '') ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
      lastActivityAt:
          DateTime.tryParse(json['last_activity_at']?.toString() ?? ''),
      levelName: level?['name'] as String?,
      levelKey: level?['key'] as String?,
      levelPercentToNext: level == null ? null : _asInt(level['percent_to_next']),
      isMaxLevel: level?['is_max_level'] as bool? ?? false,
      levelPosition: level == null ? null : (level['position'] as num?)?.toInt(),
      levelIconKey: level?['icon_key'] as String?,
      cyclesCompleted: _asInt(json['cycles_completed']),
      client: client == null
          ? null
          : UserModel(
              id: client['id'].toString(),
              name: client['name'] as String? ?? 'Client',
              phone: client['phone'] as String?,
              role: 'client',
              avatarUrl: client['avatar_url'] as String?,
              createdAt:
                  DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                      DateTime.now(),
            ),
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
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
    double? cashbackBalanceFcfa,
    String? status,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    MerchantModel? merchant,
    UserModel? client,
    String? levelName,
    String? levelKey,
    int? levelPercentToNext,
    bool? isMaxLevel,
    int? levelPosition,
    String? levelIconKey,
    int? cyclesCompleted,
  }) {
    return LoyaltyCardModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      merchantId: merchantId ?? this.merchantId,
      stampsCount: stampsCount ?? this.stampsCount,
      pointsTotal: pointsTotal ?? this.pointsTotal,
      cashbackBalanceFcfa: cashbackBalanceFcfa ?? this.cashbackBalanceFcfa,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      merchant: merchant ?? this.merchant,
      client: client ?? this.client,
      levelName: levelName ?? this.levelName,
      levelKey: levelKey ?? this.levelKey,
      levelPercentToNext: levelPercentToNext ?? this.levelPercentToNext,
      isMaxLevel: isMaxLevel ?? this.isMaxLevel,
      levelPosition: levelPosition ?? this.levelPosition,
      levelIconKey: levelIconKey ?? this.levelIconKey,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
    );
  }
}
