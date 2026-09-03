import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/settings_provider.dart';

/// Écran de révélation de la récompense de bienvenue — affiché après
/// un premier join réussi si le programme offre un cadeau de bienvenue.
///
/// Affiche une animation festive (confettis + scale-in) puis un bouton
/// pour continuer vers la fiche carte. L'ID de la carte est passé en
/// paramètre pour la navigation de sortie.
class WelcomeRewardSurpriseScreen extends ConsumerStatefulWidget {
  final String cardId;
  final String? referredBy;

  const WelcomeRewardSurpriseScreen({
    super.key,
    required this.cardId,
    this.referredBy,
  });

  @override
  ConsumerState<WelcomeRewardSurpriseScreen> createState() =>
      _WelcomeRewardSurpriseScreenState();
}

class _WelcomeRewardSurpriseScreenState
    extends ConsumerState<WelcomeRewardSurpriseScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _buttonFade;

  final _random = Random();
  late final List<_Confetti> _confettiPieces;

  @override
  void initState() {
    super.initState();

    // Main content animation
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOutCubic));
    _buttonFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    // Confetti animation
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _confettiPieces = List.generate(40, (_) => _Confetti(_random));
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    context.pushReplacement('/client/card/${widget.cardId}');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ConfettiPainter(
                  confetti: _confettiPieces,
                  progress: _confettiCtrl.value,
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gift icon with glow
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.15),
                                  AppColors.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryTint,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Text('🎁', style: TextStyle(fontSize: 30)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Title
                          Text(
                            'Cadeau de bienvenue !',
                            style: AppTextStyles.displayLarge(color: AppColors.ink),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            'Félicitations ! Vous avez reçu une récompense '
                            'pour avoir rejoint ce programme de fidélité.',
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.inkMuted(),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          if (widget.referredBy != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Parrainé par ${widget.referredBy}',
                              style: AppTextStyles.bodySmall(
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Reward card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Icon(LucideIcons.gift,
                                    size: 28, color: AppColors.primary),
                                const SizedBox(height: 10),
                                Text(
                                  'Récompense surprise 🎁',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Découvrez-la dans vos récompenses !',
                                  style: AppTextStyles.bodySmall(
                                    color: AppColors.inkMuted(),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Continue button
                          FadeTransition(
                            opacity: _buttonFade,
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _continue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Voir ma carte',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confetti ─────────────────────────────────────────────────────────────────

class _Confetti {
  final double x; // 0..1
  final double speed; // fall speed multiplier
  final double size;
  final Color color;
  final double rotation;
  final double wobble;

  _Confetti(Random r)
      : x = r.nextDouble(),
        speed = 0.6 + r.nextDouble() * 0.8,
        size = 4 + r.nextDouble() * 6,
        color = _confettiColors[r.nextInt(_confettiColors.length)],
        rotation = r.nextDouble() * pi * 2,
        wobble = r.nextDouble() * 30;

  static const _confettiColors = [
    Color(0xFF4F46E5), // primary
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // emerald
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final y = -20 + (size.height + 40) * progress * c.speed;
      final x = c.x * size.width + sin(progress * pi * 4 + c.rotation) * c.wobble;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = c.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rotation + progress * pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
