import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
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
    this.onRedeemCashback,
  });

  final LoyaltyCardModel card;

  /// `stamps`, `spend` ou `cashback` — voir `loyalty_programs.type` côté API.
  final String mechanic;
  final int goal;
  final int fcfaPerPoint;
  final double cashbackPercentage;
  final ValueChanged<double?> onValidate;

  /// Mode Cashback uniquement : utilisation d'une partie du solde comme
  /// réduction sur l'achat en cours — `(montantAchat, montantUtilisé)`, le
  /// premier sert de base au plafond serveur (`cashback_redeem_cap_percent`).
  final void Function(double purchaseAmount, double redeemAmount)? onRedeemCashback;

  @override
  State<ClientCardSheet> createState() => _ClientCardSheetState();
}

class _ClientCardSheetState extends State<ClientCardSheet> {
  final _amountCtrl = TextEditingController();
  final _redeemCtrl = TextEditingController();
  double? _amount;
  double? _redeemAmount;
  bool _submitting = false;
  bool _showRedeemPanel = false;

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

  bool get _canSubmit {
    if (_submitting || !_isActive) return false;
    if (_isSpend) return _pointsPreview >= 1;
    if (_isCashback) return (_amount ?? 0) > 0;
    return true;
  }

  bool get _canRedeem {
    if (_submitting || !_isActive) return false;
    final amount = _redeemAmount ?? 0;
    final purchase = _amount ?? 0;
    return purchase > 0 && amount > 0 && amount <= widget.card.cashbackBalanceFcfa;
  }

  String get _actionLabel {
    if (!_isActive) return 'Carte inactive';
    switch (widget.mechanic) {
      case 'spend':
        return 'Confirmer et créditer';
      case 'cashback':
        return 'Créditer le cashback';
      default:
        return 'Valider le tampon';
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

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final name = card.client?.name ?? 'Client';
    final phone = card.client?.phone ?? '';
    final initials = card.client?.initials ?? '?';
    final since = DateFormatter.memberSince(card.createdAt);
    final progress = card.progressRatio(widget.goal);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                                    _LevelBadge(name: card.levelName!),
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
                            child: Text('Inactive',
                                style: AppTextStyles.caption().copyWith(
                                    color: AppColors.danger, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const Divider(height: Sp.lg),
                    ..._buildProgress(progress),
                    if (_isSpend || _isCashback) ...[
                      const SizedBox(height: Sp.md),
                      TextField(
                        controller: _amountCtrl,
                        enabled: _isActive,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        decoration: InputDecoration(
                          labelText: 'Montant de l\'achat',
                          suffixText: 'FCFA',
                          border: const OutlineInputBorder(borderRadius: Rd.input),
                          helperText: _isCashback
                              ? '${widget.cashbackPercentage.toStringAsFixed(widget.cashbackPercentage % 1 == 0 ? 0 : 1)}% crédités en cashback'
                              : '1 point tous les ${widget.fcfaPerPoint} FCFA d\'achat',
                        ),
                        onChanged: (v) => setState(() => _amount = double.tryParse(v.trim())),
                      ),
                      const SizedBox(height: Sp.sm),
                      Text(
                        _amount == null
                            ? (_isCashback
                                ? 'Saisissez le montant pour voir le cashback crédité.'
                                : 'Saisissez le montant pour voir les points crédités.')
                            : (_isCashback
                                ? '= ${_cashbackPreview.round()} FCFA de cashback crédités'
                                : '= $_pointsPreview point(s) crédité(s)'),
                        style: AppTextStyles.bodyMd().copyWith(
                          color: (_isCashback ? _cashbackPreview > 0 : _pointsPreview >= 1)
                              ? AppColors.merchant
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: Sp.lg),
                    AppButton.primary(_actionLabel, onPressed: _canSubmit ? _submit : null, loading: _submitting),
                    if (_isCashback && widget.card.cashbackBalanceFcfa > 0) ...[
                      const SizedBox(height: Sp.sm),
                      AppButton.ghost(
                        _showRedeemPanel ? 'Masquer l\'utilisation du cashback' : 'Utiliser le cashback',
                        onPressed: () => setState(() => _showRedeemPanel = !_showRedeemPanel),
                      ),
                      if (_showRedeemPanel) ...[
                        const SizedBox(height: Sp.sm),
                        if (_amount == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Sp.xs),
                            child: Text(
                              'Renseignez d\'abord le montant de l\'achat ci-dessus.',
                              style: AppTextStyles.caption().copyWith(color: AppColors.danger),
                            ),
                          ),
                        TextField(
                          controller: _redeemCtrl,
                          enabled: _isActive,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          decoration: InputDecoration(
                            labelText: 'Montant de cashback à utiliser',
                            suffixText: 'FCFA',
                            border: const OutlineInputBorder(borderRadius: Rd.input),
                            helperText:
                                'Solde disponible : ${widget.card.cashbackBalanceFcfa.round()} FCFA',
                          ),
                          onChanged: (v) =>
                              setState(() => _redeemAmount = double.tryParse(v.trim())),
                        ),
                        const SizedBox(height: Sp.sm),
                        AppButton.primary(
                          'Confirmer l\'utilisation',
                          onPressed: _canRedeem ? _submitRedeem : null,
                          loading: _submitting,
                        ),
                      ],
                    ],
                    const SizedBox(height: Sp.sm),
                    AppButton.ghost('Annuler', onPressed: () => Navigator.pop(context)),
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

  List<Widget> _buildProgress(double progress) {
    if (widget.mechanic == 'cashback') {
      return [
        Row(
          children: [
            const Icon(LucideIcons.wallet, size: 14, color: AppColors.merchant),
            const SizedBox(width: 6),
            Text('CASHBACK',
                style: AppTextStyles.caption().copyWith(
                    color: AppColors.merchant, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: Sp.xs),
        Text('${widget.card.cashbackBalanceFcfa.round()} FCFA',
            style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w900, color: AppColors.merchant)),
        Text('solde disponible',
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
        Text('${widget.card.stampsCount} sur ${widget.goal} tampons',
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
          Text(isSpend ? 'ACHATS' : 'POINTS',
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.merchant, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ],
      ),
      const SizedBox(height: Sp.xs),
      Text('${widget.card.stampsCount}',
          style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w900, color: AppColors.merchant)),
      Text('sur ${widget.goal} ${isSpend ? "pts (achats)" : "points"}',
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
  const _LevelBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.merchantTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name.toUpperCase(),
        style: AppTextStyles.caption().copyWith(
          color: AppColors.merchant,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
