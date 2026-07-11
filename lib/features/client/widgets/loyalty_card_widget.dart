import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'dart:math' as math;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../models/loyalty_card_model.dart';
import '../../merchant/widgets/stamp_grid_widget.dart';

class LoyaltyCardWidget extends StatelessWidget {
  const LoyaltyCardWidget.featured({super.key, required this.card})
      : compact = false;
  const LoyaltyCardWidget.compact({super.key, required this.card})
      : compact = true;

  final LoyaltyCardModel card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final merchant = card.merchant;
    final primary = merchant?.primaryColor ?? AppColors.primary;
    final secondary = merchant?.secondaryColor ?? AppColors.primaryDark;
    final required = merchant?.stampsRequired ?? 10;

    final isStampsMode = merchant?.loyaltyMode == 'stamps' || merchant == null;

    final progress = isStampsMode
        ? card.progressRatio(required)
        : (card.pointsTotal / required).clamp(0.0, 1.0);

    final remaining = isStampsMode
        ? card.stampsRemaining(required)
        : (required - card.pointsTotal).clamp(0, required);

    // Gradient configuration
    final gradient = merchant?.cardGradientType == 'radial'
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

    final pattern = merchant?.cardDecorationPattern ?? 'none';

    if (compact) {
      return Container(
        width: 160,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: Rd.card,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: Rd.card,
          child: Stack(
            children: [
              if (pattern != 'none')
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardPatternPainter(
                      pattern: pattern,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Sp.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant?.name ?? '',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      isStampsMode
                          ? '${card.stampsCount}/$required tampons'
                          : '${card.pointsTotal}/$required pts',
                      style: AppTextStyles.mono().copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: Rd.pill,
                      child: LinearProgressIndicator(
                        value: progress,
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
      );
    }

    return Container(
      height: 196,
      decoration: BoxDecoration(
        borderRadius: Rd.card20,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: Rd.card20,
        child: Stack(
          children: [
            if (pattern != 'none')
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardPatternPainter(
                    pattern: pattern,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (merchant?.logoUrl != null && merchant!.logoUrl!.isNotEmpty) ...[
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Builder(builder: (context) {
                              final url = merchant.logoUrl!;
                              if (url.startsWith('http')) {
                                return Image.network(
                                  url,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    merchant.initials,
                                    style: AppTextStyles.mono().copyWith(
                                      color: primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
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
                                  errorBuilder: (_, __, ___) => Text(
                                    merchant.initials,
                                    style: AppTextStyles.mono().copyWith(
                                      color: primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              } catch (_) {
                                return Text(
                                  merchant.initials,
                                  style: AppTextStyles.mono().copyWith(
                                    color: primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              }
                            }),
                          ),
                        ),
                      ] else ...[
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Text(
                            merchant?.initials ?? '?',
                            style: AppTextStyles.mono().copyWith(
                              color: primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Text(
                          merchant?.name ?? '',
                          style: AppTextStyles.labelBold().copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (merchant != null)
                        AppBadge(
                          merchant.category,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          textColor: Colors.white,
                        ),
                    ],
                  ),
                  const SizedBox(height: Sp.sm),
                  if (isStampsMode) ...[
                    StampGridWidget(
                      filled: card.stampsCount,
                      total: required,
                      stampSize: 26,
                      gap: 8,
                      designType: merchant?.stampDesignType ?? 'check',
                      emoji: merchant?.stampEmoji ?? '✨',
                      iconName: merchant?.stampIcon ?? 'check_rounded',
                      primaryColor: primary,
                    ),
                    const SizedBox(height: Sp.xs),
                    Text(
                      '${card.stampsCount} sur $required — encore $remaining visite${remaining > 1 ? "s" : ""}',
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
                          '${card.pointsTotal}',
                          style: AppTextStyles.h1().copyWith(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          merchant.loyaltyMode == 'spend' ? 'pts' : 'points',
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
                                'Objectif : $required pts',
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
                      'Encore $remaining points pour obtenir : ${merchant.rewardDescription ?? "votre récompense"}',
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
                      value: progress,
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
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
        );
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
