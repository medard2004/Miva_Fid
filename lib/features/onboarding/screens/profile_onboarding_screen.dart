import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String description;
}

class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key, required this.role});

  final String role; // 'client' or 'merchant'

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<OnboardingSlide> _slides = widget.role == 'merchant'
      ? const [
          OnboardingSlide(
            title: 'Votre programme, vos règles',
            subtitle: 'Créez votre propre programme',
            description: 'Configurez vos tampons en quelques secondes, personnalisez les couleurs et choisissez les récompenses de votre choix.',
          ),
          OnboardingSlide(
            title: 'Chouchoutez vos clients',
            subtitle: 'Fidélisez votre communauté',
            description: 'Offrez-leur une expérience moderne, intuitive et interactive pour les inciter à revenir régulièrement.',
          ),
          OnboardingSlide(
            title: 'Faites décoller vos ventes',
            subtitle: 'Analysez & communiquez',
            description: 'Envoyez des campagnes SMS ciblées, suivez l’activité en temps réel et pilotez votre croissance en toute simplicité.',
          ),
        ]
      : const [
          OnboardingSlide(
            title: 'Dénichez des pépites',
            subtitle: 'Explorez votre quartier',
            description: 'Découvrez tous les commerces partenaires Miva Fid autour de vous : cafés, boutiques de mode ou artisans locaux.',
          ),
          OnboardingSlide(
            title: 'Faites le plein de tampons',
            subtitle: 'Scannez & cumulez',
            description: 'Présentez simplement votre QR Code lors du passage en caisse pour obtenir instantanément vos tampons digitaux.',
          ),
          OnboardingSlide(
            title: 'C’est l’heure des cadeaux',
            subtitle: 'Profitez de vos récompenses',
            description: 'Une fois votre carte remplie, récupérez automatiquement vos cadeaux, réductions et surprises.',
          ),
        ];

  void _onNext() {
    HapticFeedback.mediumImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    HapticFeedback.lightImpact();
    if (widget.role == 'merchant') {
      context.go('/auth/merchant/auth');
    } else {
      context.go('/auth/client-signup');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.role == 'merchant' ? AppColors.merchant : AppColors.primary;
    final gradient = widget.role == 'merchant'
        ? const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          // Elegant Glow Mesh Background
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.08),
                    blurRadius: 180,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header navigation bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go('/role-select');
                        },
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Passer',
                            style: AppTextStyles.labelBold().copyWith(
                              color: themeColor,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Onboarding Graphics & Texts
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
                        padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clean Elegant Illustration Container
                            Container(
                              height: 200,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: OnboardingGraphic(
                                role: widget.role,
                                index: index,
                                themeColor: themeColor,
                              ),
                            ),
                            const SizedBox(height: Sp.xl),

                            // Subtitle category badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: themeColor.withValues(alpha: 0.1),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                slide.subtitle.toUpperCase(),
                                style: AppTextStyles.caption().copyWith(
                                  color: themeColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            )
                                .animate(key: ValueKey('subtitle_$index'))
                                .scale(begin: const Offset(0.95, 0.95), duration: 200.ms)
                                .fadeIn(),
                            const SizedBox(height: Sp.md),

                            // Title
                            Text(
                              slide.title,
                              style: AppTextStyles.h1().copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                height: 1.25,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate(key: ValueKey('title_$index'))
                                .fadeIn(duration: 400.ms, delay: 100.ms)
                                .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
                            const SizedBox(height: Sp.sm),

                            // Description
                            Text(
                              slide.description,
                              style: AppTextStyles.bodyMd().copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate(key: ValueKey('desc_$index'))
                                .fadeIn(duration: 400.ms, delay: 200.ms)
                                .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Dots & Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.xl, vertical: Sp.lg),
                  child: Column(
                    children: [
                      // Smooth Elegant Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) {
                            final isActive = _currentPage == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: isActive ? 20 : 6,
                              decoration: BoxDecoration(
                                color: isActive ? themeColor : AppColors.border.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Sp.xl),

                      // Elegant Next / Finish Button
                      GestureDetector(
                        onTap: _onNext,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withValues(alpha: 0.25),
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
                                      ? 'Commencer'
                                      : 'Suivant',
                                  style: AppTextStyles.labelBold().copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                    .move(begin: Offset.zero, end: const Offset(4, 0), duration: 600.ms, curve: Curves.easeInOut),
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
        ],
      ),
    );
  }
}

// Minimalist Elegant Illustrations
class OnboardingGraphic extends StatelessWidget {
  const OnboardingGraphic({
    super.key,
    required this.role,
    required this.index,
    required this.themeColor,
  });

