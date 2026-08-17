import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/stamp_stepper.dart';

class MerchantStep2Screen extends ConsumerStatefulWidget {
  const MerchantStep2Screen({super.key});

  @override
  ConsumerState<MerchantStep2Screen> createState() =>
      _MerchantStep2ScreenState();
}

class _MerchantStep2ScreenState extends ConsumerState<MerchantStep2Screen> {
  late final TextEditingController _rewardCtrl;
  late final TextEditingController _reviewUrlCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingNotifierProvider);
    _rewardCtrl = TextEditingController(text: state.rewardDescription);
    _reviewUrlCtrl = TextEditingController(text: state.googleReviewUrl);
  }

  @override
  void dispose() {
    _rewardCtrl.dispose();
    _reviewUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingProgressBar(current: 2, total: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Text(
                      'Votre programme',
                      style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: Sp.lg),

                    // Mode de récompense
                    Text('Mode de récompense', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeChip(
                            label: 'Tampons',
                            icon: LucideIcons.layoutGrid,
                            isSelected: state.loyaltyMode == 'stamps',
                            onTap: () {
                              notifier.setLoyaltyMode('stamps');
                              if (state.stampsRequired > 25) {
                                notifier.setStampsRequired(10);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: Sp.xs),
                        Expanded(
                          child: _buildModeChip(
                            label: 'Points',
                            icon: LucideIcons.sparkles,
                            isSelected: state.loyaltyMode == 'points',
                            onTap: () {
                              notifier.setLoyaltyMode('points');
                              notifier.setStampsRequired(100);
                            },
                          ),
                        ),
                        const SizedBox(width: Sp.xs),
                        Expanded(
                          child: _buildModeChip(
                            label: 'Achat',
                            icon: LucideIcons.shoppingCart,
                            isSelected: state.loyaltyMode == 'spend',
                            onTap: () {
                              notifier.setLoyaltyMode('spend');
                              notifier.setStampsRequired(500);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.lg),

                    // Conditional inputs based on loyaltyMode
                    if (state.loyaltyMode == 'stamps') ...[
                      Text('Nombre de tampons requis', style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.sm),
                      StampStepper(
                        value: state.stampsRequired,
                        onChanged: notifier.setStampsRequired,
                      ),
                      const SizedBox(height: Sp.lg),
                    ] else if (state.loyaltyMode == 'points') ...[
                      Text('Seuil de points requis', style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.sm),
                      Row(
                        children: [100, 250, 500, 1000].map((pts) {
                          final isSelected = state.stampsRequired == pts;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => notifier.setStampsRequired(pts),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.merchant : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.merchant : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$pts pts',
                                  style: AppTextStyles.bodyMd().copyWith(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: Sp.lg),
                    ] else ...[
                      Text('Objectif de points d\'achat', style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.sm),
                      Row(
                        children: [300, 500, 1000, 2000].map((pts) {
                          final isSelected = state.stampsRequired == pts;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => notifier.setStampsRequired(pts),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.merchant : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.merchant : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$pts pts',
                                  style: AppTextStyles.bodyMd().copyWith(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: Sp.lg),
                      Container(
                        padding: const EdgeInsets.all(Sp.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.banknote,
                              color: AppColors.merchant,
                              size: 20,
                            ),
                            const SizedBox(width: Sp.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '1 point par 500 FCFA d\'achat',
                                    style: AppTextStyles.bodyMd().copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Exemple : Un achat de 2 500 FCFA donne 5 points.',
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
                      const SizedBox(height: Sp.lg),
                    ],

                    AppInput(
                      label: 'Votre récompense',
                      hint: 'Ex : 1 café offert, 10% de réduction',
                      controller: _rewardCtrl,
                      onChanged: notifier.setRewardDescription,
                      prefixIcon: LucideIcons.gift,
                      accentColor: AppColors.merchant,
                    ),
                    const SizedBox(height: Sp.sm),
                    SwitchListTile.adaptive(
                      value: state.showReviewButton,
                      onChanged: notifier.setShowReviewButton,
                      title: Text(
                        "Afficher le bouton 'Laisser un avis'",
                        style: AppTextStyles.bodyMd(),
                      ),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.merchant,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (state.showReviewButton) ...[
                      const SizedBox(height: Sp.sm),
                      AppInput(
                        label: "Lien d'avis clients",
                        hint: 'https://g.page/...',
                        controller: _reviewUrlCtrl,
                        onChanged: notifier.setGoogleReviewUrl,
                        prefixIcon: LucideIcons.link,
                        keyboardType: TextInputType.url,
                        accentColor: AppColors.merchant,
                      ),
                    ],
                    const SizedBox(height: Sp.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Sp.md,
                0,
                Sp.md,
                MediaQuery.of(context).padding.bottom + Sp.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.ghost(
                      'Retour',
                      color: AppColors.merchant,
                      onPressed: () => context.go('/auth/merchant/step1'),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    flex: 2,
                    child: AppButton.merchant(
                      'Continuer',
                      icon: LucideIcons.arrowRight,
                      onPressed: () => context.go('/auth/merchant/step3'),
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

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.merchant : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.merchant : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMd().copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
