import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/domain/loyalty_level.dart';
import '../../../core/domain/tier_icon_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/tier_level_icon.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../onboarding/models/program_tier.dart';
import 'tier_icon_picker_sheet.dart';

/// Éditeur de paliers réutilisé par l'onboarding (step2) et les réglages
/// marchand — un palier = objectif + nom de niveau (masqué si un seul
/// palier) + récompense + validité optionnelle.
///
/// Nom/icône des 5 premiers paliers d'un programme multi-palier sont
/// imposés par leur position (`LoyaltyLevel.forPosition`, ordre Bronze <
/// Argent < Or < Platine < Fidèle), non éditables. Au-delà de la position
/// 5, le marchand choisit nom libre + icône (`TierIconPalette`).
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
  final List<String?> _iconKeys = [];
  final List<bool> _isExpanded = [];
  final List<bool> _revealReward = [];

  @override
  void initState() {
    super.initState();
    final tiers = widget.initialTiers.isEmpty && !widget.allowEmpty
        ? [const ProgramTier(goal: 10, rewardDescription: '')]
        : widget.initialTiers;
    for (int i = 0; i < tiers.length; i++) {
      _addController(tiers[i], expanded: false);
    }
  }

  void _addController(ProgramTier tier, {bool expanded = true}) {
    _goalCtrls.add(TextEditingController(text: tier.goal.toString()));
    _levelNameCtrls.add(TextEditingController(text: tier.levelName ?? ''));
    _descCtrls.add(TextEditingController(text: tier.rewardDescription));
    _validityCtrls
        .add(TextEditingController(text: tier.validityDays?.toString() ?? ''));
    _iconKeys.add(tier.iconKey);
    _isExpanded.add(expanded);
    _revealReward.add(tier.revealReward);
  }

  void _emitChange() {
    widget.onChanged(currentTiers());
  }

  /// Snapshot lisible par l'appelant à tout moment (ex. juste avant soumission).
  List<ProgramTier> currentTiers() {
    final isMultiTier = _goalCtrls.length > 1;
    return List.generate(_goalCtrls.length, (i) {
      final position = i + 1;
      final isLocked = position <= 5;
      return ProgramTier(
        goal: int.tryParse(_goalCtrls[i].text.trim()) ?? 10,
        levelName: !isMultiTier
            ? null
            : (isLocked
                ? LoyaltyLevel.forPosition(position)?.label
                : (_levelNameCtrls[i].text.trim().isNotEmpty
                    ? _levelNameCtrls[i].text.trim()
                    : null)),
        iconKey: !isMultiTier || isLocked ? null : _iconKeys[i],
        rewardDescription: _descCtrls[i].text.trim(),
        validityDays: int.tryParse(_validityCtrls[i].text.trim()),
        revealReward: _revealReward[i],
      );
    });
  }

  void addTier() {
    final lastGoal =
        _goalCtrls.isNotEmpty ? (int.tryParse(_goalCtrls.last.text) ?? 10) : 10;
    setState(() {
      for (int i = 0; i < _isExpanded.length; i++) {
        _isExpanded[i] = false;
      }
      _addController(ProgramTier(goal: lastGoal + widget.goalStep, rewardDescription: ''), expanded: true);
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
      _iconKeys.removeAt(index);
      _isExpanded.removeAt(index);
      _revealReward.removeAt(index);
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
    final t = AppLocalizations.of(context)!;
    final isMultiTier = _goalCtrls.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.merchantTierEditorTitle, style: AppTextStyles.labelBold()),
            Text(
              t.merchantTierEditorCount(_goalCtrls.length),
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.merchant, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (isMultiTier) ...[
          const SizedBox(height: Sp.xs),
          Text(
            'Chaque palier attribue un niveau et débloque sa propre '
            'récompense, sans jamais redescendre une fois atteint. Les 5 '
            'premiers niveaux (Bronze, Argent, Or, Platine, Fidèle) sont '
            'fixes ; au-delà, vous choisissez le nom et l\'icône.',
            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: Sp.sm),
        if (widget.allowEmpty && _goalCtrls.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.sm),
            child: Text(
              t.merchantTierEditorEmptyState,
              style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _goalCtrls.length,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
          itemBuilder: (context, index) {
            final isExpanded = _isExpanded[index];
            final position = index + 1;
            final isLocked = position <= 5;
            final fixedLevel = isLocked ? LoyaltyLevel.forPosition(position) : null;
            final levelName = _levelNameCtrls[index].text.trim();
            final goal = _goalCtrls[index].text.trim();
            final reward = _descCtrls[index].text.trim();

            final summaryTitle = !isMultiTier
                ? 'Palier ${index + 1}'
                : (isLocked
                    ? fixedLevel!.label
                    : (levelName.isNotEmpty ? levelName : 'Palier ${index + 1}'));
            String summarySubtitle = '';
            if (goal.isNotEmpty && reward.isNotEmpty) {
              summarySubtitle = '$goal ${widget.goalUnit} • $reward';
            } else if (goal.isNotEmpty) {
              summarySubtitle = '$goal ${widget.goalUnit}';
            } else if (reward.isNotEmpty) {
              summarySubtitle = reward;
            } else {
              summarySubtitle = t.merchantTierEditorConfigurePrompt;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isExpanded ? AppColors.merchant : AppColors.border,
                    width: isExpanded ? 2 : 1),
                boxShadow: [
                  BoxShadow(
                    color: (isExpanded ? AppColors.merchant : Colors.black)
                        .withValues(alpha: isExpanded ? 0.08 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded[index] = !isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(Sp.md),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isExpanded ? AppColors.merchantTint : AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: !isMultiTier
                                    ? const Icon(Icons.flag_outlined, size: 20)
                                    : TierLevelIcon(
                                        position: isLocked ? position : null,
                                        iconKey: isLocked ? null : _iconKeys[index],
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: Sp.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      summaryTitle,
                                      style: AppTextStyles.bodyMd().copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isExpanded ? AppColors.merchant : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (!isExpanded) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        summarySubtitle,
                                        style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_goalCtrls.length > 1)
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, size: isExpanded ? 20 : 18, color: isExpanded ? AppColors.danger : AppColors.textSecondary),
                                  onPressed: () => removeTier(index),
                                  tooltip: t.merchantTierEditorDeleteTooltip,
                                ),
                              const SizedBox(width: Sp.xs),
                              Icon(
                                isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                size: 20,
                                color: isExpanded ? AppColors.merchant : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity, height: 0),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: Sp.md),
                            AppInput(
                              label: t.merchantTierEditorGoalLabel(widget.goalUnit),
                              hint: t.merchantProgrammeRulesInputHint,
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
                                if (val.isEmpty) return t.merchantTierEditorGoalRequired;
                                final parsed = int.tryParse(val);
                                if (parsed == null || parsed <= 0) {
                                  return t.merchantProgrammeRulesValidatorError;
                                }
                                if (index > 0) {
                                  final prev = int.tryParse(_goalCtrls[index - 1].text.trim());
                                  if (prev != null && parsed <= prev) {
                                    return t.merchantTierEditorMustExceedPrevious(prev.toString());
                                  }
                                }
                                return null;
                              },
                            ),
                            if (isMultiTier) ...[
                              const SizedBox(height: Sp.sm),
                              if (isLocked) ...[
                                _LockedLevelPreview(level: fixedLevel!),
                              ] else ...[
                                AppInput(
                                  label: t.merchantTierEditorLevelNameLabel,
                                  hint: t.merchantTierEditorLevelNameHint,
                                  controller: _levelNameCtrls[index],
                                  prefixIcon: LucideIcons.award,
                                  accentColor: AppColors.merchant,
                                  onChanged: (_) {
                                    setState(() {});
                                    _emitChange();
                                  },
                                  validator: (v) => (v?.trim() ?? '').isEmpty
                                      ? t.merchantTierEditorLevelNameRequired
                                      : null,
                                ),
                                const SizedBox(height: Sp.sm),
                                _IconPickerField(
                                  iconKey: _iconKeys[index],
                                  onPick: () async {
                                    final picked = await showTierIconPickerSheet(context, _iconKeys[index]);
                                    if (picked != null) {
                                      setState(() => _iconKeys[index] = picked);
                                      _emitChange();
                                    }
                                  },
                                ),
                              ],
                            ],
                            const SizedBox(height: Sp.sm),
                            AppInput(
                              label: t.merchantTierEditorRewardLabel,
                              hint: t.merchantTierEditorRewardHint,
                              controller: _descCtrls[index],
                              prefixIcon: LucideIcons.gift,
                              accentColor: AppColors.merchant,
                              maxLength: 255,
                              onChanged: (_) {
                                setState(() {});
                                _emitChange();
                              },
                              validator: (v) => (v?.trim() ?? '').isEmpty
                                  ? t.merchantTierEditorRewardRequired
                                  : null,
                            ),
                            const SizedBox(height: Sp.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.merchantTierEditorSurpriseRewardLabel,
                                            style: AppTextStyles.caption()
                                                .copyWith(fontWeight: FontWeight.bold)),
                                        Text(
                                          t.merchantTierEditorSurpriseRewardHint,
                                          style: AppTextStyles.caption()
                                              .copyWith(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: !_revealReward[index],
                                    onChanged: (hide) {
                                      setState(() => _revealReward[index] = !hide);
                                      _emitChange();
                                    },
                                    activeThumbColor: AppColors.merchant,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Sp.sm),
                            AppInput(
                              label: t.merchantTierEditorValidityLabel,
                              hint: t.merchantTierEditorValidityHint,
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
                                  return t.merchantTierEditorValidityError;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Aperçu non modifiable du nom/icône imposés pour les 5 premiers paliers
/// (Bronze/Argent/Or/Platine/Fidèle).
class _LockedLevelPreview extends StatelessWidget {
  final LoyaltyLevel level;
  const _LockedLevelPreview({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(level.icon, size: 18, color: level.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Niveau : ${level.label}', style: AppTextStyles.bodyMd()),
          ),
          Icon(LucideIcons.lock, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// Déclencheur du sélecteur d'icône pour un palier custom (position > 5).
class _IconPickerField extends StatelessWidget {
  final String? iconKey;
  final VoidCallback onPick;
  const _IconPickerField({required this.iconKey, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final option = TierIconPalette.byKey(iconKey);
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(option.icon, size: 18, color: AppColors.merchant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                iconKey == null ? 'Choisir une icône' : option.label,
                style: AppTextStyles.bodyMd(),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
