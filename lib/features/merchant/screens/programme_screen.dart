import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../onboarding/models/program_tier.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/loyalty_card_preview.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../client/providers/settings_provider.dart';

class ProgrammeScreen extends ConsumerStatefulWidget {
  const ProgrammeScreen({super.key});

  @override
  ConsumerState<ProgrammeScreen> createState() => _ProgrammeScreenState();
}

class _ProgrammeScreenState extends ConsumerState<ProgrammeScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPreview();
    });
  }

  void _initPreview() {
    final restaurant = ref.read(merchantAuthProvider).restaurant;
    final m = ref.read(merchantNotifierProvider).value;
    if (restaurant != null && m != null) {
      final config = restaurant.loyaltyConfig;
      List<ProgramTier> loadedTiers = [];
      if (config['tiers'] is List) {
        for (final item in config['tiers'] as List) {
          if (item is Map<String, dynamic>) {
            loadedTiers.add(ProgramTier.fromJson(item));
          } else if (item is Map) {
            loadedTiers.add(ProgramTier.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      if (loadedTiers.isEmpty) {
        loadedTiers = [
          ProgramTier(
            goal: m.stampsRequired,
            rewardDescription: m.rewardDescription ?? '',
          ),
        ];
      }

      ref.read(onboardingNotifierProvider.notifier)
        ..setCommerceName(m.name)
        ..setCommerceType(m.category)
        ..setColorPrimary(m.primaryColor)
        ..setTiers(loadedTiers);

      setState(() {
        _initialized = true;
      });
    }
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.merchant,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: Rd.card,
      child: Container(
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Rd.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Sp.sm),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: Rd.button,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelBold()),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;
    final merchantAsync = ref.watch(merchantNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.merchantProgrammeTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: merchantAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Sp.md),
            child: Column(children: [SkeletonCard(height: 200), SkeletonCard()]),
          ),
          error: (_, __) => Center(child: Text(t.merchantQrCodeLoadError, style: AppTextStyles.bodyMd())),
          data: (merchant) {
            if (!_initialized || merchant == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final loyaltyMode = merchant.loyaltyMode;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(Sp.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.merchantProgrammeCardPreviewLabel, style: AppTextStyles.labelBold()),
                  const SizedBox(height: Sp.sm),
                  const LoyaltyCardPreview(previewStamps: 6),

                  const SizedBox(height: Sp.xl),
                  Text(t.merchantProgrammeConfigTitle, style: AppTextStyles.h2()),
                  const SizedBox(height: Sp.sm),
                  Text(
                    t.merchantProgrammeConfigSubtitle,
                    style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: Sp.lg),

                  _buildCategoryItem(
                    icon: LucideIcons.palette,
                    title: t.merchantProgrammeAppearanceTitle,
                    subtitle: t.merchantProgrammeAppearanceSubtitle,
                    onTap: () => context.go('/merchant/more/programme/design'),
                  ),
                  const SizedBox(height: Sp.md),

                  _buildCategoryItem(
                    icon: LucideIcons.gift,
                    title: t.merchantProgrammeTiersTitle,
                    subtitle: t.merchantProgrammeTiersSubtitle,
                    onTap: () => context.go('/merchant/more/programme/tiers'),
                  ),
                  const SizedBox(height: Sp.md),

                  if (loyaltyMode == 'spend') ...[
                    _buildCategoryItem(
                      icon: LucideIcons.calculator,
                      title: t.merchantProgrammeRulesTitle,
                      subtitle: t.merchantProgrammeRulesSubtitle,
                      onTap: () => context.go('/merchant/more/programme/rules'),
                    ),
                    const SizedBox(height: Sp.md),
                  ],

                  if (loyaltyMode != 'cashback') ...[
                    Container(
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: Rd.card,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SwitchListTile.adaptive(
                        value: merchant.loops,
                        onChanged: (v) => ref
                            .read(merchantNotifierProvider.notifier)
                            .updateProgramme({'loops': v}),
                        title: Text(t.merchantProgrammeLoopTitle, style: AppTextStyles.labelBold()),
                        subtitle: Text(
                          merchant.loops
                              ? t.merchantProgrammeLoopEnabledSubtitle
                              : t.merchantProgrammeLoopDisabledSubtitle,
                          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                        ),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.merchant,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: Sp.md),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
