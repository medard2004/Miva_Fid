/// Palier de niveau de fidélité configurable par le marchand — indépendant
/// des paliers de récompense ([RewardTier]). `threshold` signifie "cycles
/// complétés à vie" pour Tampons/Achats, "cashback cumulé à vie (FCFA)"
/// pour Cashback.
class LoyaltyLevel {
  final String name;
  final int threshold;

  const LoyaltyLevel({
    required this.name,
    required this.threshold,
  });

  LoyaltyLevel copyWith({
    String? name,
    int? threshold,
  }) {
    return LoyaltyLevel(
      name: name ?? this.name,
      threshold: threshold ?? this.threshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'threshold': threshold,
    };
  }

  factory LoyaltyLevel.fromJson(Map<String, dynamic> json) {
    return LoyaltyLevel(
      name: (json['name'] as String?) ?? '',
      threshold: (json['threshold'] as num?)?.toInt() ?? 0,
    );
  }
}
