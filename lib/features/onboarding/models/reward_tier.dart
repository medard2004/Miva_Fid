class RewardTier {
  final int goal;
  final String rewardDescription;

  /// Durée de validité (jours) propre à ce palier — `null` = utilise la
  /// valeur par défaut du programme (`reward_validity_days`), elle aussi
  /// optionnelle. Voir `RewardTierService::validityDaysFor` côté API.
  final int? validityDays;

  const RewardTier({
    required this.goal,
    required this.rewardDescription,
    this.validityDays,
  });

  RewardTier copyWith({
    int? goal,
    String? rewardDescription,
    int? validityDays,
    bool clearValidityDays = false,
  }) {
    return RewardTier(
      goal: goal ?? this.goal,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      validityDays:
          clearValidityDays ? null : (validityDays ?? this.validityDays),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'reward_description': rewardDescription,
      if (validityDays != null) 'validity_days': validityDays,
    };
  }

  factory RewardTier.fromJson(Map<String, dynamic> json) {
    return RewardTier(
      goal: (json['goal'] as num?)?.toInt() ?? 10,
      rewardDescription: (json['reward_description'] as String?) ?? '',
      validityDays: (json['validity_days'] as num?)?.toInt(),
    );
  }
}
