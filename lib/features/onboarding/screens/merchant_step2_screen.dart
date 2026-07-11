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

                    // Gradient Type Selection
                    Text(
                      'Type de dégradé de la carte',
                      style: AppTextStyles.labelBold(),
                    ),
                    const SizedBox(height: Sp.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'Linéaire',
                            isSelected: state.cardGradientType == 'linear',
                            onTap: () => notifier.setCardGradientType('linear'),
                          ),
                        ),
                        const SizedBox(width: Sp.sm),
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'Radial',
                            isSelected: state.cardGradientType == 'radial',
                            onTap: () => notifier.setCardGradientType('radial'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.lg),

                    // Background Pattern Selection
                    Text(
                      'Motif de fond de la carte',
                      style: AppTextStyles.labelBold(),
                    ),
                    const SizedBox(height: Sp.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSegmentButton(
                            label: 'Uni / Aucun',
                            isSelected: state.cardDecorationPattern == 'none',
                            onTap: () => notifier.setCardDecorationPattern('none'),
                          ),
                          const SizedBox(width: Sp.xs),
                          _buildSegmentButton(
                            label: 'Lignes',
                            isSelected: state.cardDecorationPattern == 'lines',
                            onTap: () => notifier.setCardDecorationPattern('lines'),
                          ),
                          const SizedBox(width: Sp.xs),
                          _buildSegmentButton(
                            label: 'Vagues',
                            isSelected: state.cardDecorationPattern == 'waves',
                            onTap: () => notifier.setCardDecorationPattern('waves'),
                          ),
                          const SizedBox(width: Sp.xs),
                          _buildSegmentButton(
                            label: 'Points',
                            isSelected: state.cardDecorationPattern == 'dots',
                            onTap: () => notifier.setCardDecorationPattern('dots'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.lg),

                    // Stamp Design Selection
                    Text(
                      'Symbole des tampons',
                      style: AppTextStyles.labelBold(),
                    ),
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
                    const SizedBox(height: Sp.sm),

                    // Suboptions for custom stamps (icons or emoji)
                    if (state.stampDesignType == 'icon') ...[
                      const SizedBox(height: Sp.xs),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'check_rounded',
                            'star_rounded',
                            'favorite_rounded',
                            'local_cafe_rounded',
                            'card_giftcard_rounded',
                            'auto_awesome_rounded',
                            'emoji_emotions_rounded',
                            'diamond_rounded',
                          ].map((iconName) {
                            final isSelected = state.stampIcon == iconName;
                            return GestureDetector(
                              onTap: () => notifier.setStampIcon(iconName),
                              child: Container(
                                margin: const EdgeInsets.only(right: Sp.sm),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryTint : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  _getIconData(iconName),
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: Sp.md),
                    ],

                    if (state.stampDesignType == 'emoji') ...[
                      const SizedBox(height: Sp.xs),
                      Row(
                        children: [
                          Expanded(
                            child: AppInput(
                              label: 'Saisir un emoji personnalisé',
                              hint: '✨ ou ☕ ou ⭐',
                              onChanged: (v) {
                                if (v.isNotEmpty) {
                                  notifier.setStampEmoji(v.characters.first);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: Sp.sm),
                          ...['✨', '☕', '⭐', '❤️', '💎', '🍕'].map((e) {
                            final isSelected = state.stampEmoji == e;
                            return GestureDetector(
                              onTap: () => notifier.setStampEmoji(e),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryTint : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(e, style: const TextStyle(fontSize: 16)),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: Sp.md),
                    ],

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

  IconData _getIconData(String name) {
    switch (name) {
      case 'star_rounded':
        return Icons.star_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      case 'local_cafe_rounded':
        return Icons.local_cafe_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'auto_awesome_rounded':
        return Icons.auto_awesome_rounded;
      case 'emoji_emotions_rounded':
        return Icons.emoji_emotions_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      case 'check_rounded':
      default:
        return Icons.check_rounded;
    }
  }
}
