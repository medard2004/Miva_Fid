import 'package:flutter/material.dart';

/// Couleur secondaire de carte, dérivée de la couleur principale — pas de
/// second sélecteur dans l'UI, le dégradé est calculé plutôt que choisi.
Color deriveSecondaryColor(Color primary) => HSLColor.fromColor(primary)
    .withLightness(
      (HSLColor.fromColor(primary).lightness - 0.15).clamp(0.0, 1.0),
    )
    .toColor();
