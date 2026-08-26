import 'package:flutter/material.dart';

/// Une icône proposée au marchand pour un palier au-delà du 5ᵉ (voir
/// [LoyaltyLevel.forPosition]) — distincte des 5 icônes fixes pour éviter
/// toute confusion visuelle avec Bronze/Argent/Or/Platine/Fidèle.
class TierIconOption {
  final String key;
  final IconData icon;
  final String label;
  const TierIconOption(this.key, this.icon, this.label);
}

/// Palette d'icônes pour les paliers en position 6+ — le marchand choisit
/// nom ET icône librement pour ceux-là (voir `TierEditorForm`).
class TierIconPalette {
  static const List<TierIconOption> options = [
    TierIconOption('local_fire_department', Icons.local_fire_department, 'Flamme'),
    TierIconOption('bolt', Icons.bolt, 'Éclair'),
    TierIconOption('favorite', Icons.favorite, 'Cœur'),
    TierIconOption('shield', Icons.shield, 'Bouclier'),
    TierIconOption('rocket_launch', Icons.rocket_launch, 'Fusée'),
    TierIconOption('auto_awesome', Icons.auto_awesome, 'Étincelle'),
    TierIconOption('verified', Icons.verified, 'Vérifié'),
    TierIconOption('celebration', Icons.celebration, 'Fête'),
    TierIconOption('whatshot', Icons.whatshot, 'Tendance'),
    TierIconOption('grade', Icons.grade, 'Insigne'),
    TierIconOption('thumb_up', Icons.thumb_up, 'Pouce levé'),
    TierIconOption('sports_score', Icons.sports_score, 'Podium'),
  ];

  static const TierIconOption fallback = TierIconOption('grade', Icons.grade, 'Insigne');

  static TierIconOption byKey(String? key) => options.firstWhere(
        (o) => o.key == key,
        orElse: () => fallback,
      );
}
