import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/rewards_provider.dart';

class CelebrationScreen extends ConsumerStatefulWidget {
  const CelebrationScreen({super.key});

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _confetti.play();
      await AppHaptics.heavy();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewardsAsync = ref.watch(rewardsNotifierProvider);
    final latestReward = rewardsAsync.value?.where((r) => r.isAvailable).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              colors: const [
                AppColors.primary,
                AppColors.merchant,
                AppColors.warning,
                AppColors.success,
                Colors.pinkAccent,
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Sp.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.merchant],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withOpacity(0.4),
                          blurRadius: 32,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  )
                      .animate()
                      .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.1, 1.1),
                          curve: Curves.elasticOut,
                          duration: 600.ms)
                      .then()
                      .scale(end: const Offset(1.0, 1.0), duration: 150.ms),
                  const SizedBox(height: Sp.lg),
                  Text(
                    'Félicitations !',
                    style: AppTextStyles.display().copyWith(fontSize: 32),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 200.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms)
                      .fadeIn(),
                  const SizedBox(height: Sp.sm),
                  Text(
                    'Votre récompense est débloquée !',
                    style: AppTextStyles.bodyMd()
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 300.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms)
                      .fadeIn(),
                  const SizedBox(height: Sp.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Sp.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: Rd.card,
                      border: Border.all(color: AppColors.primaryLight, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: Sp.sm),
                        Text(
                          'Récompense disponible',
                          style: AppTextStyles.h2().copyWith(color: AppColors.primary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Sp.xs),
                        Text(
                          'Valable 30 jours',
                          style: AppTextStyles.caption()
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 400.ms)
                      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 300.ms)
                      .fadeIn(),
                  const SizedBox(height: Sp.xl),
                  AppButton.primary(
                    'Afficher mon code de récompense',
                    icon: Icons.qr_code_rounded,
                    onPressed: latestReward != null
                        ? () => context.go('/client/rewards/${latestReward.id}/redeem')
                        : () => context.go('/client/rewards'),
                  ),
                  const SizedBox(height: Sp.sm),
                  AppButton.ghost(
                    'Retour à l\'accueil',
                    onPressed: () => context.go('/client'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
