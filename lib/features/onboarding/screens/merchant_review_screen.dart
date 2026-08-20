import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/errors/error_translator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
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

    try {
      final ok =
          await ref.read(onboardingNotifierProvider.notifier).submitLoyaltyProgram();
      if (!ok) throw Exception('refreshFromApi failed');
      await AppHaptics.heavy();
      if (mounted) context.go('/auth/merchant/success');
    } catch (e) {
      debugPrint('Save loyalty program error: $e');
      if (mounted) {
        final error = ErrorTranslator.translate(
          e,
          context: ErrorContext.createLoyaltyProgram,
        );
        // Un 422 peut porter plusieurs champs invalides à la fois (step2 et
        // step3 sont soumis ensemble ici) — les lister tous plutôt que
        // n'afficher que le premier évite un aller-retour par champ.
        final message = error.hasFieldErrors
            ? error.fieldErrors.values.join('\n')
            : error.displayMessage ?? ErrorMessages.profileSaveFailed;
        AppToast.error(context, message);
      }
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
    final cityCountry =
        [state.city, state.country].where((v) => v.isNotEmpty).join(', ');

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
                      stepBadge: 'Étape 1',
                      title: 'Commerce & Informations',
                      onEdit: () => context.go('/auth/merchant/step1'),
                      rows: [
                        _ReviewRow(
                          icon: LucideIcons.store,
                          label: 'Nom',
                          value: state.commerceName.isEmpty ? '—' : state.commerceName,
                        ),
                        _ReviewRow(
                          icon: LucideIcons.tag,
                          label: 'Catégorie',
                          value: state.commerceType.isEmpty ? '—' : state.commerceType,
                        ),
                        _ReviewRow(
                          icon: LucideIcons.phone,
                          label: 'Téléphone',
                          value: state.phone.isEmpty ? '—' : state.phone,
                        ),
                      ],
                    ).animate(delay: 120.ms).fadeIn(duration: 350.ms),
                    const SizedBox(height: Sp.md),

                    _ReviewSection(
                      stepBadge: 'Étape 2',
                      title: 'Localisation du commerce',
                      onEdit: () => context.go('/auth/merchant/location'),
                      rows: [
                        _ReviewRow(
                          icon: LucideIcons.globe,
                          label: 'Pays & Ville',
                          value: cityCountry.isEmpty ? 'Non renseignés' : cityCountry,
                        ),
                        _ReviewRow(
                          icon: LucideIcons.mapPin,
                          label: 'Adresse / Repère',
                          value: state.address.isEmpty ? 'Non renseignée' : state.address,
                        ),
                        _ReviewRow(
                          icon: LucideIcons.locateFixed,
                          label: 'Position GPS',
                          value: state.latitude != null && state.longitude != null
                              ? '${state.latitude!.toStringAsFixed(5)}, ${state.longitude!.toStringAsFixed(5)}'
                              : 'Non définie',
                        ),
                      ],
                    ).animate(delay: 140.ms).fadeIn(duration: 350.ms),
                    const SizedBox(height: Sp.md),

                    _ReviewSection(
                      stepBadge: 'Étape 3',
                      title: 'Réseaux sociaux & Contacts',
                      onEdit: () => context.go('/auth/merchant/step1'),
                      rows: [
                        _ReviewRow(
                          icon: LucideIcons.messageCircle,
                          label: 'WhatsApp',
                          value: state.whatsapp.isEmpty ? 'Non renseigné' : state.whatsapp,
                        ),
                        _ReviewRow(
                          icon: LucideIcons.camera,
                          label: 'Instagram',
                          value: state.instagram.isEmpty ? 'Non renseigné' : state.instagram,
                        ),
                        _ReviewRow(
                          icon: LucideIcons.globe,
                          label: 'Facebook',
                          value: state.facebook.isEmpty ? 'Non renseigné' : state.facebook,
                        ),
                        _ReviewRow(
                          icon: LucideIcons.music,
                          label: 'TikTok',
                          value: state.tiktok.isEmpty ? 'Non renseigné' : state.tiktok,
                        ),
                      ],
                    ).animate(delay: 160.ms).fadeIn(duration: 350.ms),
                    const SizedBox(height: Sp.md),

                    _ReviewSection(
                      stepBadge: 'Étape 4',
                      title: 'Programme & Récompenses',
                      onEdit: () => context.go('/auth/merchant/step2'),
                      rows: [
                        _ReviewRow(
                          icon: LucideIcons.layoutGrid,
                          label: 'Mode de fidélité',
                          value: '$_modeLabel (${state.rewards.length} palier${state.rewards.length > 1 ? 's' : ''})',
                        ),
                        ...state.rewards.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final reward = entry.value;
                          return _ReviewRow(
                            icon: LucideIcons.gift,
                            label: 'Palier #${idx + 1}',
                            value: 'À ${reward.goal} : ${reward.rewardDescription.isEmpty ? 'Aucune description' : reward.rewardDescription}',
                          );
                        }),
                      ],
                    ).animate(delay: 180.ms).fadeIn(duration: 350.ms),
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
    required this.stepBadge,
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String stepBadge;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.merchantTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stepBadge,
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.merchant,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: Sp.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelBold().copyWith(fontSize: 14),
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.pencil, size: 12, color: AppColors.merchant),
                      const SizedBox(width: 4),
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
          ),
          const SizedBox(height: Sp.xs),
          Divider(height: 16, color: AppColors.border),
          ...rows,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: Sp.sm),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMd().copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
