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
    this.fcfaPerPoint = 500,
  });

  final LoyaltyCardModel card;

  /// `stamps`, `points` ou `spend` — voir `loyalty_programs.type` côté API.
  final String mechanic;
  final int goal;
  final int fcfaPerPoint;
  final ValueChanged<double?> onValidate;

  @override
  State<ClientCardSheet> createState() => _ClientCardSheetState();
}

class _ClientCardSheetState extends State<ClientCardSheet> {
  final _amountCtrl = TextEditingController();
  double? _amount;
  bool _submitting = false;

  bool get _isSpend => widget.mechanic == 'spend';
  bool get _isActive => widget.card.status == 'active' || widget.card.hasRewardAvailable;

  int get _pointsPreview {
    if (_amount == null || widget.fcfaPerPoint <= 0) return 0;
    return _amount! ~/ widget.fcfaPerPoint;
  }

  bool get _canSubmit {
    if (_submitting || !_isActive) return false;
    if (_isSpend) return _pointsPreview >= 1;
    return true;
  }

  String get _actionLabel {
    if (!_isActive) return 'Carte inactive';
    switch (widget.mechanic) {
      case 'points':
        return 'Valider les points';
      case 'spend':
        return 'Confirmer et créditer';
      default:
        return 'Valider le tampon';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    widget.onValidate(_isSpend ? _amount : null);
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
                              Text(name, style: AppTextStyles.labelBold()),
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
                    if (_isSpend) ...[
                      const SizedBox(height: Sp.md),
                      TextField(
                        controller: _amountCtrl,
                        enabled: _isActive,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        decoration: InputDecoration(
                          labelText: 'Montant de l\'achat',
                          suffixText: 'FCFA',
                          border: const OutlineInputBorder(borderRadius: Rd.input),
                          helperText: '1 point tous les ${widget.fcfaPerPoint} FCFA d\'achat',
                        ),
                        onChanged: (v) => setState(() => _amount = double.tryParse(v.trim())),
                      ),
                      const SizedBox(height: Sp.sm),
                      Text(
                        _amount == null
                            ? 'Saisissez le montant pour voir les points crédités.'
                            : '= $_pointsPreview point(s) crédité(s)',
                        style: AppTextStyles.bodyMd().copyWith(
                          color: _pointsPreview >= 1 ? AppColors.merchant : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: Sp.lg),
                    AppButton.primary(_actionLabel, onPressed: _canSubmit ? _submit : null, loading: _submitting),
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
