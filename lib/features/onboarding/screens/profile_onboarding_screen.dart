import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../client/providers/settings_provider.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Programme sur-mesure',
      description: 'Créez votre carte de fidélité en quelques clics.',
    ),
    OnboardingSlide(
      title: 'Scan QR instantané',
      description: 'Tamponnez vos clients rapidement et simplement.',
    ),
    OnboardingSlide(
      title: 'Pilotez vos ventes',
      description: 'Suivez vos performances et fidélisez vos clients.',
    ),
  ];

  void _onNext() {
    HapticFeedback.mediumImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    HapticFeedback.lightImpact();
    context.go('/auth/merchant/auth');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cet écran peint via les tokens statiques d'AppColors, invisibles pour
    // le système de dépendances de Flutter : observer la luminosité
    // effective est son seul déclencheur de rebuild sur une bascule
    // clair/sombre.
    ref.watch(appBrightnessProvider);
    const themeColor = AppColors.merchant;
    const gradient = LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: const CircleBorder(),
                      side: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    icon: Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.textPrimary),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/role-select');
                      }
                    },
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Passer',
                      style: AppTextStyles.labelBold().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ultra-clean Slide Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (page) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Clean Graphic Héro
                        Expanded(
                          child: Center(
                            child: _MerchantMinimalGraphic(
                              index: index,
                              themeColor: themeColor,
                            ),
                          ),
                        ),

                        // Title
                        Text(
                          slide.title,
                          style: AppTextStyles.h2().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(key: ValueKey('ttl_$index'))
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: 0.05, end: 0),

                        const SizedBox(height: 6),

                        // Ultra-concise Description
                        Text(
                          slide.description,
                          style: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(key: ValueKey('dsc_$index'))
                            .fadeIn(duration: 250.ms, delay: 50.ms),

                        const SizedBox(height: Sp.md),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions & Dots
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: isActive ? 20 : 6,
                          decoration: BoxDecoration(
                            gradient: isActive ? gradient : null,
                            color: isActive ? null : AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: Sp.md),

                  // Next / Start Button
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _slides.length - 1
                                  ? 'Commencer'
                                  : 'Suivant',
                              style: AppTextStyles.labelBold().copyWith(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              LucideIcons.arrowRight,
                              color: Colors.white,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Login Link
                  TextButton(
                    onPressed: _finish,
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary, fontSize: 12),
                        children: const [
                          TextSpan(text: 'Déjà commerçant ? '),
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: AppColors.merchant,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
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
}

// ── MINIMAL GRAPHICS ──────────────────────────────────────────────────

class _MerchantMinimalGraphic extends StatelessWidget {
  const _MerchantMinimalGraphic({
    required this.index,
    required this.themeColor,
  });

  final int index;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return Container(
          width: 220,
          height: 130,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.store, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Carte Fidélité',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final isDone = i < 3;
                  return Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? Colors.white : Colors.white.withValues(alpha: 0.2),
                    ),
                    child: isDone
                        ? const Icon(LucideIcons.check, size: 13, color: Color(0xFF7C3AED))
                        : null,
                  );
                }),
              ),
            ],
          ),
        );
      case 1:
        return Container(
          width: 130,
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B4B),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              LucideIcons.qrCode,
              size: 70,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        );
      case 2:
        return Container(
          width: 210,
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activités',
                    style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const Text(
                    '+38%',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Icon(LucideIcons.trendingUp, color: themeColor, size: 42),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
