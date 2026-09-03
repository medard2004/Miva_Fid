import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/storage/local_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../client/providers/settings_provider.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.tag,
  });

  final String title;
  final String description;
  final String tag;
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
      tag: 'FIDÉLITÉ SUR-MESURE',
      title: 'Votre carte de fidélité numérique',
      description:
          'Créez votre programme en quelques clics, personnalisez vos cartes et récompensez vos clients habitués.',
    ),
    OnboardingSlide(
      tag: 'SCAN ULTRA-RAPIDE',
      title: 'Validation express en caisse',
      description:
          'Scannez le QR code de vos clients en moins d\'une seconde pour ajouter des tampons et valider les cadeaux.',
    ),
    OnboardingSlide(
      tag: 'CROISSANCE COMMERÇANT',
      title: 'Pilotez vos ventes et vos clients',
      description:
          'Suivez vos passages en direct, activez des campagnes SMS ciblées et faites revenir vos clients plus souvent.',
    ),
  ];

  void _onNext() {
    HapticFeedback.mediumImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    HapticFeedback.lightImpact();
    unawaited(ref.read(localPreferencesProvider).setHasSeenOnboarding(true));
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    context.go('/auth/merchant/auth');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Top Navigation Bar : Bouton Retour (vers /role-select) et Bouton Passer
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.md,
                vertical: Sp.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      'Passer',
                      style: AppTextStyles.labelBold().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carrousel Slides
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
                      children: [
                        // Héro Visuel Riche & Adapté
                        Expanded(
                          child: Center(
                            child: _MerchantRichGraphic(
                              index: index,
                              themeColor: themeColor,
                            ),
                          ),
                        ),

                        // Tag Catégorie
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.merchantTint,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            slide.tag,
                            style: AppTextStyles.caption().copyWith(
                              color: themeColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 10.5,
                            ),
                          ),
                        )
                            .animate(key: ValueKey('tag_$index'))
                            .fadeIn(duration: 200.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 10),

                        // Titre
                        Text(
                          slide.title,
                          style: AppTextStyles.h2().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            height: 1.25,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(key: ValueKey('ttl_$index'))
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: 0.05, end: 0),

                        const SizedBox(height: 8),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            slide.description,
                            style: AppTextStyles.bodyMd().copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
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

            // Bas de page : Indicateurs + Bouton Action
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.md),
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
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          height: 6,
                          width: isActive ? 24 : 6,
                          decoration: BoxDecoration(
                            gradient: isActive ? gradient : null,
                            color: isActive ? null : AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: Sp.lg),

                  // Bouton Suivant / Commencer
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _slides.length - 1
                                  ? 'Commencer l\'aventure'
                                  : 'Continuer',
                              style: AppTextStyles.labelBold().copyWith(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.arrowRight,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
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

// ── RICH MERCHANT GRAPHICS ───────────────────────────────────────────

class _MerchantRichGraphic extends StatelessWidget {
  const _MerchantRichGraphic({
    required this.index,
    required this.themeColor,
  });

  final int index;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (index) {
      case 0:
        content = _buildLoyaltyCardVisual();
        break;
      case 1:
        content = _buildScannerVisual();
        break;
      case 2:
        content = _buildAnalyticsVisual();
        break;
      default:
        content = const SizedBox();
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: content,
    );
  }

  // Visual 1 : Carte de fidélité marchand avec tampons dorés et récompense
  Widget _buildLoyaltyCardVisual() {
    return SizedBox(
      width: 290,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Carte principale
          Container(
            width: 280,
            height: 175,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header carte
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.store,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mon Commerce VIP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Carte de fidélité',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.crown, size: 10, color: Colors.black87),
                          SizedBox(width: 3),
                          Text(
                            'GOLD',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Grille de tampons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    final isChecked = i < 4;
                    final isGift = i == 4;
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isChecked
                            ? Colors.white
                            : isGift
                                ? Colors.amber.shade300
                                : Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: isChecked
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isChecked
                            ? const Icon(
                                LucideIcons.check,
                                color: Color(0xFF7C3AED),
                                size: 18,
                              )
                            : isGift
                                ? const Icon(
                                    LucideIcons.gift,
                                    color: Color(0xFF7C3AED),
                                    size: 16,
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                      ),
                    );
                  }),
                ),

                // Footer de la carte
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '4/5 validés',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cadeau au prochain 🎁',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating badge "+10% de remise débloqué"
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.sparkles,
                      size: 13,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Récompense personnalisable',
                    style: AppTextStyles.caption().copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Visual 2 : Scanner de caisse ultra-rapide avec QR code et confirmation
  Widget _buildScannerVisual() {
    return SizedBox(
      width: 290,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cadre de visée scanner
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF131127),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: themeColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // QR Code
                Icon(
                  LucideIcons.qrCode,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.85),
                ),

                // Ligne laser de scan
                Positioned(
                  top: 85,
                  left: 18,
                  right: 18,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA78BFA).withValues(alpha: 0.9),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // Coins de cadrage
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFA78BFA), width: 3),
                        left: BorderSide(color: Color(0xFFA78BFA), width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFA78BFA), width: 3),
                        right: BorderSide(color: Color(0xFFA78BFA), width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFA78BFA), width: 3),
                        left: BorderSide(color: Color(0xFFA78BFA), width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFA78BFA), width: 3),
                        right: BorderSide(color: Color(0xFFA78BFA), width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notification flottante : Scan validé
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+1 Tampon validé !',
                        style: AppTextStyles.labelBold().copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Client: Koffi Mensah',
                        style: AppTextStyles.caption().copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Visual 3 : Tableau de bord analytique & Campagnes de fidélisation
  Widget _buildAnalyticsVisual() {
    return SizedBox(
      width: 290,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Carte principale de stats
          Container(
            width: 275,
            height: 175,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clients fidélisés',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '348 clients',
                          style: AppTextStyles.h3().copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.trendingUp,
                            color: AppColors.success,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '+42%',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Graphique barres stylisé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(height: 18, label: 'Lun', isActive: false),
                    _buildBar(height: 28, label: 'Mar', isActive: false),
                    _buildBar(height: 24, label: 'Mer', isActive: false),
                    _buildBar(height: 38, label: 'Jeu', isActive: false),
                    _buildBar(height: 48, label: 'Ven', isActive: true),
                    _buildBar(height: 56, label: 'Sam', isActive: true),
                    _buildBar(height: 36, label: 'Dim', isActive: false),
                  ],
                ),
              ],
            ),
          ),

          // Floating badge Campagne SMS
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.messageSquare, size: 13, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Campagne SMS automatisée active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required double height,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: height,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF7C3AED)
                : const Color(0xFF7C3AED).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
