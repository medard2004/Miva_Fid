/// Palier unifié : objectif (seuil) + niveau (nom libre du marchand,
/// `null`/ignoré si un seul palier) + récompense. Remplace `RewardTier` et
/// `LoyaltyLevel`, auparavant deux systèmes indépendants.
class ProgramTier {
  final int goal;

  /// Nom du niveau — libre, masqué côté UI si un seul palier est configuré.
  final String? levelName;
  final String rewardDescription;

  /// Durée de validité (jours) propre à ce palier — `null` = utilise la
  /// valeur par défaut du programme (`reward_validity_days`).
  final int? validityDays;

  const ProgramTier({
    required this.goal,
    this.levelName,
    required this.rewardDescription,
    this.validityDays,
  });

  ProgramTier copyWith({
    int? goal,
    String? levelName,
    bool clearLevelName = false,
    String? rewardDescription,
    int? validityDays,
    bool clearValidityDays = false,
  }) {
    return ProgramTier(
      goal: goal ?? this.goal,
      levelName: clearLevelName ? null : (levelName ?? this.levelName),
      rewardDescription: rewardDescription ?? this.rewardDescription,
      validityDays:
          clearValidityDays ? null : (validityDays ?? this.validityDays),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'level_name': levelName,
      'reward_description': rewardDescription,
      if (validityDays != null) 'validity_days': validityDays,
    };
  }

  factory ProgramTier.fromJson(Map<String, dynamic> json) {
    return ProgramTier(
      goal: (json['goal'] as num?)?.toInt() ?? 10,
      levelName: json['level_name'] as String?,
      rewardDescription: (json['reward_description'] as String?) ?? '',
      validityDays: (json['validity_days'] as num?)?.toInt(),
    );
  }
}
