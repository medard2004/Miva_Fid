import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/merchant_model.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../onboarding/providers/onboarding_provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initFromMerchant();
  }

  void _initFromMerchant([bool force = false]) {
    if (_initialized && !force) return;

    final m = ref.read(merchantNotifierProvider).value;
    final restaurant = ref.read(merchantAuthProvider).restaurant;
    final ob = ref.read(onboardingNotifierProvider);

    final cfg = restaurant?.loyaltyConfig ?? {};

    final colorHex = m?.colorPrimary ?? (cfg['color_primary'] as String?) ?? '#5B50EC';
    String hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final color = Color(int.tryParse(hex, radix: 16) ?? 0xFF5B50EC);

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final commerceName = m?.name ?? restaurant?.name ?? (ob.commerceName.isNotEmpty ? ob.commerceName : 'Votre Commerce');
    final commerceType = m?.category ?? restaurant?.category ?? (ob.commerceType.isNotEmpty ? ob.commerceType : 'Restaurant');

    notifier.setCommerceName(commerceName);
    notifier.setCommerceType(commerceType);
    notifier.setColorPrimary(color);
    notifier.setCardDecorationPattern(m?.cardDecorationPattern ?? (cfg['card_decoration_pattern'] as String?) ?? ob.cardDecorationPattern);
    notifier.setStampDesignType(m?.stampDesignType ?? (cfg['stamp_design_type'] as String?) ?? ob.stampDesignType);
    notifier.setStampIcon(m?.stampIcon ?? (cfg['stamp_icon'] as String?) ?? ob.stampIcon);
    notifier.setStampEmoji(m?.stampEmoji ?? (cfg['stamp_emoji'] as String?) ?? ob.stampEmoji);
    notifier.setLogoUrl(m?.logoUrl ?? restaurant?.logoUrl ?? ob.logoUrl ?? '');
    notifier.setLoyaltyMode(m?.loyaltyMode ?? restaurant?.loyaltyType ?? ob.loyaltyMode);
    
    final goal = m?.stampsRequired ?? (cfg['goal'] as int?) ?? ob.stampsRequired;
    notifier.setStampsRequired(goal > 0 ? goal : 10);

    final reward = m?.rewardDescription ?? (cfg['reward_description'] as String?) ?? ob.rewardDescription;
    if (reward.isNotEmpty) {
      notifier.setRewardDescription(reward);
    }

    _initialized = true;
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

    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'color_primary': hexColor,
        'card_decoration_pattern': state.cardDecorationPattern,
        'stamp_design_type': state.stampDesignType,
        'stamp_icon': state.stampIcon,
        'stamp_emoji': state.stampEmoji,
        'logo_url': state.logoUrl,
      });
      if (mounted) {
        ToastService.showSuccess(t.merchantProgrammeDesignSaveSuccess);
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(t.merchantProgrammeDesignSaveError(e.toString()));
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B50EC) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B50EC) : AppColors.border,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: SingleChildScrollView(
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
                        color: isSelected ? const Color(0xFF5B50EC) : AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : const Color(0xFF5B50EC),
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
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: SingleChildScrollView(
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
                        color: isSelected ? const Color(0xFF5B50EC).withValues(alpha: 0.15) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF5B50EC) : AppColors.border,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final merchantAsync = ref.watch(merchantNotifierProvider);
    final merchant = merchantAsync.value;
    final restaurant = ref.watch(merchantAuthProvider).restaurant;

    // React to merchant data loading if initialized early
    ref.listen<AsyncValue<MerchantModel?>>(merchantNotifierProvider, (_, next) {
      if (next.value != null && !_initialized) {
        _initFromMerchant(true);
      }
    });

    final name = merchant?.name ?? restaurant?.name ?? 'VC';
    final String displayInitials = merchant?.initials ??
        (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'VC');
    final String currentLogoUrl = state.logoUrl?.isNotEmpty == true
        ? state.logoUrl!
        : (merchant?.logoUrl ?? restaurant?.logoUrl ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.merchantMoreCustomizeCard,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(LucideIcons.bell, size: 18, color: AppColors.textPrimary),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/merchant/more/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. CARTE DE FIDÉLITÉ EN DIRECT ────────────────────
                    const LoyaltyCardPreview(previewStamps: 4),
                    const SizedBox(height: 20),

                    // ── 2. LOGO DU COMMERCE ──────────────────────────────
                    Text(
                      t.merchantMoreLogoBusiness,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.merchantProgrammeDesignLogoHint,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
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
                                logoUrl: currentLogoUrl,
                                initials: displayInitials,
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentLogoUrl.isNotEmpty
                                      ? t.merchantProgrammeDesignLogoPresent
                                      : t.merchantProgrammeDesignNoLogo,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.merchantProgrammeDesignSquareFormatHint,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
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
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(LucideIcons.camera, size: 14, color: Color(0xFF5B50EC)),
                            label: Text(
                              currentLogoUrl.isNotEmpty ? t.commonEdit : t.merchantProgrammeDesignAddButton,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (currentLogoUrl.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: _uploadingLogo ? null : _removeLogo,
                              tooltip: t.merchantProgrammeDesignRemoveTooltip,
                              icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 3. COULEUR PRINCIPALE ─────────────────────────────
                    Text(
                      t.merchantProgrammeDesignPrimaryColorLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.merchantProgrammeDesignColorHint,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(14),
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
                    const SizedBox(height: 20),

                    // ── 4. MOTIF DE FOND ──────────────────────────────────
                    Text(
                      t.merchantProgrammeDesignPatternLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                    const SizedBox(height: 20),

                    // ── 5. STYLE DES TAMPONS ──────────────────────────────
                    if ((merchant?.loyaltyMode ?? restaurant?.loyaltyType ?? state.loyaltyMode) == 'stamps') ...[
                      Text(
                        t.merchantProgrammeDesignStampStyleLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          const SizedBox(width: 8),
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
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => state.stampDesignType == 'icon'
                              ? _showIconPicker(context, notifier, state.stampIcon)
                              : _showEmojiPicker(context, notifier, state.stampEmoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
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
                                    color: const Color(0xFF5B50EC),
                                    size: 18,
                                  )
                                else
                                  Text(state.stampEmoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    state.stampDesignType == 'icon'
                                        ? t.merchantProgrammeDesignIconSelectedLabel
                                        : t.merchantProgrammeDesignEmojiSelectedLabel,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  t.commonEdit,
                                  style: const TextStyle(
                                    color: Color(0xFF5B50EC),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // ── BOUTON ENREGISTRER ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B50EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          t.merchantProgrammeDesignSaveButton,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