  final String role;
  final int index;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    if (role == 'merchant') {
      switch (index) {
        case 0:
          return _buildMerchantDesign();
        case 1:
          return _buildMerchantCommunity();
        case 2:
          return _buildMerchantGrowth();
        default:
          return const SizedBox();
      }
    } else {
      switch (index) {
        case 0:
          return _buildClientMap();
        case 1:
          return _buildClientStamps();
        case 2:
          return _buildClientRewards();
        default:
          return const SizedBox();
      }
    }
  }

  // --- CLIENT MINIMALIST ILLUSTRATIONS ---

  Widget _buildClientMap() {
    return SizedBox(
      height: 180,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Elegant white card base
          Container(
            width: 180,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Stylized map lines
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 6,
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                Positioned(
                  left: 70,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),

          // Glowing locator pin
          Positioned(
            top: 45,
            left: 80,
            child: Icon(
              Icons.location_on_rounded,
              color: themeColor,
              size: 40,
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(0, -6), duration: 1000.ms, curve: Curves.easeInOut),
          ),

          // Mini Elegant merchant tag
          Positioned(
            top: 25,
            left: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Café',
                style: AppTextStyles.caption().copyWith(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(0, -4), duration: 1000.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildClientStamps() {
    return SizedBox(
      height: 180,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Stamp card mockup
          Container(
            width: 170,
            height: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStampCircle(true),
                _buildStampCircle(true),
                _buildStampCircle(true),
                _buildStampCircle(true),
                _buildStampCircle(false),
                _buildStampCircle(false),
              ],
            ),
          ),

          // Animated verification checkmark landing inside the empty stamp slot
          Positioned(
            left: 98,
            top: 72,
            child: Icon(
              Icons.check_circle_rounded,
              color: themeColor,
              size: 26,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(begin: const Offset(2.0, 2.0), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 200.ms)
                .then(delay: 1500.ms)
                .fadeOut(duration: 150.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildStampCircle(bool active) {
    return Container(
      decoration: BoxDecoration(
        color: active ? themeColor.withValues(alpha: 0.08) : AppColors.border.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.check_rounded,
          color: active ? themeColor : Colors.transparent,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildClientRewards() {
    return SizedBox(
      height: 180,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Elegant voucher card
          Container(
            width: 180,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Side colored accent bar
                  Container(
                    width: 8,
                    color: themeColor,
                  ),
                  // Voucher details
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 16, right: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RÉCOMPENSE',
                          style: AppTextStyles.caption().copyWith(
                            color: themeColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Café Offert',
                          style: AppTextStyles.h3().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Carte Fidélité Pleine',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(0.97, 0.97), end: const Offset(1.03, 1.03), duration: 1200.ms, curve: Curves.easeInOut),

          // Floating sparkling star badge
          Positioned(
            top: -10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(0, -6), duration: 800.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  // --- MERCHANT MINIMALIST ILLUSTRATIONS ---

  Widget _buildMerchantDesign() {
    return SizedBox(
      height: 180,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simplified elegant loyalty card mockup
          Container(
            width: 170,
            height: 110,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
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
                    Container(
                      width: 28,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  ],
                ),
                Container(
                  width: 80,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .rotate(begin: -0.03, end: 0.03, duration: 1800.ms, curve: Curves.easeInOut),

          // Small adjustment sliders representing customization
          Positioned(
            right: 0,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: themeColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '10 Tampons',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(0, -4), duration: 1200.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCommunity() {
    return SizedBox(
      height: 180,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sleek interconnected nodes representing client community
          CustomPaint(
            size: const Size(180, 100),
            painter: _ConnectionPainter(themeColor),
          ),

          // Floating clean avatars
          Positioned(
            left: 20,
            top: 20,
            child: _buildSimpleAvatar(Colors.indigo)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(0, 8), duration: 1500.ms),
          ),
          Positioned(
            right: 20,
            top: 30,
            child: _buildSimpleAvatar(Colors.teal)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(0, -8), duration: 1400.ms, delay: 100.ms),
          ),
          Positioned(
            bottom: 10,
            left: 80,
            child: _buildSimpleAvatar(Colors.deepOrange)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(8, 0), duration: 1800.ms),
          ),

          // Central quiet heart pulsing (simple but elegant)
          Center(
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.red.shade400,
              size: 44,
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAvatar(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(
        Icons.person_rounded,
        color: color,
        size: 18,
      ),
    );
  }

  Widget _buildMerchantGrowth() {
    return SizedBox(
      height: 180,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Growth curve path
          CustomPaint(
            size: const Size(180, 90),
            painter: _ChartPainter(themeColor),
          ),

          // Growth peak point
          Positioned(
            top: 15,
            right: 35,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1000.ms),
          ),

          // Minimalist performance banner
          Positioned(
            left: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: themeColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Croissance',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .move(begin: Offset.zero, end: const Offset(0, -4), duration: 1200.ms),
          ),
        ],
      ),
    );
  }
}

// Simple lines connecting community avatars
class _ConnectionPainter extends CustomPainter {
  final Color lineColor;
  _ConnectionPainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(36, 36)
      ..lineTo(size.width / 2, size.height / 2)
      ..lineTo(size.width - 36, 46)
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(96, size.height - 26);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simple chart path painter for growth visual
class _ChartPainter extends CustomPainter {
  final Color chartColor;
  _ChartPainter(this.chartColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = chartColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.7,
        size.width * 0.7,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.15,
        size.width,
        size.height * 0.05,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final linePaint = Paint()
      ..color = chartColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final linePath = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.7,
        size.width * 0.7,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.15,
        size.width,
        size.height * 0.05,
      );

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
