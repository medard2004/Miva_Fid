import 'package:flutter/material.dart';

/// Niveaux de fidélité partagés par le module marchand et l'app client.
///
/// L'API expose une clé canonique (`level.key` : bronze, silver, gold,
/// platinum, custom) dérivée du libellé libre configuré par le marchand —
/// le client, lui, ne voit que des symboles. Cette classe fait le pont :
/// même icône, même couleur et même libellé des deux côtés, sans matching
/// fragile sur les chaînes.
enum LoyaltyLevel {
  bronze('bronze', 'Bronze', Icons.military_tech, Color(0xFFEA580C),
      Color(0xFFFFEDD5)),
  silver('silver', 'Argent', Icons.workspace_premium, Color(0xFF64748B),
      Color(0xFFF1F5F9)),
  gold('gold', 'Or', Icons.emoji_events, Color(0xFFD97706),
      Color(0xFFFEF3C7)),
  platinum('platinum', 'Platine', Icons.diamond, Color(0xFF9333EA),
      Color(0xFFF3E8FF)),
  custom('custom', 'Fidèle', Icons.star, Color(0xFF475569),
      Color(0xFFF1F5F9));

  const LoyaltyLevel(
    this.key,
    this.label,
    this.icon,
    this.color,
    this.background,
  );

  /// Clé canonique renvoyée par `GET /merchant/clients` (`level.key`).
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  static LoyaltyLevel fromKey(String? key) => LoyaltyLevel.values.firstWhere(
        (l) => l.key == (key ?? '').trim().toLowerCase(),
        orElse: () => LoyaltyLevel.custom,
      );

  /// Niveau canonique pour un palier en position [position] (1-based) parmi
  /// les 5 premiers d'un programme — `null` au-delà (palier personnalisé,
  /// voir `TierIconPalette`). L'ordre de déclaration de cet enum EST l'ordre
  /// métier (Bronze < Argent < Or < Platine < Fidèle), d'où l'indexation
  /// directe sans table de correspondance séparée.
  static LoyaltyLevel? forPosition(int position) =>
      position >= 1 && position <= LoyaltyLevel.values.length
          ? LoyaltyLevel.values[position - 1]
          : null;
}
