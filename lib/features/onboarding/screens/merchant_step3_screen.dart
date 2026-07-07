import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';

class MerchantStep3Screen extends ConsumerWidget {
  const MerchantStep3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingProgressBar(current: 3, total: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Text(
                      'Étape 3 sur 4',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Text('Réseaux & contacts', style: AppTextStyles.h1()),
                    const SizedBox(height: Sp.xs),
                    Text(
                      'Optionnel — visible sur votre vitrine',
                      style: AppTextStyles.bodyMd()
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: Sp.lg),
                    AppInput(
                      label: 'Numéro WhatsApp',
                      hint: '+228 90 00 00 00',
                      prefixIcon: Icons.chat_outlined,
                      keyboardType: TextInputType.phone,
                      onChanged: notifier.setPhone,
                    ),
                    AppInput(
                      label: 'Instagram',
                      hint: '@votre_commerce',
                      prefixIcon: Icons.camera_alt_outlined,
                      onChanged: (v) {},
                    ),
                    AppInput(
                      label: 'Facebook',
                      hint: 'facebook.com/votre-page',
                      prefixIcon: Icons.facebook_outlined,
                      onChanged: (v) {},
                    ),
                    AppInput(
                      label: 'TikTok',
                      hint: '@votre_compte',
                      prefixIcon: Icons.music_note_outlined,
                      onChanged: (v) {},
                    ),
                    const SizedBox(height: Sp.md),
                    Container(
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: Rd.card,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: Sp.sm),
                          Expanded(
                            child: Text(
                              'Ces informations apparaîtront sur votre vitrine publique Miva-Fid.',
                              style: AppTextStyles.caption()
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
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
                      onPressed: () => context.go('/auth/merchant/step2'),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      'Continuer',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.go('/auth/merchant/step4'),
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
