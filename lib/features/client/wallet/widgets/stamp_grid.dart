import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Grille de tampons de la carte client, dessinée avec le style choisi par
/// le marchand à l'onboarding (`stamp_design_type` : `check`, `icon` ou
/// `emoji`).
///
/// Pendant de `StampGridWidgetPreview`
/// (`lib/features/onboarding/widgets/stamp_grid_widget_preview.dart`), qui
/// montre la même grille au marchand pendant la configuration. Les couleurs
/// sont ici dérivées de la carte plutôt que fixées en blanc : la doublure
/// d'un commerce peut être claire, auquel cas des pastilles blanches
/// disparaîtraient.
class StampGrid extends StatelessWidget {
  final int filled;
  final int total;
  final String designType;
  final String emoji;
  final String iconName;

  /// Couleur du texte de la carte — pastilles pleines et contour.
  final Color textColor;

  /// Doublure de la carte, reprise pour l'icône posée sur la pastille pleine.
  final Color cardColor;

  final double stampSize;
  final double gap;

  const StampGrid({
    super.key,
    required this.filled,
    required this.total,
    required this.textColor,
    required this.cardColor,
    this.designType = 'check',
    this.emoji = '✨',
    this.iconName = 'check_rounded',
    this.stampSize = 16,
    this.gap = 5,
  });

  /// Au-delà, un badge « +N » résume le reste — évite de déborder quand le
  /// marchand fixe un objectif élevé (20 tampons et plus).
  static const int _maxVisibleDots = 10;

  /// Mêmes clés que le sélecteur d'icônes du parcours marchand.
  IconData _iconData(String name) {
    switch (name) {
      case 'star_rounded':
        return LucideIcons.star;
      case 'favorite_rounded':
        return LucideIcons.heart;
      case 'local_cafe_rounded':
        return LucideIcons.coffee;
      case 'card_giftcard_rounded':
        return LucideIcons.gift;
      case 'auto_awesome_rounded':
        return LucideIcons.sparkles;
      case 'emoji_emotions_rounded':
        return LucideIcons.smile;
      case 'diamond_rounded':
        return LucideIcons.gem;
      case 'check_rounded':
      default:
        return LucideIcons.check;
    }
  }

  Widget _stampMark() {
    if (designType == 'emoji') {
      return Text(emoji, style: TextStyle(fontSize: stampSize * 0.55));
    }
    return Icon(
      _iconData(designType == 'icon' ? iconName : 'check_rounded'),
      color: cardColor,
      size: stampSize * 0.55,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    final clampedFilled = filled.clamp(0, total);
    final hasOverflow = total > _maxVisibleDots;
    final dotsToRender = hasOverflow ? _maxVisibleDots - 1 : total;
    final overflowCount = total - dotsToRender;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (int i = 0; i < dotsToRender; i++)
          SizedBox(
            width: stampSize,
            height: stampSize,
            child: i < clampedFilled
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: _stampMark()),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.5),
                        width: 1.8,
                      ),
                    ),
                  ),
          ),
        if (hasOverflow)
          Container(
            width: stampSize,
            height: stampSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textColor.withValues(alpha: 0.18),
            ),
            child: Text(
              '+$overflowCount',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: stampSize * 0.36,
              ),
            ),
          ),
      ],
    );
  }
}
