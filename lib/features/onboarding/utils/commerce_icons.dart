import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icône représentative d'une catégorie de commerce — utilisée à la fois
/// sur la carte de fidélité (badge catégorie) et dans le sélecteur de
/// catégorie de l'onboarding, pour une cohérence visuelle entre les deux.
IconData iconForCommerceType(String type) {
  switch (type) {
    case 'Restaurant':
      return LucideIcons.utensils;
    case 'Hôtel':
      return LucideIcons.bedDouble;
    case 'Salon':
    case 'Salon de coiffure':
    case 'Salon de beauté':
      return LucideIcons.scissors;
    case 'Boutique':
      return LucideIcons.shoppingBag;
    case 'Café':
    case 'Pâtisserie':
      return LucideIcons.coffee;
    case 'Supérette':
      return LucideIcons.shoppingCart;
    case 'Pharmacie':
      return LucideIcons.pill;
    default:
      return LucideIcons.store;
  }
}
