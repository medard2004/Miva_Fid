import 'package:flutter/material.dart';

import '../domain/loyalty_level.dart';
import '../domain/tier_icon_palette.dart';

/// Icône Material d'un palier de fidélité, résolue à partir de sa position
/// (1-based) et, pour un palier custom (position > 5 ou position inconnue),
/// de la clé choisie par le marchand dans la palette. Remplace l'ancien
/// rendu emoji (`Text(tier.icon, ...)`) partout où un niveau de fidélité
/// est affiché — un seul point d'implémentation, marchand ET client.
class TierLevelIcon extends StatelessWidget {
  final int? position;
  final String? iconKey;
  final double size;
  final Color? color;

  const TierLevelIcon({
    super.key,
    required this.position,
    this.iconKey,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final level = position == null ? null : LoyaltyLevel.forPosition(position!);
    if (level != null) {
      return Icon(level.icon, size: size, color: color ?? level.color);
    }
    final custom = TierIconPalette.byKey(iconKey);
    return Icon(custom.icon, size: size, color: color ?? Theme.of(context).colorScheme.primary);
  }
}
