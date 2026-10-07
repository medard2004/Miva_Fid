import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:miva_fid/core/api/storage/local_preferences.dart';
import 'package:miva_fid/features/client/core/theme/app_colors.dart';
import 'package:miva_fid/features/client/core/theme/app_radius.dart';
import 'package:miva_fid/features/client/core/theme/app_text_styles.dart';
import 'package:miva_fid/features/client/providers/settings_provider.dart';
import 'package:miva_fid/features/client/widgets/components/components.dart';
import 'package:miva_fid/l10n/gen/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingSlideData> _slides(AppLocalizations t) => [
        OnboardingSlideData(
          title: t.onboardingSlide1Title,
          subtitle: t.onboardingSlide1Subtitle,
          visualBuilder: (context, active) => _WalletVisual(active: active),
        ),
        OnboardingSlideData(
          title: t.onboardingSlide2Title,
          subtitle: t.onboardingSlide2Subtitle,
          visualBuilder: (context, active) => _RewardsVisual(active: active),
        ),
        OnboardingSlideData(
          title: t.onboardingSlide3Title,
          subtitle: t.onboardingSlide3Subtitle,
          visualBuilder: (context, active) => _ReferralVisual(active: active),
        ),
      ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onNext(int slideCount) {
    if (_currentPage < slideCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    unawaited(ref.read(localPreferencesProvider).setHasSeenOnboarding(true));
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    context.go('/client/auth');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final slides = _slides(t);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (context.canPop())
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.ink,
                      ),
                      onPressed: () => context.pop(),
                    )
                  else
                    const SizedBox(width: 40),
                  TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      t.onboardingSkip,
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.inkMuted(opacity: 0.6),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  final active = _currentPage == index;
                  return _OnboardingSlide(
                    slide: slide,
                    active: active,
                    pageIndex: index,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.fastEaseInToSlowEaseOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentPage == index ? 26 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: AppButton(
                      key: ValueKey(_currentPage == slides.length - 1),
                      label: _currentPage == slides.length - 1
                          ? t.onboardingStart
                          : t.onboardingContinue,
                      onTap: () => _onNext(slides.length),
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

class OnboardingSlideData {
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, bool active) visualBuilder;

  OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.visualBuilder,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final OnboardingSlideData slide;
  final bool active;
  final int pageIndex;

  const _OnboardingSlide({
    required this.slide,
    required this.active,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 650),
                curve: Curves.fastEaseInToSlowEaseOut,
                tween: Tween(begin: 0.92, end: active ? 1.0 : 0.92),
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: slide.visualBuilder(context, active),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Titre avec animation fluide et humaine du bas vers le haut
          Text(
            slide.title,
            style: AppTextStyles.displayLarge().copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 23,
              letterSpacing: -0.4,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          )
              .animate(
                key: ValueKey('title_$pageIndex'),
                target: active ? 1 : 0,
              )
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.25,
                end: 0,
                duration: 450.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 12),

          // Sous-titre avec animation fluide et légère temporisation
          Text(
            slide.subtitle,
            style: AppTextStyles.bodyMedium(
              color: AppColors.inkMuted(opacity: 0.75),
            ).copyWith(fontSize: 14.5, height: 1.45),
            textAlign: TextAlign.center,
          )
              .animate(
                key: ValueKey('sub_$pageIndex'),
                target: active ? 1 : 0,
              )
              .fadeIn(
                duration: 450.ms,
                delay: 70.ms,
                curve: Curves.easeOut,
              )
              .slideY(
                begin: 0.28,
                end: 0,
                duration: 500.ms,
                delay: 70.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

/// Visuel 1 : pile de cartes superposées avec mouvement fluide.
class _WalletVisual extends StatelessWidget {
  final bool active;
  const _WalletVisual({required this.active});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          height: 310,
          width: 310,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 750),
                curve: Curves.fastEaseInToSlowEaseOut,
                left: active ? 45 : 70,
                top: active ? 35 : 55,
                child: Transform.rotate(
                  angle: active ? -0.1 : -0.04,
                  child: GradientCardSurface(
                    color: AppColors.liningPlum,
                    width: 220,
                    height: 135,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Le Palais',
                            style:
                                AppTextStyles.titleMedium(color: Colors.white)
                                    .copyWith(fontSize: 14)),
                        const Icon(LucideIcons.star,
                            size: 18, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 750),
                curve: Curves.fastEaseInToSlowEaseOut,
                right: active ? 38 : 65,
                bottom: active ? 35 : 55,
                child: Transform.rotate(
                  angle: active ? 0.05 : 0.0,
                  child: GradientCardSurface(
                    color: AppColors.liningIndigo,
                    width: 232,
                    height: 148,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Chez Awa',
                                style: AppTextStyles.titleMedium(
                                        color: Colors.white)
                                    .copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.qrCode,
                                color: Colors.white70, size: 20),
                          ],
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < 3
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                        ),
                        Text('3 / 8 TAMPONS',
                            style:
                                AppTextStyles.monoSmall(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(
          begin: -3,
          end: 3,
          duration: 2600.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Visuel 2 : carte à tampons avec micro-animations.
class _RewardsVisual extends StatelessWidget {
  final bool active;
  const _RewardsVisual({required this.active});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          height: 310,
          width: 310,
          child: Center(
            child: AppCard(
              elevated: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SectionEyebrow('Carte de fidélité'),
                  const SizedBox(height: 4),
                  Text('Chez Awa', style: AppTextStyles.displayMedium()),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            List.generate(4, (index) => _buildStamp(index)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            List.generate(4, (index) => _buildStamp(index + 4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      'Offre : 1 plat offert après 8 tampons',
                      style:
                          AppTextStyles.bodySmall(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(
          begin: -2.5,
          end: 2.5,
          duration: 2800.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildStamp(int index) {
    final stamped = index < 5;
    return AnimatedContainer(
      duration: Duration(milliseconds: 320 + (index * 60)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: stamped && active ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: stamped ? AppColors.primary : AppColors.border,
          width: stamped ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: stamped
            ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
            : Text('${index + 1}',
                style: AppTextStyles.monoSmall(
                    color: AppColors.inkMuted(opacity: 0.35))),
      ),
    );
  }
}

/// Visuel 3 : carton d'invitation / parrainage avec micro-animations.
class _ReferralVisual extends StatelessWidget {
  final bool active;
  const _ReferralVisual({required this.active});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          height: 310,
          width: 310,
          child: Center(
            child: SizedBox(
              width: 280,
              child: AppCard(
                elevated: true,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SectionEyebrow("Carton d'invitation"),
                    const SizedBox(height: 12),
                    Text(
                      'Partagez votre privilège :',
                      style: AppTextStyles.bodySmall(
                          color: AppColors.inkMuted(opacity: 0.8)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Center(
                        child: Text('AURA-7590',
                            style: AppTextStyles.monoLarge(
                                color: AppColors.primaryDark)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.copy,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "Copier l'invitation",
                            style:
                                AppTextStyles.label(color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(
          begin: -3,
          end: 3,
          duration: 2500.ms,
          curve: Curves.easeInOut,
        );
  }
}
