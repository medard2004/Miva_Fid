import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../widgets/loyalty_card_preview.dart';
import '../widgets/onboarding_progress_bar.dart';

class MerchantStep3Screen extends ConsumerStatefulWidget {
  const MerchantStep3Screen({super.key});

  @override
  ConsumerState<MerchantStep3Screen> createState() =>
      _MerchantStep3ScreenState();
}

class _MerchantStep3ScreenState extends ConsumerState<MerchantStep3Screen> {
  final _descCtrl = TextEditingController();
  String? _logoPath;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _logoPath = file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingProgressBar(current: 3, total: 5),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Text('Étape 3 sur 5',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.textSecondary)),
                    Text('Logo & description', style: AppTextStyles.h1()),
                    const SizedBox(height: Sp.lg),
                    Text('Logo de votre commerce',
                        style: AppTextStyles.caption().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: Sp.xs),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickLogo,
                            icon: const Icon(Icons.upload_outlined, size: 18),
                            label: const Text('Uploader mon logo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border, width: 1.5),
                              shape: const RoundedRectangleBorder(borderRadius: Rd.button),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: Sp.sm),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryTint,
                          child: _logoPath == null
                              ? const Icon(Icons.image_outlined, color: AppColors.primaryLight)
                              : const Icon(Icons.check, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.md),
                    AppInput(
                      label: 'Description de votre commerce',
                      hint: 'Décrivez votre commerce en quelques mots...',
                      controller: _descCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: Sp.lg),
                    Text('Aperçu de votre carte fidélité', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    const LoyaltyCardPreview(previewStamps: 5),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.md, 0, Sp.md,
                  MediaQuery.of(context).padding.bottom + Sp.md),
              child: Row(
                children: [
                  Expanded(child: AppButton.ghost('Retour',
                      onPressed: () => context.go('/auth/merchant/step2'))),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary('Continuer',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => context.go('/auth/merchant/step4')),
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
