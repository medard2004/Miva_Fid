import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../onboarding/models/loyalty_level.dart';
import '../../onboarding/models/reward_tier.dart';
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
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _goalCtrls = [];
  final List<TextEditingController> _descCtrls = [];
  final List<TextEditingController> _validityCtrls = [];
  final List<TextEditingController> _levelNameCtrls = [];
  final List<TextEditingController> _levelThresholdCtrls = [];
  final _fcfaPerPointCtrl = TextEditingController(text: '500');
  final _rewardValidityDaysCtrl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromMerchant();
    });
  }

  void _initFromMerchant() {
    final restaurant = ref.read(merchantAuthProvider).restaurant;
    final m = ref.read(merchantNotifierProvider).value;
    if (restaurant != null && m != null) {
      final config = restaurant.loyaltyConfig;
      List<RewardTier> loadedRewards = [];
      if (config['rewards'] is List) {
        for (final item in config['rewards'] as List) {
          if (item is Map<String, dynamic>) {
            loadedRewards.add(RewardTier.fromJson(item));
          } else if (item is Map) {
            loadedRewards.add(RewardTier.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      if (loadedRewards.isEmpty) {
        loadedRewards = [
          RewardTier(
            goal: m.stampsRequired,
            rewardDescription: m.rewardDescription ?? '',
          ),
        ];
      }

      _clearRewardControllers();
      for (final tier in loadedRewards) {
        _addRewardController(tier);
      }
      _fcfaPerPointCtrl.text =
          (int.tryParse(config['fcfa_per_point']?.toString() ?? '') ?? 500).toString();
      _rewardValidityDaysCtrl.text =
          config['reward_validity_days']?.toString() ?? '';

      List<LoyaltyLevel> loadedLevels = [];
      if (config['levels'] is List) {
        for (final item in config['levels'] as List) {
          if (item is Map<String, dynamic>) {
            loadedLevels.add(LoyaltyLevel.fromJson(item));
          } else if (item is Map) {
            loadedLevels.add(LoyaltyLevel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      _clearLevelControllers();
      for (final level in loadedLevels) {
        _addLevelController(level);
      }

      // Sync onboarding state for the preview card
      ref.read(onboardingNotifierProvider.notifier)
        ..setCommerceName(m.name)
        ..setCommerceType(m.category)
        ..setColorPrimary(m.primaryColor)
        ..setRewards(loadedRewards);

      setState(() {
        _initialized = true;
      });
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

  void _addNewTier() {
    final m = ref.read(merchantNotifierProvider).value;
    final loyaltyMode = m?.loyaltyMode ?? 'stamps';
    final lastGoal = _goalCtrls.isNotEmpty
        ? (int.tryParse(_goalCtrls.last.text) ?? 10)
        : 10;
    final step = loyaltyMode == 'stamps'
        ? 5
        : (loyaltyMode == 'points' ? 50 : 500);

    setState(() {
      _addRewardController(RewardTier(goal: lastGoal + step, rewardDescription: ''));
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

  void _addLevelController(LoyaltyLevel level) {
    _levelNameCtrls.add(TextEditingController(text: level.name));
    _levelThresholdCtrls.add(TextEditingController(text: level.threshold.toString()));
  }

  void _clearLevelControllers() {
    for (final c in _levelNameCtrls) {
      c.dispose();
    }
    for (final c in _levelThresholdCtrls) {
      c.dispose();
    }
    _levelNameCtrls.clear();
    _levelThresholdCtrls.clear();
  }

  void _addNewLevel() {
    final lastThreshold = _levelThresholdCtrls.isNotEmpty
        ? (int.tryParse(_levelThresholdCtrls.last.text) ?? 0)
        : -1;
    setState(() {
      _addLevelController(LoyaltyLevel(name: '', threshold: lastThreshold + 1));
    });
  }

  void _removeLevel(int index) {
    setState(() {
      _levelNameCtrls[index].dispose();
      _levelThresholdCtrls[index].dispose();
      _levelNameCtrls.removeAt(index);
      _levelThresholdCtrls.removeAt(index);
    });
  }

  @override
  void dispose() {
    _clearRewardControllers();
    _clearLevelControllers();
    _fcfaPerPointCtrl.dispose();
    _rewardValidityDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

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

    final firstGoal = updatedRewards.isNotEmpty ? updatedRewards.first.goal : 10;
    final firstDesc = updatedRewards.isNotEmpty ? updatedRewards.first.rewardDescription : '';
    final loyaltyMode = ref.read(merchantNotifierProvider).value?.loyaltyMode ?? 'stamps';

    ref.read(onboardingNotifierProvider.notifier).setRewards(updatedRewards);

    final List<LoyaltyLevel> updatedLevels = [];
    for (int i = 0; i < _levelNameCtrls.length; i++) {
      final nameVal = _levelNameCtrls[i].text.trim();
      final thresholdVal = int.tryParse(_levelThresholdCtrls[i].text.trim()) ?? 0;
      if (nameVal.isEmpty) continue;
      updatedLevels.add(LoyaltyLevel(name: nameVal, threshold: thresholdVal));
    }

    try {
      await ref.read(merchantNotifierProvider.notifier).updateProgramme({
        'stamps_required': firstGoal,
        'reward_description': firstDesc,
        'rewards': updatedRewards.map((r) => r.toJson()).toList(),
        if (updatedLevels.isNotEmpty)
          'levels': updatedLevels.map((l) => l.toJson()).toList(),
        'reward_validity_days':
            int.tryParse(_rewardValidityDaysCtrl.text.trim()),
        if (loyaltyMode == 'spend')
          'fcfa_per_point': int.tryParse(_fcfaPerPointCtrl.text.trim()) ?? 500,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Programme mis à jour avec succès')));
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

  String _getGoalUnit(String loyaltyMode) {
    switch (loyaltyMode) {
      case 'points':
        return 'points';
      case 'spend':
        return 'points / FCFA';
      default:
        return 'tampons';
    }
  }

  /// Unité du seuil de niveau — différente de l'objectif de récompense :
  /// un niveau se base sur l'activité à vie, pas sur le cycle en cours.
  String _getLevelUnit(String loyaltyMode) {
    return loyaltyMode == 'cashback'
        ? 'FCFA de cashback cumulés'
        : 'cycles complétés';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBrightnessProvider);
    final merchantAsync = ref.watch(merchantNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: merchantAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Sp.md),
            child: Column(children: [SkeletonCard(height: 200), SkeletonCard()]),
          ),
          error: (_, __) =>
              Center(child: Text('Erreur', style: AppTextStyles.bodyMd())),
          data: (merchant) {
            final loyaltyMode = merchant?.loyaltyMode ?? 'stamps';
            final goalUnit = _getGoalUnit(loyaltyMode);

            return Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Sp.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mon Programme', style: AppTextStyles.h1()),
                          const SizedBox(height: Sp.xs),
                          Text('Modifiez les paliers de votre programme de fidélité',
                              style: AppTextStyles.bodyMd()
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: Sp.lg),
                          const LoyaltyCardPreview(previewStamps: 6),
                          const SizedBox(height: Sp.xl),

                          if (loyaltyMode == 'spend') ...[
                            Container(
                              padding: const EdgeInsets.all(Sp.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: AppInput(
                                label: '1 point tous les combien de FCFA ? *',
                                hint: 'Ex: 500',
                                controller: _fcfaPerPointCtrl,
                                keyboardType: TextInputType.number,
                                prefixIcon: LucideIcons.banknote,
                                accentColor: AppColors.merchant,
                                validator: (v) {
                                  final parsed = int.tryParse(v?.trim() ?? '');
                                  if (parsed == null || parsed <= 0) {
                                    return 'Veuillez entrer un nombre supérieur à 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: Sp.lg),
                          ],

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

                                    // Champ 3: Validité propre à ce palier (optionnelle)
                                    AppInput(
                                      label: 'Validité (jours, optionnel)',
                                      hint: 'Ex: 30 — vide = valeur par défaut ci-dessous',
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

                          const SizedBox(height: Sp.md),

                          AppInput(
                            label: 'Validité par défaut des récompenses (jours, optionnel)',
                            hint: 'Ex: 30 — utilisée par les paliers sans validité propre, vide = jamais expirée',
                            controller: _rewardValidityDaysCtrl,
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

                          const SizedBox(height: Sp.xl),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Niveaux de fidélité',
                                  style: AppTextStyles.labelBold()),
                              Text(
                                '${_levelNameCtrls.length} niveau${_levelNameCtrls.length > 1 ? 'x' : ''}',
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.merchant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Sp.xs),
                          Text(
                            'Indépendants des récompenses : ils suivent la fidélité du '
                            'client dans la durée (${_getLevelUnit(loyaltyMode)}) et ne '
                            'sont jamais remis à zéro quand une récompense est débloquée.',
                            style: AppTextStyles.caption()
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: Sp.sm),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _levelNameCtrls.length,
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
                                            'Niveau #${index + 1}',
                                            style: AppTextStyles.caption().copyWith(
                                              color: AppColors.merchant,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2,
                                              size: 18, color: AppColors.danger),
                                          onPressed: () => _removeLevel(index),
                                          tooltip: 'Supprimer ce niveau',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Sp.sm),
                                    AppInput(
                                      label: 'Nom du niveau *',
                                      hint: 'Ex : Bronze',
                                      controller: _levelNameCtrls[index],
                                      prefixIcon: LucideIcons.award,
                                      accentColor: AppColors.merchant,
                                      validator: (v) {
                                        if ((v?.trim() ?? '').isEmpty) {
                                          return 'Le nom du niveau est obligatoire';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: Sp.sm),
                                    AppInput(
                                      label: 'Seuil (${_getLevelUnit(loyaltyMode)}) *',
                                      hint: 'Ex: 5',
                                      controller: _levelThresholdCtrls[index],
                                      keyboardType: TextInputType.number,
                                      prefixIcon: LucideIcons.trendingUp,
                                      accentColor: AppColors.merchant,
                                      onChanged: (_) => setState(() {}),
                                      validator: (v) {
                                        final parsed = int.tryParse(v?.trim() ?? '');
                                        if (parsed == null || parsed < 0) {
                                          return 'Veuillez entrer un nombre positif';
                                        }
                                        if (index > 0) {
                                          final prev = int.tryParse(
                                              _levelThresholdCtrls[index - 1].text.trim());
                                          if (prev != null && parsed <= prev) {
                                            return 'Doit être strictement supérieur au niveau précédent ($prev)';
                                          }
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

                          OutlinedButton.icon(
                            onPressed: _addNewLevel,
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
                              'Ajouter un niveau',
                              style: AppTextStyles.bodyMd().copyWith(
                                color: AppColors.merchant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          if (merchant != null && !merchant.isPro) ...[
                            const SizedBox(height: Sp.md),
                            Container(
                              padding: const EdgeInsets.all(Sp.md),
                              decoration: const BoxDecoration(
                                color: AppColors.warningTint,
                                borderRadius: Rd.card,
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.lock,
                                      color: AppColors.warning, size: 18),
                                  const SizedBox(width: Sp.sm),
                                  Expanded(
                                    child: Text(
                                      'Passez à Pro pour les statistiques avancées et SMS illimités.',
                                      style: AppTextStyles.caption()
                                          .copyWith(color: AppColors.warning),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                        MediaQuery.of(context).padding.bottom + Sp.md),
                    child: AppButton.primary('Enregistrer',
                        icon: LucideIcons.save,
                        onPressed: _save,
                        loading: _saving),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
