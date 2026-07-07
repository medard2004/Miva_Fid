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
  final _rewardCtrl = TextEditingController();
  final _reviewUrlCtrl = TextEditingController();
  bool _loading = false;

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
                    Text('Nombre de tampons', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    StampStepper(
                      value: state.stampsRequired,
                      onChanged: notifier.setStampsRequired,
                    ),
                    const SizedBox(height: Sp.lg),
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
}
