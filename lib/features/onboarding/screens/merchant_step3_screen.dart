import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/color_palette_picker.dart';
import '../widgets/loyalty_card_preview.dart';
import '../widgets/onboarding_progress_bar.dart';

class MerchantStep3Screen extends ConsumerStatefulWidget {
  const MerchantStep3Screen({super.key});

  @override
  ConsumerState<MerchantStep3Screen> createState() => _MerchantStep3ScreenState();
}

class _MerchantStep3ScreenState extends ConsumerState<MerchantStep3Screen> {
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (!mounted) return;
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
            const OnboardingProgressBar(current: 3, total: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sp.md),
                    Text(
                      'Personnalisez votre carte',
                      style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: Sp.lg),
                    const LoyaltyCardPreview(previewStamps: 4),
                    const SizedBox(height: Sp.xl),

                    Center(child: _buildLogoPicker(state)),
                    const SizedBox(height: Sp.xl),

                    Text('Couleur principale', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    ColorPalettePicker(
                      selected: state.colorPrimary,
                      onColorSelected: notifier.setColorPrimary,
                    ),
                    const SizedBox(height: Sp.lg),

                    Text('Style des tampons', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'Coche ✓',
                            isSelected: state.stampDesignType == 'check',
                            onTap: () => notifier.setStampDesignType('check'),
                          ),
                        ),
                        const SizedBox(width: Sp.xs),
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'Icône',
                            isSelected: state.stampDesignType == 'icon',
                            onTap: () => notifier.setStampDesignType('icon'),
                          ),
                        ),
                        const SizedBox(width: Sp.xs),
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'Emoji',
                            isSelected: state.stampDesignType == 'emoji',
                            onTap: () => notifier.setStampDesignType('emoji'),
                          ),
                        ),
                      ],
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
                      color: AppColors.merchant,
                      onPressed: () => context.go('/auth/merchant/step2'),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    flex: 2,
                    child: AppButton.merchant(
                      'Continuer',
                      onPressed: () => context.go('/auth/merchant/review'),
                      icon: LucideIcons.arrowRight,
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

  Widget _buildLogoPicker(dynamic state) {
    final hasLogo = state.logoUrl != null && state.logoUrl!.isNotEmpty;
    return GestureDetector(
      onTap: _pickLogo,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryTint,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: !hasLogo
                      ? const Icon(LucideIcons.store, color: AppColors.primaryLight, size: 28)
                      : Builder(builder: (context) {
                          final url = state.logoUrl!;
                          if (url.startsWith('http')) {
                            return Image.network(url, fit: BoxFit.cover);
                          }
                          return Image.file(File(url), fit: BoxFit.cover);
                        }),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.bgLight, width: 2),
                  ),
                  child: const Icon(LucideIcons.pencil, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.xs),
          Text(
            hasLogo ? 'Changer le logo' : 'Ajouter un logo',
            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          label,
          style: AppTextStyles.bodyMd().copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
