import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_input.dart';
import '../../onboarding/models/program_tier.dart';

/// Icônes de niveau — automatiques par rang, jamais choisies par le
/// marchand (miroir de `LoyaltyTierService::iconForRank` côté API).
const List<String> tierRankIcons = ['🥉', '🥈', '🥇', '💎', '👑'];
String iconForTierRank(int rank) =>
    rank >= 1 && rank <= tierRankIcons.length ? tierRankIcons[rank - 1] : '⭐';

/// Éditeur de paliers réutilisé par l'onboarding (step2) et les réglages
/// marchand — un palier = objectif + nom de niveau (masqué si un seul
/// palier) + récompense + validité optionnelle.
class TierEditorForm extends StatefulWidget {
  final List<ProgramTier> initialTiers;
  final String goalUnit;
  final ValueChanged<List<ProgramTier>> onChanged;
  final bool allowEmpty;
  final int goalStep;

  const TierEditorForm({
    super.key,
    required this.initialTiers,
    required this.goalUnit,
    required this.onChanged,
    this.allowEmpty = false,
    this.goalStep = 500,
  });

  @override
  State<TierEditorForm> createState() => TierEditorFormState();
}

class TierEditorFormState extends State<TierEditorForm> {
  final List<TextEditingController> _goalCtrls = [];
  final List<TextEditingController> _levelNameCtrls = [];
  final List<TextEditingController> _descCtrls = [];
  final List<TextEditingController> _validityCtrls = [];

  @override
  void initState() {
    super.initState();
    final tiers = widget.initialTiers.isEmpty && !widget.allowEmpty
        ? [const ProgramTier(goal: 10, rewardDescription: '')]
        : widget.initialTiers;
    for (final tier in tiers) {
      _addController(tier);
    }
  }

  void _addController(ProgramTier tier) {
    _goalCtrls.add(TextEditingController(text: tier.goal.toString()));
    _levelNameCtrls.add(TextEditingController(text: tier.levelName ?? ''));
    _descCtrls.add(TextEditingController(text: tier.rewardDescription));
    _validityCtrls
        .add(TextEditingController(text: tier.validityDays?.toString() ?? ''));
  }

  void _emitChange() {
    widget.onChanged(currentTiers());
  }

  /// Snapshot lisible par l'appelant à tout moment (ex. juste avant soumission).
  List<ProgramTier> currentTiers() {
    return List.generate(_goalCtrls.length, (i) {
      return ProgramTier(
        goal: int.tryParse(_goalCtrls[i].text.trim()) ?? 10,
        levelName: _goalCtrls.length > 1 && _levelNameCtrls[i].text.trim().isNotEmpty
            ? _levelNameCtrls[i].text.trim()
            : null,
        rewardDescription: _descCtrls[i].text.trim(),
        validityDays: int.tryParse(_validityCtrls[i].text.trim()),
      );
    });
  }

  void addTier() {
    final lastGoal =
        _goalCtrls.isNotEmpty ? (int.tryParse(_goalCtrls.last.text) ?? 10) : 10;
    setState(() {
      _addController(ProgramTier(goal: lastGoal + widget.goalStep, rewardDescription: ''));
    });
    _emitChange();
  }

  void removeTier(int index) {
    if (_goalCtrls.length <= (widget.allowEmpty ? 0 : 1)) return;
    setState(() {
      _goalCtrls[index].dispose();
      _levelNameCtrls[index].dispose();
      _descCtrls[index].dispose();
      _validityCtrls[index].dispose();
      _goalCtrls.removeAt(index);
      _levelNameCtrls.removeAt(index);
      _descCtrls.removeAt(index);
      _validityCtrls.removeAt(index);
    });
    _emitChange();
  }

  @override
  void dispose() {
    for (final c in [..._goalCtrls, ..._levelNameCtrls, ..._descCtrls, ..._validityCtrls]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiTier = _goalCtrls.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Vos paliers', style: AppTextStyles.labelBold()),
            Text(
              '${_goalCtrls.length} palier${_goalCtrls.length > 1 ? 's' : ''}',
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (isMultiTier) ...[
          const SizedBox(height: Sp.xs),
          Text(
            'Chaque palier attribue un niveau nommé par vous et débloque sa '
            'propre récompense, sans jamais redescendre une fois atteint.',
            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: Sp.sm),
        if (widget.allowEmpty && _goalCtrls.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.sm),
            child: Text(
              'Aucun palier configuré — le cashback fonctionne normalement sans palier.',
              style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _goalCtrls.length,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
          itemBuilder: (context, index) => Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.merchantTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${iconForTierRank(index + 1)} Palier ${index + 1}',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    if (_goalCtrls.length > 1)
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                        onPressed: () => removeTier(index),
                        tooltip: 'Supprimer ce palier',
                      ),
                  ],
                ),
                const SizedBox(height: Sp.sm),
                AppInput(
                  label: 'Objectif (${widget.goalUnit}) *',
                  hint: 'Ex: 500',
                  controller: _goalCtrls[index],
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.target,
                  accentColor: AppColors.merchant,
                  onChanged: (_) {
                    setState(() {});
                    _emitChange();
                  },
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return "L'objectif est obligatoire";
                    final parsed = int.tryParse(val);
                    if (parsed == null || parsed <= 0) {
                      return 'Veuillez entrer un nombre supérieur à 0';
                    }
                    if (index > 0) {
                      final prev = int.tryParse(_goalCtrls[index - 1].text.trim());
                      if (prev != null && parsed <= prev) {
                        return 'Doit être supérieur au palier précédent ($prev)';
                      }
                    }
                    return null;
                  },
                ),
                if (isMultiTier) ...[
                  const SizedBox(height: Sp.sm),
                  AppInput(
                    label: 'Nom du niveau *',
                    hint: 'Ex : Découverte, Habitué, VIP',
                    controller: _levelNameCtrls[index],
                    prefixIcon: LucideIcons.award,
                    accentColor: AppColors.merchant,
                    onChanged: (_) => _emitChange(),
                    validator: (v) => (v?.trim() ?? '').isEmpty
                        ? 'Le nom du niveau est obligatoire'
                        : null,
                  ),
                ],
                const SizedBox(height: Sp.sm),
                AppInput(
                  label: 'Récompense offerte *',
                  hint: 'Ex : 1 café offert, 10% de réduction',
                  controller: _descCtrls[index],
                  prefixIcon: LucideIcons.gift,
                  accentColor: AppColors.merchant,
                  maxLength: 255,
                  onChanged: (_) => _emitChange(),
                  validator: (v) => (v?.trim() ?? '').isEmpty
                      ? 'La description de la récompense est obligatoire'
                      : null,
                ),
                const SizedBox(height: Sp.sm),
                AppInput(
                  label: 'Validité (jours, optionnel)',
                  hint: "Ex: 30 — vide = pas d'expiration",
                  controller: _validityCtrls[index],
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.calendarClock,
                  accentColor: AppColors.merchant,
                  onChanged: (_) => _emitChange(),
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
          ),
        ),
      ],
    );
  }
}
