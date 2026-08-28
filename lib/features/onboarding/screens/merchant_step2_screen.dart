import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_input.dart';
import '../models/program_tier.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../../client/providers/settings_provider.dart';

/// Étape 3 : Configuration du programme de fidélité.
/// Un seul palier/objectif clair au démarrage (Tampons, Achats par points, ou Cashback).
class MerchantStep2Screen extends ConsumerStatefulWidget {
  const MerchantStep2Screen({super.key});

  @override
  ConsumerState<MerchantStep2Screen> createState() =>
      _MerchantStep2ScreenState();
}

class _MerchantStep2ScreenState extends ConsumerState<MerchantStep2Screen> {
  final _formKey = GlobalKey<FormState>();

  // Mode Tampons
  late final TextEditingController _stampsGoalCtrl;
  late final TextEditingController _stampsRewardCtrl;

  // Mode Achats (Points)
  late final TextEditingController _fcfaPerPointCtrl;
  late final TextEditingController _pointsGoalCtrl;
  late final TextEditingController _pointsRewardCtrl;

  // Mode Cashback
  late final TextEditingController _cashbackPercentCtrl;
  late final TextEditingController _cashbackMinRedeemCtrl;
  late final TextEditingController _cashbackExpiryCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingNotifierProvider);

    final initialGoal = state.tiers.isNotEmpty ? state.tiers.first.goal : 10;
    final initialReward =
        state.tiers.isNotEmpty ? state.tiers.first.rewardDescription : '';

    _stampsGoalCtrl = TextEditingController(text: initialGoal.toString());
    _stampsRewardCtrl = TextEditingController(
      text: initialReward.isNotEmpty ? initialReward : '1 café offert',
    );

    _fcfaPerPointCtrl =
        TextEditingController(text: state.fcfaPerPoint.toString());
    _pointsGoalCtrl = TextEditingController(
      text: (state.loyaltyMode == 'spend' ? initialGoal : 100).toString(),
    );
    _pointsRewardCtrl = TextEditingController(
      text: initialReward.isNotEmpty ? initialReward : 'Bon d\'achat de 2 000 FCFA',
    );

    _cashbackPercentCtrl = TextEditingController(
      text: state.cashbackPercentage.toStringAsFixed(
        state.cashbackPercentage % 1 == 0 ? 0 : 1,
      ),
    );
    _cashbackMinRedeemCtrl = TextEditingController(text: '1000');
    _cashbackExpiryCtrl = TextEditingController(
      text: state.cashbackExpiryDays?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _stampsGoalCtrl.dispose();
    _stampsRewardCtrl.dispose();
    _fcfaPerPointCtrl.dispose();
    _pointsGoalCtrl.dispose();
    _pointsRewardCtrl.dispose();
    _cashbackPercentCtrl.dispose();
    _cashbackMinRedeemCtrl.dispose();
    _cashbackExpiryCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final loyaltyMode = ref.read(onboardingNotifierProvider).loyaltyMode;

    if (loyaltyMode == 'stamps') {
      final goal = int.tryParse(_stampsGoalCtrl.text.trim()) ?? 10;
      final reward = _stampsRewardCtrl.text.trim();
      notifier.setTiers([ProgramTier(goal: goal, rewardDescription: reward)]);
    } else if (loyaltyMode == 'spend') {
      final fcfaPerPoint = int.tryParse(_fcfaPerPointCtrl.text.trim()) ?? 100;
      final goal = int.tryParse(_pointsGoalCtrl.text.trim()) ?? 100;
      final reward = _pointsRewardCtrl.text.trim();
      notifier.setFcfaPerPoint(fcfaPerPoint);
      notifier.setTiers([ProgramTier(goal: goal, rewardDescription: reward)]);
    } else if (loyaltyMode == 'cashback') {
      final pct = double.tryParse(
              _cashbackPercentCtrl.text.trim().replaceAll(',', '.')) ??
          5;
      final expiry = int.tryParse(_cashbackExpiryCtrl.text.trim());
      notifier.setCashbackPercentage(pct);
      notifier.setCashbackExpiryDays(expiry);
    }

    context.go('/auth/merchant/step3');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              OnboardingProgressBar(
                current: 3,
                total: 4,
                stepTitle: 'Votre programme',
                onBack: () => context.go('/auth/merchant/location'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Choisissez votre programme',
                        style: AppTextStyles.h1().copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Définissez la formule de fidélité pour vos clients.',
                        style: AppTextStyles.bodyMd().copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: Sp.md),

                      // Compact Single-Line Segmented Mode Selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildModeTab(
                              label: 'Tampons',
                              icon: LucideIcons.stamp,
                              isSelected: state.loyaltyMode == 'stamps',
                              onTap: () {
                                notifier.setLoyaltyMode('stamps');
                                setState(() {});
                              },
                            ),
                            _buildModeTab(
                              label: 'Achats',
                              icon: LucideIcons.shoppingBag,
                              isSelected: state.loyaltyMode == 'spend',
                              onTap: () {
                                notifier.setLoyaltyMode('spend');
                                setState(() {});
                              },
                            ),
                            _buildModeTab(
                              label: 'Cashback',
                              icon: LucideIcons.wallet,
                              isSelected: state.loyaltyMode == 'cashback',
                              onTap: () {
                                notifier.setLoyaltyMode('cashback');
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sp.md),

                      // CONTENT FOR SELECTED MODE
                      if (state.loyaltyMode == 'stamps')
                        _buildStampsSection()
                      else if (state.loyaltyMode == 'spend')
                        _buildSpendSection()
                      else if (state.loyaltyMode == 'cashback')
                        _buildCashbackSection(),

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
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.merchant,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(LucideIcons.arrowRight, size: 18, color: Colors.white),
                    label: Text(
                      'Continuer',
                      style: AppTextStyles.labelBold().copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.merchant : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.merchant : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODE 1: TAMPONS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStampsSection() {
    final goal = int.tryParse(_stampsGoalCtrl.text.trim()) ?? 10;
    final reward = _stampsRewardCtrl.text.trim().isNotEmpty
        ? _stampsRewardCtrl.text.trim()
        : 'votre récompense';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'CONFIGURATION TAMPONS',
          badgeText: 'Simple & Populaire',
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre de tampons
              Text(
                'Nombre de tampons requis *',
                style: AppTextStyles.labelBold().copyWith(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [5, 8, 10, 12, 15].map((count) {
                  final isSelected = goal == count;
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ChoiceChip(
                      label: Text('$count'),
                      selected: isSelected,
                      selectedColor: AppColors.merchant,
                      backgroundColor: AppColors.border,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _stampsGoalCtrl.text = count.toString();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              AppInput(
                label: 'Ou saisissez un nombre personnalisé',
                hint: 'Ex: 10',
                controller: _stampsGoalCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.hash,
                accentColor: AppColors.merchant,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Entrez un nombre de tampons valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Sp.sm),

              // Récompense offerte
              AppInput(
                label: 'Récompense offerte *',
                hint: 'Ex : 1 café offert, 10% de réduction, etc.',
                controller: _stampsRewardCtrl,
                prefixIcon: LucideIcons.gift,
                accentColor: AppColors.merchant,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Veuillez décrire la récompense'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Carte Explication Claire
        _ExplanationCard(
          icon: LucideIcons.info,
          title: 'Fonctionnement pour vos clients',
          description:
              'Chaque visite donne 1 tampon.\nAu bout de $goal tampons, le client débloque : "$reward".',
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODE 2: ACHATS / POINTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSpendSection() {
    final fcfaPerPoint = int.tryParse(_fcfaPerPointCtrl.text.trim()) ?? 100;
    final pointsGoal = int.tryParse(_pointsGoalCtrl.text.trim()) ?? 100;
    final totalSpendRequired = fcfaPerPoint * pointsGoal;
    final reward = _pointsRewardCtrl.text.trim().isNotEmpty
        ? _pointsRewardCtrl.text.trim()
        : 'votre récompense';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'CONFIGURATION ACHATS PAR POINTS',
          badgeText: 'Paniers variables',
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Taux de conversion
              Text(
                'Taux de conversion *',
                style: AppTextStyles.labelBold().copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '1 point est accordé tous les combien de FCFA ?',
                style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [100, 500, 1000].map((val) {
                  final isSelected = fcfaPerPoint == val;
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ChoiceChip(
                      label: Text('$val F'),
                      selected: isSelected,
                      selectedColor: AppColors.merchant,
                      backgroundColor: AppColors.border,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _fcfaPerPointCtrl.text = val.toString();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              AppInput(
                label: 'Montant FCFA par point',
                hint: 'Ex: 100',
                controller: _fcfaPerPointCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.coins,
                accentColor: AppColors.merchant,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Entrez un montant supérieur à 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Sp.sm),

              // Objectif de points
              AppInput(
                label: 'Objectif de points *',
                hint: 'Ex: 100',
                controller: _pointsGoalCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.target,
                accentColor: AppColors.merchant,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Entrez un objectif supérieur à 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Sp.sm),

              // Récompense offerte
              AppInput(
                label: 'Récompense offerte *',
                hint: 'Ex : Bon d\'achat de 2 000 FCFA, 1 plat offert, etc.',
                controller: _pointsRewardCtrl,
                prefixIcon: LucideIcons.gift,
                accentColor: AppColors.merchant,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Veuillez décrire la récompense'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Carte Explication Claire & Calcul
        _ExplanationCard(
          icon: LucideIcons.calculator,
          title: 'Calcul en direct',
          description:
              '• 1 point = $fcfaPerPoint FCFA dépensés\n• Avec $pointsGoal points ($totalSpendRequired FCFA cumulés), le client obtient : "$reward".',
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODE 3: CASHBACK
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCashbackSection() {
    final pct = double.tryParse(
            _cashbackPercentCtrl.text.trim().replaceAll(',', '.')) ??
        5;
    final minRedeem = int.tryParse(_cashbackMinRedeemCtrl.text.trim()) ?? 1000;
    final earnedOn20k = (20000 * pct / 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'CONFIGURATION DU CASHBACK',
          badgeText: 'Cagnotte en %',
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pourcentage
              Text(
                'Pourcentage de cashback reversé *',
                style: AppTextStyles.labelBold().copyWith(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [3, 5, 10, 15].map((count) {
                  final isSelected = pct == count.toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ChoiceChip(
                      label: Text('$count%'),
                      selected: isSelected,
                      selectedColor: AppColors.merchant,
                      backgroundColor: AppColors.border,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _cashbackPercentCtrl.text = count.toString();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              AppInput(
                label: 'Pourcentage de cashback (%)',
                hint: 'Ex: 5',
                controller: _cashbackPercentCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: LucideIcons.percent,
                accentColor: AppColors.merchant,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final parsed = double.tryParse(
                      (v?.trim() ?? '').replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0 || parsed > 100) {
                    return 'Entrez un pourcentage entre 0.1 et 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Sp.sm),

              // Seuil minimal d'utilisation
              AppInput(
                label: 'Seuil minimum pour utiliser la cagnotte (FCFA)',
                hint: 'Ex: 1000',
                controller: _cashbackMinRedeemCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.walletCards,
                accentColor: AppColors.merchant,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Sp.sm),

              // Expiration
              AppInput(
                label: 'Durée de validité du solde (jours, optionnel)',
                hint: 'Ex: 365 (vide = pas d\'expiration)',
                controller: _cashbackExpiryCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.calendarClock,
                accentColor: AppColors.merchant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Carte Explication Claire Cashback
        _ExplanationCard(
          icon: LucideIcons.sparkles,
          title: 'Fonctionnement du cashback',
          description:
              '• Pour 20 000 FCFA d\'achat, le client gagne $earnedOn20k FCFA ($pct%).\n• Dès $minRedeem FCFA cumulés, il peut déduire son solde.',
        ),
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.badgeText});

  final String title;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              fontSize: 11,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.merchant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              color: AppColors.merchant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.merchant.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: AppColors.merchant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF312E81),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
