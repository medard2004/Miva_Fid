import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Surface premium pour la carte de fidélité marchand — dégradé fourni par
/// l'appelant (le marchand choisit sa propre couleur/type de dégradé),
/// ombre teintée douce à 3 niveaux, reflet diagonal discret et liseré
/// interne clair. Inspirée du traitement des cartes du module client
/// (`lib/features/client/widgets/components/gradient_card_surface.dart`),
/// réimplémentée ici avec les tokens du thème marchand plutôt que
/// partagée entre modules.
class PremiumCardSurface extends StatelessWidget {
  const PremiumCardSurface({
    super.key,
    required this.gradient,
    required this.shadowColor,
    required this.child,
    this.height,
    this.borderRadius = Rd.card28,
  });

  final Gradient gradient;
  final Color shadowColor;
  final Widget child;
  final double? height;
  final BorderRadius borderRadius;

  /// Ombre teintée à 3 niveaux : contact (ancre la carte), halo médian
  /// (profondeur colorée) et halo large diffus — plutôt qu'une ombre
  /// neutre plate qui reste terne sous un dégradé saturé.
  static List<BoxShadow> tintedShadow(Color tint) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: tint.withValues(alpha: 0.24),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: tint.withValues(alpha: 0.14),
        blurRadius: 42,
        offset: const Offset(0, 22),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: tintedShadow(shadowColor),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Reflet diagonal — fin balayage de lumière, jamais assez
            // opaque pour couvrir le contenu.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0, -1.0),
                    end: Alignment(1.0, 1.0),
                    colors: [
                      Color(0x24FFFFFF),
                      Color(0x0DFFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0.0, 0.28, 0.55],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
