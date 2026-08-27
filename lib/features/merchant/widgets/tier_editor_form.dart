import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_input.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../onboarding/models/program_tier.dart';

/// Icônes de niveau — automatiques par rang, jamais choisies par le
/// marchand (miroir de `LoyaltyTierService::iconForRank` côté API : mise à
/// l'échelle sur `totalTiers` pour que le dernier palier obtienne toujours
/// l'icône maximale 👑, même avec seulement 2 paliers).
const List<String> tierRankIcons = ['🥉', '🥈', '🥇', '💎', '👑'];
String iconForTierRank(int rank, int totalTiers) {
  final maxIndex = tierRankIcons.length - 1;
  final index = totalTiers <= 1
      ? maxIndex
      : (((rank - 1) / (totalTiers - 1)) * maxIndex).round();
  return tierRankIcons[index.clamp(0, maxIndex)];
}

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
    _isExpanded.add(expanded);
    _revealReward.add(tier.revealReward);
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
            t.merchantTierEditorMultiTierHint,
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
            final levelName = _levelNameCtrls[index].text.trim();
            final goal = _goalCtrls[index].text.trim();
            final reward = _descCtrls[index].text.trim();

            final summaryTitle = levelName.isNotEmpty ? levelName : t.merchantTierEditorDefaultTierName((index + 1).toString());
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
                                child: Text(
                                  iconForTierRank(index + 1, _goalCtrls.length),
                                  style: const TextStyle(fontSize: 20),
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
