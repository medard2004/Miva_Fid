import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/loyalty_card_preview.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/stamp_stepper.dart';

class MerchantStep4Screen extends ConsumerStatefulWidget {
  const MerchantStep4Screen({super.key});

  @override
  ConsumerState<MerchantStep4Screen> createState() =>
      _MerchantStep4ScreenState();
}

class _MerchantStep4ScreenState extends ConsumerState<MerchantStep4Screen> {
  late final TextEditingController _rewardCtrl;
  late final TextEditingController _reviewUrlCtrl;
  bool _loading = false;

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

  Future<void> _createMerchant() async {
    setState(() => _loading = true);
    final state = ref.read(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setRewardDescription(_rewardCtrl.text.trim());
    notifier.setGoogleReviewUrl(_reviewUrlCtrl.text.trim());

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('Non authentifié');
      await Supabase.instance.client
          .from('merchants')
          .insert(state.toMerchantJson(uid));
      await AppHaptics.heavy();
      if (mounted) context.go('/auth/merchant/success');
    } catch (e) {
      debugPrint('Create merchant error: $e');
      await AppHaptics.heavy();
      if (mounted) context.go('/auth/merchant/success');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            const OnboardingProgressBar(current: 4, total: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Text(
                      'Étape 4 sur 4',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Text('Objectif & récompense', style: AppTextStyles.h1()),
                    const SizedBox(height: Sp.xs),
                    Text(
                      'Définissez votre programme de fidélité',
                      style: AppTextStyles.bodyMd()
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: Sp.xl),

                    // Mode de Récompense
                    Text(
                      'Mode de récompense',
                      style: AppTextStyles.labelBold(),
                    ),
                    const SizedBox(height: Sp.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildModeButton(
                            label: 'Tampons',
                            icon: Icons.grid_view_rounded,
                            isSelected: state.loyaltyMode == 'stamps',
                            onTap: () {
                              notifier.setLoyaltyMode('stamps');
                              if (state.stampsRequired > 25) {
                                notifier.setStampsRequired(10);
                              }
                            },
                          ),
                          const SizedBox(width: Sp.xs),
                          _buildModeButton(
                            label: 'Points',
                            icon: Icons.stars_rounded,
                            isSelected: state.loyaltyMode == 'points',
                            onTap: () {
                              notifier.setLoyaltyMode('points');
                              notifier.setStampsRequired(100);
                            },
                          ),
                          const SizedBox(width: Sp.xs),
                          _buildModeButton(
                            label: 'Achat',
                            icon: Icons.shopping_cart_rounded,
                            isSelected: state.loyaltyMode == 'spend',
                            onTap: () {
                              notifier.setLoyaltyMode('spend');
                              notifier.setStampsRequired(500);
                            },
                          ),
                        ],
                      ),
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
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
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
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
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
                              Icons.monetization_on_outlined,
                              color: AppColors.primary,
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
                      prefixIcon: Icons.card_giftcard_outlined,
                    ),
                    const SizedBox(height: Sp.lg),
                    Text('Aperçu de votre carte', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    LoyaltyCardPreview(
                      previewStamps: (state.stampsRequired * 0.7).round(),
                    ),
                    const SizedBox(height: Sp.xl),
                    SwitchListTile.adaptive(
                      value: state.showReviewButton,
                      onChanged: notifier.setShowReviewButton,
                      title: Text(
                        "Afficher le bouton 'Laisser un avis'",
                        style: AppTextStyles.bodyMd(),
                      ),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (state.showReviewButton) ...[
                      const SizedBox(height: Sp.sm),
                      AppInput(
                        label: "Lien d'avis clients",
                        hint: 'https://g.page/...',
                        controller: _reviewUrlCtrl,
                        prefixIcon: Icons.link_outlined,
                        keyboardType: TextInputType.url,
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
                      onPressed: () => context.go('/auth/merchant/step3'),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      'Lancer mon commerce',
                      icon: Icons.rocket_launch_rounded,
                      loading: _loading,
                      onPressed: _createMerchant,
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

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
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
