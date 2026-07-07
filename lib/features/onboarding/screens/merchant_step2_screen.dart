import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/color_palette_picker.dart';
import '../widgets/loyalty_card_preview.dart';
import '../widgets/onboarding_progress_bar.dart';

class MerchantStep2Screen extends ConsumerStatefulWidget {
  const MerchantStep2Screen({super.key});

  @override
  ConsumerState<MerchantStep2Screen> createState() => _MerchantStep2ScreenState();
}

class _MerchantStep2ScreenState extends ConsumerState<MerchantStep2Screen> {
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(
      text: ref.read(onboardingNotifierProvider).description,
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      ref.read(onboardingNotifierProvider.notifier).setLogoUrl(file.path);
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
            const OnboardingProgressBar(current: 2, total: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Text(
                      'Étape 2 sur 4',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Text('Personnalisez votre carte', style: AppTextStyles.h1()),
                    const SizedBox(height: Sp.xs),
                    Text(
                      'Votre carte en temps réel avec votre logo',
                      style: AppTextStyles.bodyMd()
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: Sp.lg),
                    // Live card preview
                    const LoyaltyCardPreview(previewStamps: 4),
                    const SizedBox(height: Sp.xl),
                    
                    // Colors
                    Text(
                      'Couleur principale de votre marque',
                      style: AppTextStyles.labelBold(),
                    ),
                    const SizedBox(height: Sp.sm),
                    ColorPalettePicker(
                      selected: state.colorPrimary,
                      onColorSelected: notifier.setColorPrimary,
                    ),
                    const SizedBox(height: Sp.lg),

                    // Logo Uploader
                    Text(
                      'Logo de votre commerce',
                      style: AppTextStyles.labelBold(),
                    ),
                    const SizedBox(height: Sp.sm),
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
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryTint,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: state.logoUrl == null || state.logoUrl!.isEmpty
                                ? const Icon(Icons.image_outlined, color: AppColors.primaryLight)
                                : Builder(builder: (context) {
                                    final url = state.logoUrl!;
                                    if (url.startsWith('http')) {
                                      return Image.network(url, fit: BoxFit.cover);
                                    }
                                    return Image.file(File(url), fit: BoxFit.cover);
                                  }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.lg),

                    // Description
                    AppInput(
                      label: 'Description de votre commerce',
                      hint: 'Décrivez votre commerce en quelques mots...',
                      controller: _descCtrl,
                      maxLines: 3,
                      onChanged: notifier.setDescription,
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
                      onPressed: () {
                        notifier.setDescription(_descCtrl.text.trim());
                        context.go('/auth/merchant/step3');
                      },
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
