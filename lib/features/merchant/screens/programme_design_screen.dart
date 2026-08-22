import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/color_palette_picker.dart';
import '../../onboarding/widgets/loyalty_card_preview.dart';
import '../providers/merchant_provider.dart';

class ProgrammeDesignScreen extends ConsumerStatefulWidget {
  const ProgrammeDesignScreen({super.key});

  @override
  ConsumerState<ProgrammeDesignScreen> createState() => _ProgrammeDesignScreenState();
}

class _ProgrammeDesignScreenState extends ConsumerState<ProgrammeDesignScreen> {
  bool _saving = false;
  bool _initialized = false;
  bool _showPreview = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromMerchant();
    });
  }

  void _initFromMerchant() {
    final m = ref.read(merchantNotifierProvider).value;
    if (m != null) {
      String hex = m.colorPrimary.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      final color = Color(int.parse(hex, radix: 16));
      
      final notifier = ref.read(onboardingNotifierProvider.notifier);
      notifier.setColorPrimary(color);
      notifier.setCardDecorationPattern(m.cardDecorationPattern);
      notifier.setStampDesignType(m.stampDesignType);
      notifier.setStampIcon(m.stampIcon);
      notifier.setStampEmoji(m.stampEmoji);
      
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _save() async {
    final state = ref.read(onboardingNotifierProvider);
    
    setState(() => _saving = true);

    final hexColor = '#${state.colorPrimary.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'color_primary': hexColor,
        'card_decoration_pattern': state.cardDecorationPattern,
        'stamp_design_type': state.stampDesignType,
        'stamp_icon': state.stampIcon,
        'stamp_emoji': state.stampEmoji,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Design mis à jour avec succès')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final merchant = ref.watch(merchantNotifierProvider).value;

    if (!_initialized || merchant == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Apparence')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Apparence de la carte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Aperçu', style: AppTextStyles.labelBold()),
                        Switch(
                          value: _showPreview,
                          onChanged: (val) => setState(() => _showPreview = val),
                          activeThumbColor: AppColors.merchant,
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.xs),
                    if (_showPreview) ...[
                      const LoyaltyCardPreview(previewStamps: 6),
                      const SizedBox(height: Sp.xl),
                    ],

                    Text('Couleur principale', style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.xs),
                    Text(
                      'Choisissez la couleur dominante de votre carte de fidélité.',
                      style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: Sp.md),

                    Container(
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ColorPalettePicker(
                        selected: state.colorPrimary,
                        onColorSelected: notifier.setColorPrimary,
                      ),
                    ),
                    const SizedBox(height: Sp.xl),

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
                    const SizedBox(height: Sp.xl),

                    if (merchant.loyaltyMode == 'stamps') ...[
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
                      const SizedBox(height: Sp.xl),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, MediaQuery.of(context).padding.bottom + Sp.md),
              child: AppButton.primary(
                'Enregistrer le design',
                icon: LucideIcons.save,
                onPressed: _save,
                loading: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
