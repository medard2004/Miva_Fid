import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_shadows.dart';

/// Surface premium partagée par toutes les cartes de fidélité et leurs
/// aperçus (pile Wallet, détail, confirmation d'inscription, illustration
/// d'onboarding) : dégradé dérivé de la couleur d'identité de
/// l'établissement, ombre teintée douce et diffuse, reflet diagonal
/// discret et liseré interne clair — un seul point d'implémentation pour
/// garder toutes les cartes visuellement cohérentes. Rayon plus généreux
/// que [AppRadius.card] (utilisé par le reste de l'app) : ces cartes
/// jouent un rôle plus « objet physique » qui appelle des coins plus doux.
class GradientCardSurface extends StatelessWidget {
  static const double defaultRadius = 28;

  final Color color;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  /// Couleur secondaire choisie par le marchand pour le dégradé. `null` sur
  /// les cartes créées avant l'introduction de ce champ : [AppColors.cardGradient]
  /// dérive alors un dégradé automatiquement à partir de [color] seule.
  final Color? secondaryColor;

  /// `linear` ou `radial`, tel que configuré côté marchand.
  final String gradientType;

  /// `none`, `lines`, `waves` ou `dots`, tel que configuré côté marchand.
  final String decorationPattern;

  const GradientCardSurface({
    super.key,
    required this.color,
    required this.child,
    this.borderRadius = defaultRadius,
    this.padding,
    this.width,
    this.height,
    this.secondaryColor,
    this.gradientType = 'linear',
    this.decorationPattern = 'none',
  });

  Gradient get _gradient {
    final secondary = secondaryColor;
    if (secondary == null) return AppColors.cardGradient(color);
    return gradientType == 'radial'
        ? RadialGradient(
            colors: [color, secondary],
            center: Alignment.topLeft,
            radius: 1.2,
          )
        : LinearGradient(
            colors: [color, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: AppShadows.card(color),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (decorationPattern != 'none')
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardPatternPainter(
                    pattern: decorationPattern,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            // Reflet diagonal — simule un fin balayage de lumière plutôt
            // qu'un simple assombrissement de coin, pour une transition
            // fluide ; opacité toujours très faible, ne couvre jamais
            // le contenu.
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
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Motif de fond décoratif — même tracé que l'aperçu marchand
/// (`onboarding/widgets/loyalty_card_preview.dart`) pour que la carte
/// reçue par le client corresponde à ce que le marchand a configuré.
class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter({required this.pattern, required this.color});
  final String pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    if (pattern == 'lines') {
      const step = 24.0;
      for (double i = -size.height; i < size.width; i += step) {
        canvas.drawLine(
          Offset(i, 0),
          Offset(i + size.height, size.height),
          paint,
        );
      }
    } else if (pattern == 'waves') {
      const step = 32.0;
      for (double y = 8; y < size.height; y += step) {
        final path = Path()..moveTo(0, y);
        for (double x = 0; x < size.width; x += 8) {
          final dy = 5.0 * math.sin(x * 0.04);
          path.lineTo(x, y + dy);
        }
        canvas.drawPath(path, paint);
      }
    } else if (pattern == 'dots') {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      const step = 14.0;
      for (double x = step / 2; x < size.width; x += step) {
        for (double y = step / 2; y < size.height; y += step) {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern || oldDelegate.color != color;
}
