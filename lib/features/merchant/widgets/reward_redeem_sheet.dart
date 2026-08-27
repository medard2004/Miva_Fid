import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/validate_provider.dart';

/// Feuille de confirmation après scan d'un QR de récompense — affiche le
/// détail résolu côté serveur (`MerchantReward`) et propose de valider
/// (consomme la récompense) ou de l'annuler (erreur de saisie, fraude).
/// Une récompense déjà utilisée/annulée/expirée n'affiche que son état,
/// sans action possible.
class RewardRedeemSheet extends StatefulWidget {
  const RewardRedeemSheet({
    super.key,
    required this.reward,
    required this.onRedeem,
    required this.onCancel,
  });

  final MerchantReward reward;
  final Future<void> Function() onRedeem;
  final Future<void> Function(String? reason) onCancel;

  @override
  State<RewardRedeemSheet> createState() => _RewardRedeemSheetState();
}

class _RewardRedeemSheetState extends State<RewardRedeemSheet> {
  bool _submitting = false;

  String _statusLabel(AppLocalizations t) {
    if (widget.reward.status == 'used') return t.merchantValidateRewardStatusUsed;
    if (widget.reward.status == 'canceled') return t.merchantValidateRewardStatusCanceled;
    if (widget.reward.isExpired) return t.merchantValidateRewardStatusExpired;
    return t.merchantValidateRewardStatusAvailable;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _submitting = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final reward = widget.reward;
    // `showModalBottomSheet` est ouvert avec `backgroundColor: transparent`
    // (voir validate_screen.dart) : sans ce conteneur, le contenu se
    // retrouvait rendu à même le fond assombri, sans carte ni coins arrondis.
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  Row(
                    children: [
                      const Icon(LucideIcons.gift, color: AppColors.merchant),
                      const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Text(t.merchantValidateRewardSheetTitle, style: AppTextStyles.h3()),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.md),
                  Text(reward.title, style: AppTextStyles.labelBold()),
                  if (reward.clientName != null) ...[
                    const SizedBox(height: 4),
                    Text(t.merchantValidateRewardClientLabel(reward.clientName!), style: AppTextStyles.bodyMd()),
                  ],
                  const SizedBox(height: 4),
                  Text(_statusLabel(t),
                      style: AppTextStyles.bodyMd().copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: Sp.lg),
                  if (reward.isRedeemable) ...[
                    AppButton.primary(
                      t.merchantValidateRewardConfirmButton,
                      icon: LucideIcons.checkCheck,
                      loading: _submitting,
                      onPressed: () => _run(widget.onRedeem),
                    ),
                    const SizedBox(height: Sp.sm),
                    OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => _run(() => widget.onCancel(null)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(LucideIcons.x, size: 18),
                      label: Text(t.merchantValidateRewardCancelButton),
                    ),
                  ] else
                    AppButton.primary(t.commonClose, onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
