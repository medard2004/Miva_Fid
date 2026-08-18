import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';
import '../utils/commerce_icons.dart';
import 'premium_card_surface.dart';
import 'stamp_grid_widget_preview.dart';

class LoyaltyCardPreview extends ConsumerWidget {
  const LoyaltyCardPreview({super.key, this.previewStamps = 7});

  final int previewStamps;

  /// Même hauteur fixe que la carte du module client
  /// (`LoyaltyCardWidget.height` par défaut).
  static const double _cardHeight = 148;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);

    final primary = state.colorPrimary;
    final secondary = HSLColor.fromColor(primary)
        .withLightness(
          (HSLColor.fromColor(primary).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();

    final isStampsMode = state.loyaltyMode == 'stamps';
    // For stamps mode, calculate progress based on stampsRequired
    // For points mode, simulate 70% progress in preview
    final currentPoints = (state.stampsRequired * 0.7).round();
    final progress = isStampsMode
        ? previewStamps / state.stampsRequired
        : currentPoints / state.stampsRequired;

    // Gradient configuration
    final gradient = state.cardGradientType == 'radial'
        ? RadialGradient(
            colors: [primary, secondary],
            center: Alignment.topLeft,
            radius: 1.2,
          )
        : LinearGradient(
            colors: [primary, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return PremiumCardSurface(
      gradient: gradient,
      shadowColor: primary,
      child: Stack(
        children: [
          // Pattern Overlay
          if (state.cardDecorationPattern != 'none')
            Positioned.fill(
              child: CustomPaint(
                painter: _CardPatternPainter(
                  pattern: state.cardDecorationPattern,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),

          // Content — même grammaire visuelle que la carte du module
          // client (badge catégorie + nom en serif Cormorant + bloc de
          // données en DM Mono), adaptée à la personnalisation marchand
          // (logo, motif, mode tampons/points en direct). Hauteur et
          // paddings alignés sur la carte compacte du module client
          // (lib/features/client/wallet/widgets/loyalty_card_widget.dart)
          // pour une cohérence visuelle entre les deux parcours.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _cardHeight - 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CardTopGroup(
                  commerceType: state.commerceType,
                  commerceName: state.commerceName,
                  logoUrl: state.logoUrl,
                  primaryColor: primary,
                ),
                _CardBottomGroup(
                  isStampsMode: isStampsMode,
                  previewStamps: previewStamps,
                  stampsRequired: state.stampsRequired,
                  currentPoints: currentPoints,
                  loyaltyMode: state.loyaltyMode,
                  progress: progress,
                  stampDesignType: state.stampDesignType,
                  stampEmoji: state.stampEmoji,
                  stampIcon: state.stampIcon,
                  primaryColor: primary,
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    ).animate().scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1.0, 1.0),
          duration: 150.ms,
        );
  }
}

/// Badge catégorie (gauche) + logo (droite), puis nom du commerce — même
/// disposition que le haut de la carte du module client.
class _CardTopGroup extends StatelessWidget {
  const _CardTopGroup({
    required this.commerceType,
    required this.commerceName,
    required this.logoUrl,
    required this.primaryColor,
  });

  final String commerceType;
  final String commerceName;
  final String? logoUrl;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: Rd.pill,
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconForCommerceType(commerceType), size: 10, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    (commerceType.isEmpty ? 'Commerce' : commerceType).toUpperCase(),
                    style: AppTextStyles.mono().copyWith(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Logo — fond plein si un vrai logo est fourni, sinon pastille
            // translucide avec l'icône de catégorie.
            if (hasLogo)
              CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Builder(builder: (context) {
                    final url = logoUrl!;
                    Widget fallback() => Icon(
                          iconForCommerceType(commerceType),
                          size: 13,
                          color: primaryColor,
                        );
                    if (url.startsWith('http')) {
                      return Image.network(url,
                          width: 22, height: 22, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
                    }
                    try {
                      return Image.file(File(url),
                          width: 22, height: 22, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
                    } catch (_) {
                      return fallback();
                    }
                  }),
                ),
              )
            else
              CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Icon(iconForCommerceType(commerceType), size: 13, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          commerceName.isEmpty ? 'Votre Commerce' : commerceName,
          style: AppTextStyles.cardName().copyWith(color: Colors.white, fontSize: 26, height: 1.0),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Bloc mécanique (tampons/points) + barre de progression — bas de la
/// carte, poussé en bas via `MainAxisAlignment.spaceBetween` du parent.
class _CardBottomGroup extends StatelessWidget {
  const _CardBottomGroup({
    required this.isStampsMode,
    required this.previewStamps,
    required this.stampsRequired,
    required this.currentPoints,
    required this.loyaltyMode,
    required this.progress,
    required this.stampDesignType,
    required this.stampEmoji,
    required this.stampIcon,
    required this.primaryColor,
  });

  final bool isStampsMode;
  final int previewStamps;
  final int stampsRequired;
  final int currentPoints;
  final String loyaltyMode;
  final double progress;
  final String stampDesignType;
  final String stampEmoji;
  final String stampIcon;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isStampsMode) ...[
          Text(
            '$previewStamps/$stampsRequired',
            style: AppTextStyles.monoLg().copyWith(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 6),
          StampGridWidgetPreview(
            filled: previewStamps,
            total: stampsRequired,
            stampSize: 20,
            gap: 5,
            designType: stampDesignType,
            emoji: stampEmoji,
            iconName: stampIcon,
            primaryColor: primaryColor,
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currentPoints',
                style: AppTextStyles.monoLg().copyWith(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(width: 4),
              Text(
                loyaltyMode == 'spend' ? 'pts' : 'points',
                style: AppTextStyles.mono().copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Objectif : $stampsRequired pts',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: Rd.pill,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}

// ── Custom painter for card background patterns ──────────────────────────────
/// Motif ancré dans une bande à droite de la carte, avec un fondu progressif
/// vers sa gauche — le texte (nom, badge, tampons/points) reste toujours sur
/// un fond propre, plutôt qu'un motif plein cadre qui le traverse.
class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter({required this.pattern, required this.color});
  final String pattern;
  final Color color;

  static const double _bandStart = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final bandLeft = size.width * _bandStart;
    final bandRect = Rect.fromLTWH(bandLeft, 0, size.width - bandLeft, size.height);

    canvas.save();
    canvas.clipRect(bandRect);

    final fadeShader = ui.Gradient.linear(
      Offset(bandLeft, 0),
      Offset(bandLeft + (size.width - bandLeft) * 0.55, 0),
      [color.withValues(alpha: 0), color],
    );

    if (pattern == 'lines') {
      final paint = Paint()
        ..shader = fadeShader
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      const step = 20.0;
      for (double x = bandLeft - size.height; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      }
    } else if (pattern == 'waves') {
      final paint = Paint()
        ..shader = fadeShader
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      const step = 22.0;
      for (double y = 10; y < size.height; y += step) {
        final path = Path()..moveTo(bandLeft, y);
        for (double x = bandLeft; x < size.width; x += 6) {
          final dy = 4.5 * math.sin((x - bandLeft) * 0.05);
          path.lineTo(x, y + dy);
        }
        canvas.drawPath(path, paint);
      }
    } else if (pattern == 'dots') {
      final dotPaint = Paint()
        ..shader = fadeShader
        ..style = PaintingStyle.fill;
      const step = 13.0;
      for (double x = bandLeft + step / 2; x < size.width; x += step) {
        for (double y = step / 2; y < size.height; y += step) {
          canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern || oldDelegate.color != color;
}
