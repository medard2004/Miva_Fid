import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/tier_level_icon.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/loyalty_card_model.dart';
import 'stamp_grid_widget.dart';

/// Feuille de validation après scan/recherche — contenu adapté au mode du
/// programme de fidélité (`stamps`/`points`/`spend`) : grille de tampons,
/// gros compteur de points, ou saisie de montant avec aperçu de points en
/// mode "Achat". [onValidate] reçoit le montant saisi (mode "Achat"
/// uniquement, sinon `null`).
class ClientCardSheet extends StatefulWidget {
  const ClientCardSheet({
    super.key,
    required this.card,
    required this.mechanic,
    required this.goal,
    required this.onValidate,
    this.fcfaPerPoint = 100,
    this.cashbackPercentage = 0,
    this.cashbackRedeemThresholdFcfa,
    this.onRedeemCashback,
  });

  final LoyaltyCardModel card;

  /// `stamps`, `spend` ou `cashback` — voir `loyalty_programs.type` côté API.
  final String mechanic;
  final int goal;
  final int fcfaPerPoint;
  final double cashbackPercentage;

  /// Mode Cashback uniquement : solde minimum (FCFA) que le client doit
  /// avoir atteint pour pouvoir l'utiliser — `null` = pas de seuil.
  final double? cashbackRedeemThresholdFcfa;
  final ValueChanged<double?> onValidate;

  /// Mode Cashback uniquement : utilisation d'une partie du solde comme
  /// réduction sur l'achat en cours — `(montantAchat, montantUtilisé)`.
  final void Function(double purchaseAmount, double redeemAmount)? onRedeemCashback;

  @override
  State<ClientCardSheet> createState() => _ClientCardSheetState();
}

/// Étape du parcours cashback — un scan ne peut mener qu'à UNE seule
/// opération (créditer OU utiliser, jamais les deux) : le choix est fait une
/// fois pour toutes en [choice], irréversible sans fermer et rouvrir la
/// fiche (bouton "Annuler").
enum _CashbackStep { choice, form, summary }

class _ClientCardSheetState extends State<ClientCardSheet> {
  final _amountCtrl = TextEditingController();
  final _redeemCtrl = TextEditingController();
  double? _amount;
  double? _redeemAmount;
  bool _submitting = false;

  _CashbackStep _cbStep = _CashbackStep.choice;
  bool _cbIsRedeem = false;

  bool get _isSpend => widget.mechanic == 'spend';
  bool get _isCashback => widget.mechanic == 'cashback';
  bool get _isActive => widget.card.status == 'active' || widget.card.hasRewardAvailable;

  int get _pointsPreview {
    if (_amount == null || widget.fcfaPerPoint <= 0) return 0;
    return _amount! ~/ widget.fcfaPerPoint;
  }

  double get _cashbackPreview {
    if (_amount == null) return 0;
    return (_amount! * widget.cashbackPercentage / 100 * 100).round() / 100;
  }

  /// Achat moins cashback utilisé — jamais négatif (la validation empêche
  /// déjà un cashback supérieur à l'achat, ce clamp ne sert qu'à l'affichage
  /// pendant la saisie, avant que la validation soit satisfaite).
  double get _amountToPay => ((_amount ?? 0) - (_redeemAmount ?? 0)).clamp(0, double.infinity);

  bool get _canSubmit {
    if (_submitting || !_isActive) return false;
    if (_isSpend) return _pointsPreview >= 1;
    if (_isCashback) return (_amount ?? 0) > 0;
    return true;
  }

  /// Seuil configuré et non atteint par le solde actuel de la carte.
  bool get _belowRedeemThreshold {
    final threshold = widget.cashbackRedeemThresholdFcfa;
    return threshold != null && widget.card.cashbackBalanceFcfa < threshold;
  }

  bool get _canRedeem {
    if (_submitting || !_isActive || _belowRedeemThreshold) return false;
    final amount = _redeemAmount ?? 0;
    final purchase = _amount ?? 0;
    return purchase > 0 &&
        amount > 0 &&
        amount <= widget.card.cashbackBalanceFcfa &&
        amount <= purchase;
  }

