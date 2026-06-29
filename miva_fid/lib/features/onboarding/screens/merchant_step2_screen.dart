import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/color_palette_picker.dart';
import '../widgets/loyalty_card_preview.dart';
import '../widgets/onboarding_progress_bar.dart';

class MerchantStep2Screen extends ConsumerWidget {
  const MerchantStep2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingProgressBar(current: 2, total: 5),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Text(
                      'Étape 2 sur 5',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Text('Personnalisez votre carte', style: AppTextStyles.h1()),
                    const SizedBox(height: Sp.xs),
                    Text(
                      'Votre carte en temps réel',
                      style: AppTextStyles.bodyMd()
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: Sp.lg),
                    // Live card preview
                    const LoyaltyCardPreview(previewStamps: 4),
                    const SizedBox(height: Sp.xl),
                    // Color picker
                    ColorPalettePicker(
                      selected: state.colorPrimary,
                      onColorSelected: notifier.setColorPrimary,
                    ),
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
                      onPressed: () => context.go('/auth/merchant/step1'),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      'Continuer',
                      onPressed: () => context.go('/auth/merchant/step3'),
                      icon: Icons.arrow_forward_rounded,
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
