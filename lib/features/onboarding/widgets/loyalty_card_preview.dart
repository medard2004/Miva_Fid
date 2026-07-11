import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';
import 'stamp_grid_widget_preview.dart';

class LoyaltyCardPreview extends ConsumerWidget {
  const LoyaltyCardPreview({super.key, this.previewStamps = 7});

  final int previewStamps;

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
    final remainingPoints = state.stampsRequired - currentPoints;
    final progress = isStampsMode
        ? previewStamps / state.stampsRequired
        : currentPoints / state.stampsRequired;

    final remainingStamps = state.stampsRequired - previewStamps;

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 188,
      decoration: BoxDecoration(
        borderRadius: Rd.card20,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: Rd.card20,
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

            // Content
            Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // show uploaded logo (network or local) when available, otherwise default icon
                      if (state.logoUrl != null && state.logoUrl!.isNotEmpty) ...[
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Builder(builder: (context) {
                              final url = state.logoUrl!;
                              if (url.startsWith('http')) {
                                return Image.network(
                                  url,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _iconForType(state.commerceType),
                                    size: 18,
                                    color: primary,
                                  ),
                                );
                              }

                              try {
                                final f = File(url);
                                return Image.file(
                                  f,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _iconForType(state.commerceType),
                                    size: 18,
                                    color: primary,
                                  ),
                                );
                              } catch (_) {
                                return Icon(
                                  _iconForType(state.commerceType),
                                  size: 18,
                                  color: primary,
                                );
                              }
                            }),
                          ),
                        ),
                      ] else ...[
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(
                            _iconForType(state.commerceType),
                            size: 18,
                            color: primary,
                          ),
                        ),
                      ],
                      const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.commerceName.isEmpty
                                  ? 'Votre Commerce'
                                  : state.commerceName,
                              style: AppTextStyles.labelBold().copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              state.commerceType.isEmpty
                                  ? 'Commerce'
                                  : state.commerceType,
                              style: AppTextStyles.caption().copyWith(
                                  color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (isStampsMode) ...[
                    const SizedBox(height: Sp.sm),
                    StampGridWidgetPreview(
                      filled: previewStamps,
                      total: state.stampsRequired,
                      stampSize: 26,
                      designType: state.stampDesignType,
                      emoji: state.stampEmoji,
                      iconName: state.stampIcon,
                      primaryColor: primary,
                    ),
                    const SizedBox(height: Sp.xs),
                    Text(
                      '$previewStamps sur ${state.stampsRequired} — encore $remainingStamps pour votre récompense',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$currentPoints',
                          style: AppTextStyles.h1().copyWith(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.loyaltyMode == 'spend' ? 'pts' : 'points',
                          style: AppTextStyles.labelBold().copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Objectif : ${state.stampsRequired} pts',
                                style: AppTextStyles.caption().copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.xs),
                    Text(
                      'Encore $remainingPoints points pour obtenir : ${state.rewardDescription.isEmpty ? "votre récompense" : state.rewardDescription}',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: Sp.xs),
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
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1.0, 1.0),
          duration: 150.ms,
        );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Restaurant':
        return Icons.restaurant_outlined;
      case 'Hôtel':
        return Icons.hotel_outlined;
      case 'Salon':
      case 'Salon de coiffure':
      case 'Salon de beauté':
        return Icons.content_cut_outlined;
      case 'Boutique':
        return Icons.shopping_bag_outlined;
      case 'Café':
      case 'Pâtisserie':
        return Icons.coffee_outlined;
      default:
        return Icons.store_outlined;
    }
  }
}

// ── Custom painter for card background patterns ──────────────────────────────
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

