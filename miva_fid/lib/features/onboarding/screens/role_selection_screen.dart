import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          // Background mesh glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 180,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.merchant.withOpacity(0.08),
                    blurRadius: 200,
                    spreadRadius: 90,
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(Sp.md, Sp.lg, Sp.md, bottomInset + Sp.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - Sp.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header Section
                    Column(
                      children: [
                        const SizedBox(height: Sp.sm),
                        // Premium Glass Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Miva Fid',
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                        const SizedBox(height: Sp.md),
                        Text(
                          'Quel est votre profil ?',
                          style: AppTextStyles.h1().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(delay: 100.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
                        const SizedBox(height: 8),
                        Text(
                          'Choisissez l’option qui vous correspond pour continuer.',
                          style: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(delay: 150.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
                      ],
                    ),

                    const SizedBox(height: Sp.xl),

                    // Cards Layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          _SelectionCard(
                            title: 'Je suis Client',
                            subtitle: 'Cumulez des points et débloquez des récompenses exclusives chez vos commerçants.',
                            accent: const LinearGradient(
                              colors: [Color(0xFF2E2BF7), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.card_giftcard_rounded,
                            points: const [
                              'Fidélité facile',
                              'QR codes rapides',
                              'Récompenses',
                            ],
                            buttonText: 'Commencer mon parcours',
                            onTap: () => context.go('/onboarding/client'),
                          ).animate(delay: 200.ms)
                           .fadeIn(duration: 500.ms)
                           .slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
                          _SelectionCard(
                            title: 'Je suis Commerçant',
                            subtitle: 'Fidélisez votre clientèle locale et gérez vos campagnes de tampons digitalisés.',
                            accent: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.storefront_rounded,
                            points: const [
                              'Boutique personnalisée',
                              'Statistiques clients',
                              'Campagnes SMS',
                            ],
                            buttonText: 'Créer mon espace marchand',
                            onTap: () => context.go('/onboarding/merchant'),
                          ).animate(delay: 280.ms)
                           .fadeIn(duration: 500.ms)
                           .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                        ];

                        if (isWide || constraints.maxWidth >= 800) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: Sp.md),
                              Expanded(child: cards[1]),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: Sp.md),
                            cards[1],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: Sp.xl),

                    // Footer
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Déjà un compte ? '),
                            TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatefulWidget {
  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.points,
    required this.buttonText,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final LinearGradient accent;
  final IconData icon;
  final List<String> points;
  final String buttonText;
  final VoidCallback onTap;

  @override
  State<_SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<_SelectionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHovered ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 310),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: widget.accent,
          boxShadow: [
            BoxShadow(
              color: widget.accent.colors.last.withOpacity(0.35),
              blurRadius: _isHovered ? 28 : 20,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              // Beautiful Watermark Icon Background
              Positioned(
                right: -24,
                bottom: -24,
                child: Opacity(
                  opacity: 0.10,
                  child: Icon(
                    widget.icon,
                    size: 180,
                    color: Colors.white,
                  ),
                ),
              ),

              // Card Content
              InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (highlighted) {
                  setState(() {
                    _isHovered = highlighted;
                  });
                },
                splashColor: Colors.white.withOpacity(0.12),
                highlightColor: Colors.white.withOpacity(0.06),
                child: Padding(
                  padding: const EdgeInsets.all(Sp.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row with Glassmorphism Icon container
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: Sp.md),

                      // Card Titles
                      Text(
                        widget.title,
                        style: AppTextStyles.h2().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: AppTextStyles.bodyMd().copyWith(
                          color: Colors.white.withOpacity(0.90),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: Sp.md),

                      // Feature Pills
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.points
                            .map(
                              (point) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      point,
                                      style: AppTextStyles.caption().copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: Sp.lg),

                      // Call to action button mimicking style
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.buttonText,
                                style: AppTextStyles.labelBold().copyWith(
                                  color: widget.accent.colors.last,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: Sp.xs),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: widget.accent.colors.last,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

