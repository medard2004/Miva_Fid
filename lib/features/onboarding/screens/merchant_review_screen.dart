import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/loyalty_card_preview.dart';
import '../../client/providers/settings_provider.dart';

class MerchantReviewScreen extends ConsumerStatefulWidget {
  const MerchantReviewScreen({super.key});

  @override
  ConsumerState<MerchantReviewScreen> createState() => _MerchantReviewScreenState();
}

class _MerchantReviewScreenState extends ConsumerState<MerchantReviewScreen> {
  bool _loading = false;

  Future<void> _createMerchant() async {
    setState(() => _loading = true);
    final state = ref.read(onboardingNotifierProvider);

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('Non authentifié');
      await Supabase.instance.client
          .from('merchants')
          .insert(state.toMerchantJson(uid));
      await AppHaptics.heavy();
      if (mounted) context.go('/auth/merchant/success');
    } catch (e) {
      debugPrint('Create merchant error: $e');
      await AppHaptics.heavy();
      if (mounted) context.go('/auth/merchant/success');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _modeLabel {
    final mode = ref.read(onboardingNotifierProvider).loyaltyMode;
    switch (mode) {
      case 'points':
        return 'Points';
      case 'spend':
        return 'Points par achat';
      default:
        return 'Tampons';
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
    final hasSocials = state.whatsapp.isNotEmpty ||
        state.instagram.isNotEmpty ||
        state.facebook.isNotEmpty ||
        state.tiktok.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/auth/merchant/step3'),
                    icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.merchantTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.sparkles, size: 12, color: AppColors.merchant),
                          const SizedBox(width: 4),
                          Text(
                            'PRESQUE PRÊT',
                            style: AppTextStyles.caption().copyWith(
                              color: AppColors.merchant,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: Sp.sm),
                    Text(
                      'Votre carte est prête',
                      style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w900),
                    )
                        .animate(delay: 50.ms)
                        .fadeIn(duration: 300.ms),
                    const SizedBox(height: Sp.xs),
                    Text(
                      'Vérifiez les informations avant de l\'activer.',
                      style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary),
                    ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: Sp.lg),

                    LoyaltyCardPreview(
                      previewStamps: (state.stampsRequired * 0.7).round(),
                    ).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideY(
                          begin: 0.06,
                          end: 0,
                          duration: 350.ms,
                          curve: Curves.easeOut,
                        ),
                    const SizedBox(height: Sp.lg),

                    _ReviewSection(
                      title: 'Commerce',
                      onEdit: () => context.go('/auth/merchant/step1'),
                      rows: [
                        _ReviewRow(icon: LucideIcons.store, label: state.commerceName.isEmpty ? '—' : state.commerceName),
                        _ReviewRow(icon: LucideIcons.tag, label: state.commerceType.isEmpty ? '—' : state.commerceType),
                        _ReviewRow(icon: LucideIcons.mapPin, label: state.address.isEmpty ? '—' : state.address),
                        _ReviewRow(icon: LucideIcons.phone, label: state.phone.isEmpty ? '—' : state.phone),
                      ],
                    ),
                    const SizedBox(height: Sp.md),

                    if (hasSocials) ...[
                      _ReviewSection(
                        title: 'Réseaux sociaux',
                        onEdit: () => context.go('/auth/merchant/step1'),
                        rows: [
                          if (state.whatsapp.isNotEmpty)
                            _ReviewRow(icon: LucideIcons.messageCircle, label: state.whatsapp),
                          if (state.instagram.isNotEmpty)
                            _ReviewRow(icon: LucideIcons.camera, label: state.instagram),
                          if (state.facebook.isNotEmpty)
                            _ReviewRow(icon: LucideIcons.globe, label: state.facebook),
                          if (state.tiktok.isNotEmpty)
                            _ReviewRow(icon: LucideIcons.music, label: state.tiktok),
                        ],
                      ),
                      const SizedBox(height: Sp.md),
                    ],

                    _ReviewSection(
                      title: 'Programme',
                      onEdit: () => context.go('/auth/merchant/step2'),
                      rows: [
                        _ReviewRow(icon: LucideIcons.layoutGrid, label: '$_modeLabel · objectif ${state.stampsRequired}'),
                        _ReviewRow(
                          icon: LucideIcons.gift,
                          label: state.rewardDescription.isEmpty ? 'Aucune récompense définie' : state.rewardDescription,
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.xl),
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
              child: AppButton.merchant(
                'Activer mon programme',
                icon: LucideIcons.rocket,
                loading: _loading,
                onPressed: _createMerchant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final List<_ReviewRow> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Rd.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.labelBold())),
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  'Modifier',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.merchant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.sm),
          ...rows,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMd().copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