  String _actionLabel(AppLocalizations t) {
    if (!_isActive) return t.merchantValidateCardInactive;
    switch (widget.mechanic) {
      case 'spend':
        return t.merchantValidateConfirmAndCredit;
      case 'cashback':
        return t.merchantValidateCreditCashback;
      default:
        return t.merchantValidateValidateStamp;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _redeemCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    widget.onValidate(_isSpend || _isCashback ? _amount : null);
  }

  void _submitRedeem() {
    if (!_canRedeem) return;
    setState(() => _submitting = true);
    widget.onRedeemCashback?.call(_amount!, _redeemAmount!);
  }

  String _fcfa(double v) => '${v.round()} FCFA';

  /// Parcours cashback en 3 étapes — choix irréversible avant toute saisie
  /// (jamais crédit+utilisation dans la même opération, voir section 5 du
  /// cahier des charges), puis résumé obligatoire avant confirmation finale.
  List<Widget> _buildCashbackFlow(AppLocalizations t) {
    switch (_cbStep) {
      case _CashbackStep.choice:
        return _buildCashbackChoiceStep(t);
      case _CashbackStep.form:
        return _buildCashbackFormStep(t);
      case _CashbackStep.summary:
        return _buildCashbackSummaryStep(t);
    }
  }

  List<Widget> _buildCashbackChoiceStep(AppLocalizations t) {
    final hasBalance = widget.card.cashbackBalanceFcfa > 0;
    final canRedeemNow = hasBalance && !_belowRedeemThreshold;
    return [
      AppButton.primary(
        t.merchantValidateCreditCashbackButton,
        onPressed: _isActive
            ? () => setState(() {
                  _cbIsRedeem = false;
                  _cbStep = _CashbackStep.form;
                })
            : null,
      ),
      const SizedBox(height: Sp.sm),
      AppButton.outlined(
        t.merchantValidateRedeemCashbackButton,
        onPressed: _isActive && canRedeemNow
            ? () => setState(() {
                  _cbIsRedeem = true;
                  _cbStep = _CashbackStep.form;
                })
            : null,
      ),
      if (_isActive && !hasBalance) ...[
        const SizedBox(height: Sp.xs),
        Text(t.merchantValidateNoCashbackBalance,
            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
      ] else if (_isActive && _belowRedeemThreshold) ...[
        const SizedBox(height: Sp.xs),
        Text(
          t.merchantValidateBelowCashbackThreshold(
            _fcfa(widget.cashbackRedeemThresholdFcfa!),
            _fcfa(widget.card.cashbackBalanceFcfa),
          ),
          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
        ),
      ],
      const SizedBox(height: Sp.sm),
      AppButton.ghost(t.commonCancel, onPressed: () => Navigator.pop(context)),
    ];
  }

  List<Widget> _buildCashbackFormStep(AppLocalizations t) {
    return [
      TextField(
        controller: _amountCtrl,
        enabled: _isActive,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        decoration: InputDecoration(
          labelText: t.merchantValidatePurchaseAmountLabel,
          suffixText: 'FCFA',
          border: const OutlineInputBorder(borderRadius: Rd.input),
          helperText: !_cbIsRedeem
              ? t.merchantValidateCashbackCreditedHelper(widget.cashbackPercentage
                  .toStringAsFixed(widget.cashbackPercentage % 1 == 0 ? 0 : 1))
              : null,
        ),
        onChanged: (v) => setState(() => _amount = double.tryParse(v.trim())),
      ),
      if (!_cbIsRedeem) ...[
        const SizedBox(height: Sp.sm),
        Text(
          _amount == null
              ? t.merchantValidateEnterAmountCashbackHint
              : t.merchantValidateCashbackCreditedResult(_fcfa(_cashbackPreview)),
          style: AppTextStyles.bodyMd().copyWith(
            color: _cashbackPreview > 0 ? AppColors.merchant : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ] else ...[
        const SizedBox(height: Sp.sm),
        TextField(
          controller: _redeemCtrl,
          enabled: _isActive,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            labelText: t.merchantValidateCashbackToUseLabel,
            suffixText: 'FCFA',
            border: const OutlineInputBorder(borderRadius: Rd.input),
            helperText: t.merchantValidateAvailableBalance(_fcfa(widget.card.cashbackBalanceFcfa)),
          ),
          onChanged: (v) => setState(() => _redeemAmount = double.tryParse(v.trim())),
        ),
        const SizedBox(height: Sp.sm),
        Text(
          t.merchantValidateAmountToPay(_fcfa(_amountToPay)),
          style: AppTextStyles.bodyMd().copyWith(
            color: AppColors.merchant,
            fontWeight: FontWeight.w700,
          ),
        ),
        if ((_redeemAmount ?? 0) > (widget.card.cashbackBalanceFcfa)) ...[
          const SizedBox(height: Sp.xs),
          Text(t.merchantValidateExceedsBalance,
              style: AppTextStyles.caption().copyWith(color: AppColors.danger)),
        ] else if ((_redeemAmount ?? 0) > (_amount ?? 0) && (_amount ?? 0) > 0) ...[
          const SizedBox(height: Sp.xs),
          Text(t.merchantValidateExceedsPurchase,
              style: AppTextStyles.caption().copyWith(color: AppColors.danger)),
        ],
      ],
      const SizedBox(height: Sp.lg),
      AppButton.primary(
        t.merchantValidateViewSummaryButton,
        onPressed: (_cbIsRedeem ? _canRedeem : _canSubmit)
            ? () => setState(() => _cbStep = _CashbackStep.summary)
            : null,
      ),
      const SizedBox(height: Sp.sm),
      AppButton.ghost(t.commonBack, onPressed: () => setState(() => _cbStep = _CashbackStep.choice)),
    ];
  }

  List<Widget> _buildCashbackSummaryStep(AppLocalizations t) {
    final newBalance = _cbIsRedeem
        ? widget.card.cashbackBalanceFcfa - (_redeemAmount ?? 0)
        : widget.card.cashbackBalanceFcfa + _cashbackPreview;

    return [
      Container(
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(t.merchantValidateSummaryPurchase, _fcfa(_amount ?? 0)),
            if (_cbIsRedeem) ...[
              _summaryRow(t.merchantValidateSummaryCashbackUsed, '- ${_fcfa(_redeemAmount ?? 0)}'),
              const Divider(height: Sp.md),
              _summaryRow(t.merchantValidateSummaryToPay, _fcfa(_amountToPay), emphasize: true),
            ] else ...[
              _summaryRow(t.merchantValidateSummaryCashbackGenerated, '+ ${_fcfa(_cashbackPreview)}'),
            ],
            const SizedBox(height: 4),
            _summaryRow(t.merchantValidateSummaryNewBalance, _fcfa(newBalance)),
          ],
        ),
      ),
      const SizedBox(height: Sp.lg),
      AppButton.primary(
        _cbIsRedeem ? t.merchantValidateConfirmUsageButton : t.merchantValidateCreditCashback,
        onPressed: (_cbIsRedeem ? _canRedeem : _canSubmit)
            ? (_cbIsRedeem ? _submitRedeem : _submit)
            : null,
        loading: _submitting,
      ),
      const SizedBox(height: Sp.sm),
      AppButton.ghost(
        t.commonEdit,
        onPressed: _submitting ? null : () => setState(() => _cbStep = _CashbackStep.form),
      ),
    ];
  }

  Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTextStyles.bodyMd().copyWith(
              fontWeight: FontWeight.w700,
              color: emphasize ? AppColors.merchant : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final card = widget.card;
    final name = card.client?.name ?? 'Client';
    final phone = card.client?.phone ?? '';
    final initials = card.client?.initials ?? '?';
    final since = DateFormatter.memberSince(card.createdAt);
    final progress = card.progressRatio(widget.goal);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          // Le clavier (saisie du montant, mode "Achat") réduit la hauteur
          // disponible du sheet : sans scroll, le contenu (compteur, champ,
          // aperçu, boutons) débordait au lieu de défiler.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              Padding(
                padding: const EdgeInsets.all(Sp.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryTint,
                          child: Text(initials,
                              style: AppTextStyles.mono()
                                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: Sp.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(name,
                                        style: AppTextStyles.labelBold(),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  if (card.levelName != null) ...[
                                    const SizedBox(width: 6),
                                    _LevelBadge(
                                      name: card.levelName!,
                                      position: card.levelPosition,
                                      iconKey: card.levelIconKey,
                                    ),
                                  ],
                                ],
                              ),
                              if (phone.isNotEmpty)
                                Text(phone,
                                    style: AppTextStyles.caption()
                                        .copyWith(color: AppColors.textSecondary)),
                              Text(since,
                                  style: AppTextStyles.caption()
                                      .copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (!_isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.dangerTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(t.merchantValidateInactiveBadge,
                                style: AppTextStyles.caption().copyWith(
                                    color: AppColors.danger, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const Divider(height: Sp.lg),
                    ..._buildProgress(t, progress),
                    if (_isCashback) ...[
                      const SizedBox(height: Sp.md),
                      ..._buildCashbackFlow(t),
                    ] else ...[
                      if (_isSpend) ...[
                        const SizedBox(height: Sp.md),
                        TextField(
                          controller: _amountCtrl,
                          enabled: _isActive,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          decoration: InputDecoration(
                            labelText: t.merchantValidatePurchaseAmountLabel,
                            suffixText: 'FCFA',
                            border: const OutlineInputBorder(borderRadius: Rd.input),
                            helperText: t.merchantValidatePointsRatioHelper(widget.fcfaPerPoint.toString()),
                          ),
                          onChanged: (v) => setState(() => _amount = double.tryParse(v.trim())),
                        ),
                        const SizedBox(height: Sp.sm),
                        Text(
                          _amount == null
                              ? t.merchantValidateEnterAmountPointsHint
                              : t.merchantValidatePointsCreditedResult(_pointsPreview.toString()),
                          style: AppTextStyles.bodyMd().copyWith(
                            color: _pointsPreview >= 1 ? AppColors.merchant : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: Sp.lg),
                      AppButton.primary(_actionLabel(t), onPressed: _canSubmit ? _submit : null, loading: _submitting),
                      const SizedBox(height: Sp.sm),
                      AppButton.ghost(t.commonCancel, onPressed: () => Navigator.pop(context)),
                    ],
                    SizedBox(height: MediaQuery.of(context).padding.bottom + Sp.sm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProgress(AppLocalizations t, double progress) {
    if (widget.mechanic == 'cashback') {
      return [
        Row(
          children: [
            const Icon(LucideIcons.wallet, size: 14, color: AppColors.merchant),
            const SizedBox(width: 6),
            Text(t.merchantValidateCashbackLabel,
                style: AppTextStyles.caption().copyWith(
                    color: AppColors.merchant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: Sp.xs),
        Text('${widget.card.cashbackBalanceFcfa.round()} FCFA',
            style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w900, color: AppColors.merchant)),
        Text(t.merchantValidateAvailableBalanceLabel,
            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
      ];
    }
    if (widget.mechanic == 'stamps') {
      return [
        StampGridWidget(
          filled: widget.card.stampsCount,
          total: widget.goal,
          stampSize: 28,
          primaryColor: AppColors.primary,
        ),
        const SizedBox(height: Sp.sm),
        Text(t.merchantValidateStampProgressSubtitle(widget.card.stampsCount.toString(), widget.goal.toString()),
            style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: Sp.xs),
        _progressBar(progress),
      ];
    }
    // points/spend : compteur en gros plutôt qu'une grille, plus lisible
    // pour des seuils élevés (100 à 2000).
    final isSpend = widget.mechanic == 'spend';
    return [
      Row(
        children: [
          Icon(isSpend ? LucideIcons.shoppingBag : LucideIcons.coins,
              size: 14, color: AppColors.merchant),
          const SizedBox(width: 6),
          Text(isSpend ? t.merchantValidatePurchasesLabel : t.merchantValidatePointsLabel,
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.merchant, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ],
      ),
      const SizedBox(height: Sp.xs),
      Text('${widget.card.stampsCount}',
          style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w900, color: AppColors.merchant)),
      Text(
          isSpend
              ? t.merchantValidateSpendGoalLabel(widget.goal.toString())
              : t.merchantValidatePointsGoalLabel(widget.goal.toString()),
          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: Sp.sm),
      _progressBar(progress),
    ];
  }

  Widget _progressBar(double progress) {
    return ClipRRect(
      borderRadius: Rd.pill,
      child: LinearProgressIndicator(
        value: progress,
        color: AppColors.primary,
        backgroundColor: AppColors.border,
        minHeight: 8,
      ),
    );
  }
}

/// Badge de niveau de fidélité (Bronze/Argent/Or...) affiché à côté du nom
/// du client pendant la validation — répond à "Consulter le niveau de
/// fidélité du client" côté marchand, jusque-là visible uniquement côté app
/// client.
class _LevelBadge extends StatelessWidget {
  final String name;
  final int? position;
  final String? iconKey;
  const _LevelBadge({required this.name, this.position, this.iconKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.merchantTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TierLevelIcon(position: position, iconKey: iconKey, size: 11, color: AppColors.merchant),
          const SizedBox(width: 4),
          Text(
            name.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: AppColors.merchant,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
