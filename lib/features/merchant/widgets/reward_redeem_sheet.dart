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
/// détail résolu côté serveur (`MerchantReward`), le type exact (parrainage,
/// anniversaire, bienvenue, fidélité), les informations client et le résumé
/// de l'action effectuée avant validation.
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

  Color _statusColor() {
    if (widget.reward.status == 'used') return Colors.grey;
    if (widget.reward.status == 'canceled') return AppColors.danger;
    if (widget.reward.isExpired) return Colors.orange;
    return const Color(0xFF059669);
  }

  ({IconData icon, String label, Color bg, Color fg}) _typeInfo() {
    final source = widget.reward.source;
    if (source == 'referral' || source == 'referral_bonus') {
      return (
        icon: LucideIcons.users,
        label: 'Récompense de Parrainage',
        bg: const Color(0xFFEEF2FF),
        fg: const Color(0xFF4F46E5),
      );
    }
    if (source == 'birthday') {
      return (
        icon: LucideIcons.cake,
        label: 'Récompense d\'Anniversaire',
        bg: const Color(0xFFFDF2F8),
        fg: const Color(0xFFDB2777),
      );
    }
    if (source == 'welcome') {
      return (
        icon: LucideIcons.partyPopper,
        label: 'Cadeau de Bienvenue',
        bg: const Color(0xFFFFFBEB),
        fg: const Color(0xFFD97706),
      );
    }
    return (
      icon: LucideIcons.award,
      label: 'Récompense de Fidélité',
      bg: const Color(0xFFECFDF5),
      fg: const Color(0xFF059669),
    );
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
    final type = _typeInfo();

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
                  
                  // Header avec Badge de Type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: type.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(type.icon, color: type.fg, size: 22),
                      ),
                      const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.label,
                              style: AppTextStyles.caption().copyWith(
                                color: type.fg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              t.merchantValidateRewardSheetTitle,
                              style: AppTextStyles.h3(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor().withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(t),
                          style: TextStyle(
                            color: _statusColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.md),

                  // Titre de la récompense
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Sp.md),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Récompense concernée',
                          style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward.title,
                          style: AppTextStyles.h3().copyWith(fontSize: 18),
                        ),
                        if (reward.isSurprise) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 4),
                              Text(
                                'Offre surprise',
                                style: AppTextStyles.caption().copyWith(
                                  color: const Color(0xFFD97706),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Sp.sm),

                  // Détails Client
                  if (reward.clientName != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(LucideIcons.user, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: Sp.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward.clientName!,
                                  style: AppTextStyles.labelBold(),
                                ),
                                if (reward.clientPhone != null && reward.clientPhone!.isNotEmpty)
                                  Text(
                                    reward.clientPhone!,
                                    style: AppTextStyles.caption().copyWith(color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.sm),
                  ],

                  // Box d'explication de l'action à effectuer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Sp.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.info, color: Color(0xFF0284C7), size: 20),
                        const SizedBox(width: Sp.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Détail de l\'action à effectuer',
                                style: AppTextStyles.caption().copyWith(
                                  color: const Color(0xFF0369A1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reward.isRedeemable
                                    ? 'En confirmant, vous attribuez la récompense "${reward.title}" à ${reward.clientName ?? "ce client"}. Le statut passera à "Utilisée".'
                                    : 'Cette récompense ne peut plus être validée car son statut est : ${_statusLabel(t)}.',
                                style: AppTextStyles.caption().copyWith(
                                  color: const Color(0xFF0C4A6E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Sp.lg),

                  // Boutons d'action
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

