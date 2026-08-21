import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../../client/providers/settings_provider.dart';
import '../../merchant/widgets/tier_editor_form.dart';

class MerchantStep2Screen extends ConsumerStatefulWidget {
  const MerchantStep2Screen({super.key});

  @override
  ConsumerState<MerchantStep2Screen> createState() =>
      _MerchantStep2ScreenState();
}

class _MerchantStep2ScreenState extends ConsumerState<MerchantStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reviewUrlCtrl;
  late final TextEditingController _fcfaPerPointCtrl;
  late final TextEditingController _cashbackPercentCtrl;
  late final TextEditingController _cashbackCapCtrl;
  late final TextEditingController _cashbackExpiryCtrl;
  final _tierEditorKey = GlobalKey<TierEditorFormState>();

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingNotifierProvider);
    _reviewUrlCtrl = TextEditingController(text: state.googleReviewUrl);
    _fcfaPerPointCtrl = TextEditingController(text: state.fcfaPerPoint.toString());
    _cashbackPercentCtrl =
        TextEditingController(text: state.cashbackPercentage.toStringAsFixed(
            state.cashbackPercentage % 1 == 0 ? 0 : 1));
    _cashbackCapCtrl = TextEditingController(
        text: state.cashbackRedeemCapPercent?.toString() ?? '');
    _cashbackExpiryCtrl = TextEditingController(
        text: state.cashbackExpiryDays?.toString() ?? '');
  }

  @override
  void dispose() {
    _reviewUrlCtrl.dispose();
    _fcfaPerPointCtrl.dispose();
    _cashbackPercentCtrl.dispose();
    _cashbackCapCtrl.dispose();
    _cashbackExpiryCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final loyaltyMode = ref.read(onboardingNotifierProvider).loyaltyMode;

    if (loyaltyMode != 'cashback') {
      final tiers = _tierEditorKey.currentState?.currentTiers() ??
          ref.read(onboardingNotifierProvider).tiers;
      notifier.setTiers(tiers);
    }

    if (loyaltyMode == 'spend') {
      notifier.setFcfaPerPoint(int.tryParse(_fcfaPerPointCtrl.text.trim()) ?? 100);
    }

    if (loyaltyMode == 'cashback') {
      notifier.setCashbackPercentage(
          double.tryParse(_cashbackPercentCtrl.text.trim().replaceAll(',', '.')) ?? 5);
      final cap = int.tryParse(_cashbackCapCtrl.text.trim());
      notifier.setCashbackRedeemCapPercent(cap);
      final expiry = int.tryParse(_cashbackExpiryCtrl.text.trim());
      notifier.setCashbackExpiryDays(expiry);
    }

    if (ref.read(onboardingNotifierProvider).showReviewButton) {
      notifier.setGoogleReviewUrl(_reviewUrlCtrl.text.trim());
    }

    context.go('/auth/merchant/step3');
  }

  String _getGoalUnit(String loyaltyMode) {
    return loyaltyMode == 'spend' ? 'points / FCFA' : 'tampons';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final goalUnit = _getGoalUnit(state.loyaltyMode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              const OnboardingProgressBar(current: 3, total: 4),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Sp.md),
                      Text(
                        'Votre programme',
                        style: AppTextStyles.h1()
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: Sp.xs),
                      Text(
                        'Configurez vos modes et niveaux de récompense.',
                        style: AppTextStyles.bodyMd()
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: Sp.lg),

                      // Mode de récompense
                      Text('Mode de récompense',
                          style: AppTextStyles.labelBold()),
                      const SizedBox(height: Sp.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildModeButton(
                              label: 'Tampons',
                              icon: LucideIcons.layoutGrid,
                              isSelected: state.loyaltyMode == 'stamps',
                              onTap: () {
                                notifier.setLoyaltyMode('stamps');
                              },
                            ),
                            const SizedBox(width: Sp.xs),
                            _buildModeButton(
                              label: 'Achats',
                              icon: LucideIcons.shoppingCart,
                              isSelected: state.loyaltyMode == 'spend',
                              onTap: () {
                                notifier.setLoyaltyMode('spend');
                              },
                            ),
                            const SizedBox(width: Sp.xs),
                            _buildModeButton(
                              label: 'Cashback',
                              icon: LucideIcons.wallet,
                              isSelected: state.loyaltyMode == 'cashback',
                              onTap: () {
                                notifier.setLoyaltyMode('cashback');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sp.lg),

                      if (state.loyaltyMode == 'spend') ...[
                        Builder(builder: (context) {
                          final fcfa = int.tryParse(_fcfaPerPointCtrl.text.trim()) ?? 500;
                          return Container(
                            padding: const EdgeInsets.all(Sp.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppInput(
                                  label: '1 point tous les combien de FCFA ? *',
                                  hint: 'Ex: 500',
                                  controller: _fcfaPerPointCtrl,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: LucideIcons.banknote,
                                  accentColor: AppColors.merchant,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    final parsed = int.tryParse(v?.trim() ?? '');
                                    if (parsed == null || parsed <= 0) {
                                      return 'Veuillez entrer un nombre supérieur à 0';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: Sp.xs),
                                Text(
                                  'Exemple : Un achat de ${fcfa * 5} FCFA donne 5 points.',
                                  style: AppTextStyles.caption().copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: Sp.lg),
                      ],

                      if (state.loyaltyMode == 'cashback') ...[
                        Container(
                          padding: const EdgeInsets.all(Sp.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppInput(
                                label: 'Pourcentage de cashback (%) *',
                                hint: 'Ex: 5',
                                controller: _cashbackPercentCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                prefixIcon: LucideIcons.percent,
                                accentColor: AppColors.merchant,
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  final parsed = double.tryParse((v?.trim() ?? '').replaceAll(',', '.'));
                                  if (parsed == null || parsed <= 0 || parsed > 100) {
                                    return 'Veuillez entrer un pourcentage entre 0 et 100';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sp.sm),
                              AppInput(
                                label: "Plafond d'utilisation par achat (%, optionnel)",
                                hint: 'Ex: 50 — vide = pas de plafond',
                                controller: _cashbackCapCtrl,
                                keyboardType: TextInputType.number,
                                prefixIcon: LucideIcons.shieldHalf,
                                accentColor: AppColors.merchant,
                                validator: (v) {
                                  final trimmed = v?.trim() ?? '';
                                  if (trimmed.isEmpty) return null;
                                  final parsed = int.tryParse(trimmed);
                                  if (parsed == null || parsed <= 0 || parsed > 100) {
                                    return 'Veuillez entrer un pourcentage entre 1 et 100';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sp.sm),
                              AppInput(
                                label: "Expiration du solde (jours, optionnel)",
                                hint: 'Ex: 365 — vide = pas d\'expiration',
                                controller: _cashbackExpiryCtrl,
                                keyboardType: TextInputType.number,
                                prefixIcon: LucideIcons.calendarClock,
                                accentColor: AppColors.merchant,
                                validator: (v) {
                                  final trimmed = v?.trim() ?? '';
                                  if (trimmed.isEmpty) return null;
                                  final parsed = int.tryParse(trimmed);
                                  if (parsed == null || parsed <= 0) {
                                    return 'Veuillez entrer un nombre de jours supérieur à 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Sp.xs),
                              Builder(builder: (context) {
                                final pct = double.tryParse(
                                        _cashbackPercentCtrl.text.trim().replaceAll(',', '.')) ??
                                    5;
                                final earned = (20000 * pct / 100).round();
                                return Text(
                                  'Exemple : un achat de 20 000 FCFA crédite $earned FCFA de cashback.',
                                  style: AppTextStyles.caption()
                                      .copyWith(color: AppColors.textSecondary),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: Sp.lg),
                      ],

                      // Liste dynamique des récompenses (Tampons/Achats
                      // uniquement — Cashback n'a pas de cycle objectif).
                      if (state.loyaltyMode != 'cashback') ...[
                        TierEditorForm(
                          key: _tierEditorKey,
                          initialTiers: state.tiers,
                          goalUnit: goalUnit,
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: Sp.md),
                        OutlinedButton.icon(
                          onPressed: () => _tierEditorKey.currentState?.addTier(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: AppColors.merchant,
                            side: const BorderSide(color: AppColors.merchant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: Text(
                            'Ajouter un palier',
                            style: AppTextStyles.bodyMd()
                                .copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],

                      const SizedBox(height: Sp.lg),

                      SwitchListTile.adaptive(
                        value: state.showReviewButton,
                        onChanged: (v) {
                          notifier.setShowReviewButton(v);
                          if (!v) _reviewUrlCtrl.clear();
                        },
                        title: Text(
                          "Afficher le bouton 'Laisser un avis'",
                          style: AppTextStyles.bodyMd(),
                        ),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.merchant,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (state.showReviewButton) ...[
                        const SizedBox(height: Sp.sm),
                        AppInput(
                          label: "Lien d'avis clients",
                          hint: 'https://g.page/...',
                          controller: _reviewUrlCtrl,
                          onChanged: notifier.setGoogleReviewUrl,
                          prefixIcon: LucideIcons.link,
                          keyboardType: TextInputType.url,
                          accentColor: AppColors.merchant,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) {
                              return 'Veuillez renseigner le lien d\'avis';
                            }
                            final uri = Uri.tryParse(value);
                            if (uri == null ||
                                !uri.isAbsolute ||
                                !(uri.scheme == 'http' || uri.scheme == 'https')) {
                              return 'Lien invalide (doit commencer par http:// ou https://)';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: Sp.lg),
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
                        onPressed: () => context.go('/auth/merchant/location'),
                      ),
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      flex: 2,
                      child: AppButton.merchant(
                        'Continuer',
                        icon: LucideIcons.arrowRight,
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.merchant : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.merchant : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.merchant.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMd().copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
