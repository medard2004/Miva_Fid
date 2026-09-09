/// Palier unifié : objectif (seuil) + niveau (nom libre du marchand,
/// `null`/ignoré si un seul palier) + récompense. Remplace `RewardTier` et
/// `LoyaltyLevel`, auparavant deux systèmes indépendants.
class ProgramTier {
  final int goal;

  /// Nom du niveau — libre, masqué côté UI si un seul palier est configuré.
  /// Pour les paliers en position 1-5 d'un programme multi-palier, ce champ
  /// est toujours le nom canonique imposé (voir `LoyaltyLevel.forPosition`),
  /// non éditable par le marchand.
  final String? levelName;
  final String rewardDescription;

  /// Durée de validité (jours) propre à ce palier — `null` = utilise la
  /// valeur par défaut du programme (`reward_validity_days`).
  final int? validityDays;

  /// `false` = récompense "surprise" : le client voit que ce palier existe
  /// mais pas son contenu tant qu'il ne l'a pas débloqué. Réglable palier
  /// par palier — un programme peut cacher un seul palier et laisser les
  /// autres visibles.
  final bool revealReward;

  /// Icône choisie par le marchand pour un palier au-delà du 5ᵉ (voir
  /// `TierIconPalette`) — toujours `null` pour les 5 premiers, dont l'icône
  /// est fixe (`LoyaltyLevel.forPosition`), jamais stockée.
  final String? iconKey;

  const ProgramTier({
    required this.goal,
    this.levelName,
    required this.rewardDescription,
    this.validityDays,
    this.revealReward = true,
    this.iconKey,
  });

  ProgramTier copyWith({
    int? goal,
    String? levelName,
    bool clearLevelName = false,
    String? rewardDescription,
    int? validityDays,
    bool clearValidityDays = false,
    bool? revealReward,
    String? iconKey,
    bool clearIconKey = false,
  }) {
    return ProgramTier(
      goal: goal ?? this.goal,
      levelName: clearLevelName ? null : (levelName ?? this.levelName),
      rewardDescription: rewardDescription ?? this.rewardDescription,
      validityDays:
          clearValidityDays ? null : (validityDays ?? this.validityDays),
      revealReward: revealReward ?? this.revealReward,
      iconKey: clearIconKey ? null : (iconKey ?? this.iconKey),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'level_name': levelName,
      'reward_description': rewardDescription,
      if (validityDays != null) 'validity_days': validityDays,
      'reveal_reward': revealReward,
      if (iconKey != null) 'icon_key': iconKey,
    };
  }

  factory ProgramTier.fromJson(Map<String, dynamic> json) {
    return ProgramTier(
      goal: (json['goal'] as num?)?.toInt() ?? 10,
      levelName: json['level_name'] as String?,
      rewardDescription: (json['reward_description'] as String?) ?? '',
      validityDays: (json['validity_days'] as num?)?.toInt(),
      revealReward: json['reveal_reward'] as bool? ?? true,
      iconKey: json['icon_key'] as String?,
    );
  }
}
