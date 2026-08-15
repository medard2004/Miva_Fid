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
import '../../client/providers/settings_provider.dart';

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
    // Ces ecrans peignent via les tokens statiques d'AppColors,
    // invisibles pour le systeme de dependances de Flutter : observer
    // la luminosite effective est leur seul declencheur de rebuild sur
    // une bascule clair/sombre.
    ref.watch(appBrightnessProvider);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
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

                    Text('Style de la carte', style: AppTextStyles.h3()),
                    const SizedBox(height: Sp.md),

                    Text('Couleur principale', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    ColorPalettePicker(
                      selected: state.colorPrimary,
                      onColorSelected: notifier.setColorPrimary,
                    ),

                    Text('Motif de fond', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    Wrap(
                      spacing: Sp.xs,
                      runSpacing: Sp.xs,
                      children: [
                        _buildSegmentButton(
                          label: 'Aucun',
                          isSelected: state.cardDecorationPattern == 'none',
                          onTap: () => notifier.setCardDecorationPattern('none'),
                        ),
                        _buildSegmentButton(
                          label: 'Traits',
                          isSelected: state.cardDecorationPattern == 'lines',
                          onTap: () => notifier.setCardDecorationPattern('lines'),
                        ),
                        _buildSegmentButton(
                          label: 'Vagues',
                          isSelected: state.cardDecorationPattern == 'waves',
                          onTap: () => notifier.setCardDecorationPattern('waves'),
                        ),
                        _buildSegmentButton(
                          label: 'Points',
                          isSelected: state.cardDecorationPattern == 'dots',
                          onTap: () => notifier.setCardDecorationPattern('dots'),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.lg),

                    if (state.loyaltyMode == 'stamps') ...[
                      Text('Style des tampons', style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              label: 'Icône',
                              isSelected: state.stampDesignType == 'icon',
                              onTap: () {
                                notifier.setStampDesignType('icon');
                                _showIconPicker(context, notifier, state.stampIcon);
                              },
                            ),
                          ),
                          const SizedBox(width: Sp.xs),
                          Expanded(
                            child: _buildSegmentButton(
                              label: 'Emoji',
                              isSelected: state.stampDesignType == 'emoji',
                              onTap: () {
                                notifier.setStampDesignType('emoji');
                                _showEmojiPicker(context, notifier, state.stampEmoji);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (state.stampDesignType == 'icon' ||
                          state.stampDesignType == 'emoji') ...[
                        const SizedBox(height: Sp.sm),
                        GestureDetector(
                          onTap: () => state.stampDesignType == 'icon'
                              ? _showIconPicker(context, notifier, state.stampIcon)
                              : _showEmojiPicker(context, notifier, state.stampEmoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sp.md,
                              vertical: Sp.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.merchantTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (state.stampDesignType == 'icon')
                                  Icon(
                                    _stampIconChoices
                                        .firstWhere(
                                          (e) => e.$1 == state.stampIcon,
                                          orElse: () => _stampIconChoices.first,
                                        )
                                        .$2,
                                    color: AppColors.merchant,
                                    size: 18,
                                  )
                                else
                                  Text(state.stampEmoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: Sp.sm),
                                Expanded(
                                  child: Text(
                                    state.stampDesignType == 'icon'
                                        ? 'Icône sélectionnée'
                                        : 'Emoji sélectionné',
                                    style: AppTextStyles.caption().copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Modifier',
                                  style: AppTextStyles.caption().copyWith(
                                    color: AppColors.merchant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
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
                  color: AppColors.merchantTint,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: !hasLogo
                      ? const Icon(LucideIcons.store, color: AppColors.merchant, size: 28)
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
                    color: AppColors.merchant,
                    border: Border.all(color: AppColors.background, width: 2),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  static const _stampIconChoices = <(String, IconData)>[
    ('check_rounded', LucideIcons.check),
    ('star_rounded', LucideIcons.star),
    ('favorite_rounded', LucideIcons.heart),
    ('local_cafe_rounded', LucideIcons.coffee),
    ('card_giftcard_rounded', LucideIcons.gift),
    ('auto_awesome_rounded', LucideIcons.sparkles),
    ('emoji_emotions_rounded', LucideIcons.smile),
    ('diamond_rounded', LucideIcons.gem),
  ];

  static const _stampEmojiChoices = <String>[
    '✨', '🎁', '⭐', '❤️', '☕', '🍰', '🔥', '💎',
    '🏆', '👑', '🌟', '💫', '🎉', '🍕', '🍔', '🧋',
  ];

  void _showIconPicker(
    BuildContext context,
    OnboardingNotifier notifier,
    String currentIcon,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisir une icône', style: AppTextStyles.h3()),
            const SizedBox(height: Sp.md),
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: _stampIconChoices.map((choice) {
                final (name, icon) = choice;
                final isSelected = name == currentIcon;
                return GestureDetector(
                  onTap: () {
                    notifier.setStampIcon(name);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.merchant : AppColors.merchantTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : AppColors.merchant,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + Sp.sm),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(
    BuildContext context,
    OnboardingNotifier notifier,
    String currentEmoji,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisir un emoji', style: AppTextStyles.h3()),
            const SizedBox(height: Sp.md),
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: _stampEmojiChoices.map((emoji) {
                final isSelected = emoji == currentEmoji;
                return GestureDetector(
                  onTap: () {
                    notifier.setStampEmoji(emoji);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.merchantTint : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.merchant : AppColors.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + Sp.sm),
          ],
        ),
      ),
    );
  }
}
