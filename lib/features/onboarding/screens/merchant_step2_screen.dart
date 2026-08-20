import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../models/reward_tier.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../../client/providers/settings_provider.dart';

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
  final List<TextEditingController> _goalCtrls = [];
  final List<TextEditingController> _descCtrls = [];
  final List<TextEditingController> _validityCtrls = [];

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
    _initRewardControllers(state.rewards);
  }

  void _initRewardControllers(List<RewardTier> rewards) {
    _clearRewardControllers();
    if (rewards.isEmpty) {
      _addRewardController(const RewardTier(goal: 10, rewardDescription: ''));
    } else {
      for (final tier in rewards) {
        _addRewardController(tier);
      }
    }
  }

  void _addRewardController(RewardTier tier) {
    _goalCtrls.add(TextEditingController(text: tier.goal.toString()));
    _descCtrls.add(TextEditingController(text: tier.rewardDescription));
    _validityCtrls
        .add(TextEditingController(text: tier.validityDays?.toString() ?? ''));
  }

  void _clearRewardControllers() {
    for (final c in _goalCtrls) {
      c.dispose();
    }
    for (final c in _descCtrls) {
      c.dispose();
    }
    for (final c in _validityCtrls) {
      c.dispose();
    }
    _goalCtrls.clear();
    _descCtrls.clear();
    _validityCtrls.clear();
  }

  @override
  void dispose() {
    _reviewUrlCtrl.dispose();
    _fcfaPerPointCtrl.dispose();
    _cashbackPercentCtrl.dispose();
    _cashbackCapCtrl.dispose();
    _cashbackExpiryCtrl.dispose();
    _clearRewardControllers();
    super.dispose();
  }

  void _addNewTier() {
    final state = ref.read(onboardingNotifierProvider);
    final lastGoal = _goalCtrls.isNotEmpty
        ? (int.tryParse(_goalCtrls.last.text) ?? 10)
        : 10;
    final step = state.loyaltyMode == 'stamps' ? 5 : 500;

    final newTier = RewardTier(goal: lastGoal + step, rewardDescription: '');
    setState(() {
      _addRewardController(newTier);
    });
  }

  void _removeTier(int index) {
    if (_goalCtrls.length <= 1) return;
    setState(() {
      _goalCtrls[index].dispose();
      _descCtrls[index].dispose();
      _validityCtrls[index].dispose();
      _goalCtrls.removeAt(index);
      _descCtrls.removeAt(index);
      _validityCtrls.removeAt(index);
    });
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final loyaltyMode = ref.read(onboardingNotifierProvider).loyaltyMode;

    if (loyaltyMode != 'cashback') {
      final List<RewardTier> updatedRewards = [];
      for (int i = 0; i < _goalCtrls.length; i++) {
        final goalVal = int.tryParse(_goalCtrls[i].text.trim()) ?? 10;
        final descVal = _descCtrls[i].text.trim();
        final validityVal = int.tryParse(_validityCtrls[i].text.trim());
        updatedRewards.add(RewardTier(
          goal: goalVal,
          rewardDescription: descVal,
          validityDays: validityVal,
        ));
      }
      notifier.setRewards(updatedRewards);
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paliers de récompenses',
                              style: AppTextStyles.labelBold()),
                          Text(
                            '${_goalCtrls.length} palier${_goalCtrls.length > 1 ? 's' : ''}',
                            style: AppTextStyles.caption().copyWith(
                              color: AppColors.merchant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sp.sm),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _goalCtrls.length,
                        separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(Sp.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.merchantTint,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Récompense #${index + 1}',
                                        style: AppTextStyles.caption().copyWith(
                                          color: AppColors.merchant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_goalCtrls.length > 1)
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2,
                                            size: 18, color: AppColors.danger),
                                        onPressed: () => _removeTier(index),
                                        tooltip: 'Supprimer cette récompense',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: Sp.sm),

                                // Champ 1: Seuil
                                AppInput(
                                  label: 'Objectif / Seuil ($goalUnit) *',
                                  hint: 'Ex: 10',
                                  controller: _goalCtrls[index],
                                  keyboardType: TextInputType.number,
                                  prefixIcon: LucideIcons.target,
                                  accentColor: AppColors.merchant,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    final val = v?.trim() ?? '';
                                    if (val.isEmpty) {
                                      return 'Le palier est obligatoire';
                                    }
                                    final parsed = int.tryParse(val);
                                    if (parsed == null || parsed <= 0) {
                                      return 'Veuillez entrer un nombre supérieur à 0';
                                    }
                                    if (index > 0) {
                                      final prevText = _goalCtrls[index - 1].text.trim();
                                      final prevParsed = int.tryParse(prevText);
                                      if (prevParsed != null && parsed <= prevParsed) {
                                        return 'Doit être supérieur au palier précédent ($prevParsed $goalUnit)';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: Sp.sm),

                                // Champ 2: Description
                                AppInput(
                                  label: 'Récompense offerte *',
                                  hint: 'Ex : 1 café offert, 10% de réduction',
                                  controller: _descCtrls[index],
                                  prefixIcon: LucideIcons.gift,
                                  accentColor: AppColors.merchant,
                                  maxLength: 255,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    final val = v?.trim() ?? '';
                                    if (val.isEmpty) {
                                      return 'La description de la récompense est obligatoire';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: Sp.sm),

                                // Champ 3: Validité (optionnelle, propre à ce palier)
                                AppInput(
                                  label: 'Validité (jours, optionnel)',
                                  hint: 'Ex: 30 — vide = pas d\'expiration',
                                  controller: _validityCtrls[index],
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
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: Sp.md),

                      // Bouton ajouter une autre récompense
                      OutlinedButton.icon(
                        onPressed: _addNewTier,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppColors.merchant,
                          side: const BorderSide(color: AppColors.merchant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: Text(
                          'Ajouter une autre récompense',
                          style: AppTextStyles.bodyMd().copyWith(
                            color: AppColors.merchant,
                            fontWeight: FontWeight.bold,
                          ),
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
