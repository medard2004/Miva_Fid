import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/utils/card_colors.dart';
import '../../onboarding/widgets/color_palette_picker.dart';
import '../../onboarding/widgets/loyalty_card_preview.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/merchant_avatar.dart';
import '../../client/providers/settings_provider.dart';

class ProgrammeDesignScreen extends ConsumerStatefulWidget {
  const ProgrammeDesignScreen({super.key});

  @override
  ConsumerState<ProgrammeDesignScreen> createState() => _ProgrammeDesignScreenState();
}

class _ProgrammeDesignScreenState extends ConsumerState<ProgrammeDesignScreen> {
  bool _saving = false;
  bool _uploadingLogo = false;
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
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed == null) return;
      final color = Color(parsed);
      
      final notifier = ref.read(onboardingNotifierProvider.notifier);
      notifier.setColorPrimary(color);
      notifier.setCardDecorationPattern(m.cardDecorationPattern);
      notifier.setStampDesignType(m.stampDesignType);
      notifier.setStampIcon(m.stampIcon);
      notifier.setStampEmoji(m.stampEmoji);
      notifier.setLogoUrl(m.logoUrl ?? '');
      
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (!mounted || file == null) return;

    setState(() => _uploadingLogo = true);
    final ok = await ref.read(merchantAuthProvider.notifier).uploadLogo(File(file.path));
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    if (ok) {
      final updatedLogo = ref.read(merchantAuthProvider).restaurant?.logoUrl;
      ref.read(onboardingNotifierProvider.notifier).setLogoUrl(updatedLogo ?? file.path);
      ToastService.showSuccess(t.merchantProfileLogoSuccess);
    } else {
      ToastService.showError(t.merchantProfileLogoError);
    }
    setState(() => _uploadingLogo = false);
  }

  Future<void> _removeLogo() async {
    setState(() => _uploadingLogo = true);
    final ok = await ref.read(merchantAuthProvider.notifier).deleteLogo();
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    if (ok) {
      ref.read(onboardingNotifierProvider.notifier).setLogoUrl('');
      ToastService.showSuccess(t.merchantProgrammeDesignLogoRemovedToast);
    } else {
      ToastService.showError(t.merchantVitrineLogoRemoveError);
    }
    setState(() => _uploadingLogo = false);
  }

  Future<void> _save() async {
    final state = ref.read(onboardingNotifierProvider);
    final t = AppLocalizations.of(context)!;

    setState(() => _saving = true);

    final hexColor = '#${state.colorPrimary.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    // Le dégradé de la carte client dérive la secondaire de la primaire
    // (voir LoyaltyCardPreview) : on renvoie la secondaire recalculée, sinon
    // l'ancienne valeur figée à l'onboarding créerait un écart aperçu/carte.
    final secondaryColor = deriveSecondaryColor(state.colorPrimary);
    final hexSecondary = '#${secondaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'color_primary': hexColor,
        'color_secondary': hexSecondary,
        'card_decoration_pattern': state.cardDecorationPattern,
        'stamp_design_type': state.stampDesignType,
        'stamp_icon': state.stampIcon,
        'stamp_emoji': state.stampEmoji,
        'logo_url': state.logoUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.merchantProgrammeDesignSaveSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.merchantProgrammeDesignSaveError(e.toString()))),
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
          color: isSelected ? AppColors.merchant : AppColors.surface,
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
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.merchantProgrammeDesignChooseIconTitle, style: AppTextStyles.h3()),
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
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.merchantProgrammeDesignChooseEmojiTitle, style: AppTextStyles.h3()),
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
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final merchant = ref.watch(merchantNotifierProvider).value;

    if (!_initialized || merchant == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(t.merchantProgrammeDesignLoadingTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.merchantProgrammeAppearanceTitle),
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
                        Text(t.merchantVitrinePreviewButton, style: AppTextStyles.labelBold()),
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

                    // Logo Section
                    Text(t.merchantMoreLogoBusiness, style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.xs),
                    Text(
                      t.merchantProgrammeDesignLogoHint,
                      style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: Sp.md),
                    Builder(
                      builder: (context) {
                        final bool hasLogo = (state.logoUrl != null && state.logoUrl!.isNotEmpty) ||
                            (merchant.logoUrl != null && merchant.logoUrl!.isNotEmpty);
                        final String displayUrl = (state.logoUrl != null && state.logoUrl!.isNotEmpty)
                            ? state.logoUrl!
                            : (merchant.logoUrl ?? '');

                        return Container(
                          padding: const EdgeInsets.all(Sp.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  MerchantAvatar(
                                    logoUrl: displayUrl,
                                    initials: merchant.initials,
                                    radius: 26,
                                  ),
                                  if (_uploadingLogo)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black38,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: Sp.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasLogo ? t.merchantProgrammeDesignLogoPresent : t.merchantProgrammeDesignNoLogo,
                                      style: AppTextStyles.labelBold().copyWith(fontSize: 14),
                                    ),
                                    Text(
                                      t.merchantProgrammeDesignSquareFormatHint,
                                      style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _uploadingLogo ? null : _pickLogo,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(LucideIcons.camera, size: 14, color: AppColors.merchant),
                                label: Text(
                                  hasLogo ? t.commonEdit : t.merchantProgrammeDesignAddButton,
                                  style: AppTextStyles.caption().copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (hasLogo) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: _uploadingLogo ? null : _removeLogo,
                                  tooltip: t.merchantProgrammeDesignRemoveTooltip,
                                  icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: Sp.xl),

                    Text(t.merchantProgrammeDesignPrimaryColorLabel, style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.xs),
                    Text(
                      t.merchantProgrammeDesignColorHint,
                      style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: Sp.md),

                    Container(
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ColorPalettePicker(
                        selected: state.colorPrimary,
                        onColorSelected: notifier.setColorPrimary,
                      ),
                    ),
                    const SizedBox(height: Sp.xl),

                    Text(t.merchantProgrammeDesignPatternLabel, style: AppTextStyles.labelBold()),
                    const SizedBox(height: Sp.sm),
                    Wrap(
                      spacing: Sp.xs,
                      runSpacing: Sp.xs,
                      children: [
                        _buildSegmentButton(
                          label: t.merchantProgrammeDesignPatternNone,
                          isSelected: state.cardDecorationPattern == 'none',
                          onTap: () => notifier.setCardDecorationPattern('none'),
                        ),
                        _buildSegmentButton(
                          label: t.merchantProgrammeDesignPatternLines,
                          isSelected: state.cardDecorationPattern == 'lines',
                          onTap: () => notifier.setCardDecorationPattern('lines'),
                        ),
                        _buildSegmentButton(
                          label: t.merchantProgrammeDesignPatternWaves,
                          isSelected: state.cardDecorationPattern == 'waves',
                          onTap: () => notifier.setCardDecorationPattern('waves'),
                        ),
                        _buildSegmentButton(
                          label: t.merchantProgrammeDesignPatternDots,
                          isSelected: state.cardDecorationPattern == 'dots',
                          onTap: () => notifier.setCardDecorationPattern('dots'),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.xl),

                    if (merchant.loyaltyMode == 'stamps') ...[
                      Text(t.merchantProgrammeDesignStampStyleLabel, style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              label: t.merchantProgrammeDesignStampTypeIcon,
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
                              label: t.merchantProgrammeDesignStampTypeEmoji,
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
                                        ? t.merchantProgrammeDesignIconSelectedLabel
                                        : t.merchantProgrammeDesignEmojiSelectedLabel,
                                    style: AppTextStyles.caption().copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  t.commonEdit,
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
                t.merchantProgrammeDesignSaveButton,
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
