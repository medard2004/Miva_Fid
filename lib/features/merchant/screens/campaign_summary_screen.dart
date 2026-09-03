import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/campaign_model.dart';
import '../providers/merchant_auth_provider.dart';
import '../providers/sms_campaign_draft_provider.dart';

/// Étape 4 du wizard : récapitulatif, planification, et envoi.
class CampaignSummaryScreen extends ConsumerStatefulWidget {
  const CampaignSummaryScreen({super.key, this.editingCampaign});

  final CampaignModel? editingCampaign;

  @override
  ConsumerState<CampaignSummaryScreen> createState() =>
      _CampaignSummaryScreenState();
}

class _CampaignSummaryScreenState
    extends ConsumerState<CampaignSummaryScreen> {

  Future<void> _pickScheduledDate() async {
    final notifier =
        ref.read(campaignDraftProvider(widget.editingCampaign).notifier);
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    notifier.setScheduledAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _send() async {
    final draft = ref.read(campaignDraftProvider(widget.editingCampaign));
    final isEditing = widget.editingCampaign != null;

    if (draft.title.trim().isEmpty && draft.message.trim().isEmpty) {
      ToastService.showError('Veuillez saisir un titre ou un message');
      return;
    }
    if (isEditing && draft.scheduledAt == null && widget.editingCampaign?.status != 'draft') {
      ToastService.showError('Une date de programmation est requise.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEditing
              ? 'Enregistrer les modifications ?'
              : draft.scheduledAt != null
                  ? 'Programmer la campagne ?'
                  : 'Envoyer la campagne ?',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Ce message sera envoyé à ${draft.selectedClientIds.length} client(s).',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isEditing
                  ? 'Enregistrer'
                  : (draft.scheduledAt != null ? 'Programmer' : 'Envoyer'),
              style: const TextStyle(
                  color: Color(0xFF5B50EC), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(campaignDraftProvider(widget.editingCampaign).notifier)
          .submit();
      if (mounted) {
        context.go('/merchant/sms');
        ToastService.showSuccess(
          isEditing
              ? 'Campagne modifiée !'
              : (draft.scheduledAt != null
                  ? 'Campagne programmée !'
                  : 'Campagne envoyée avec succès !'),
        );
      }
    } catch (e) {
      if (mounted) ToastService.showError('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(campaignDraftProvider(widget.editingCampaign));
    final notifier =
        ref.read(campaignDraftProvider(widget.editingCampaign).notifier);
    final type = draft.type ?? CampaignType.promotion;
    final isEditing = widget.editingCampaign != null;

    final authState = ref.watch(merchantAuthProvider);
    final smsCredits = authState.restaurant?.smsCredits ?? 0;

    final cost = isEditing
        ? (draft.selectedClientIds.length -
            (widget.editingCampaign!.recipientsCount))
        : draft.selectedClientIds.length;
    final finalBalance = smsCredits - cost;
    final canSend = finalBalance >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Récapitulatif',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save, size: 20),
            tooltip: 'Sauvegarder en brouillon',
            onPressed: () async {
              try {
                await notifier.saveAsDraft(4);
                if (context.mounted) {
                  ToastService.showSuccess('Brouillon sauvegardé');
                  context.go('/merchant/sms');
                }
              } catch (e) {
                if (context.mounted) ToastService.showError('$e');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B50EC),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vérifiez avant d\'envoyer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assurez-vous que tout est correct',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Type summary
                    _buildSummaryCard(
                      icon: LucideIcons.layers,
                      title: 'Type de campagne',
                      value: '${type.emoji} ${type.label}',
                    ),
                    const SizedBox(height: 10),

                    // Content summary
                    _buildSummaryCard(
                      icon: LucideIcons.fileText,
                      title: 'Contenu',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (draft.title.trim().isNotEmpty) ...[
                            Text(
                              draft.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (draft.message.trim().isNotEmpty)
                            Text(
                              draft.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          if (draft.imageUrl != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(LucideIcons.image,
                                    size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Image jointe',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Recipients summary
                    _buildSummaryCard(
                      icon: LucideIcons.users,
                      title: 'Destinataires',
                      value:
                          '${draft.selectedClientIds.length} client${draft.selectedClientIds.length > 1 ? 's' : ''}',
                    ),
                    const SizedBox(height: 16),

                    // Scheduling
                    Text(
                      'Programmation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickScheduledDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B50EC)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.calendarClock,
                                  size: 18, color: Color(0xFF5B50EC)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                draft.scheduledAt == null
                                    ? 'Envoyer maintenant'
                                    : 'Programmée le ${draft.scheduledAt!.day}/${draft.scheduledAt!.month}/${draft.scheduledAt!.year} à ${draft.scheduledAt!.hour}:${draft.scheduledAt!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (draft.scheduledAt != null)
                              IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () =>
                                    notifier.setScheduledAt(null),
                              )
                            else
                              Text(
                                'Programmer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Credits summary
                    Text(
                      'Crédits de notification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: canSend ? AppColors.border : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Solde actuel',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                              Text(
                                '$smsCredits crédit${smsCredits > 1 ? 's' : ''}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Coût estimé',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                              Text(
                                '${cost > 0 ? '-' : (cost < 0 ? '+' : '')}${cost.abs()} crédit${cost.abs() > 1 ? 's' : ''}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Solde final',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              Text(
                                '$finalBalance crédit${finalBalance.abs() > 1 ? 's' : ''}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: finalBalance < 0
                                        ? Colors.red
                                        : AppColors.textPrimary),
                              ),
                            ],
                          ),
                          if (finalBalance < 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.alertCircle, size: 14, color: Colors.red),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Crédit insuffisant. Veuillez recharger votre compte.',
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Send button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (draft.sending || !canSend) ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B50EC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: draft.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            draft.scheduledAt != null
                                ? LucideIcons.calendarCheck
                                : LucideIcons.send,
                            size: 18),
                    label: Text(
                      isEditing
                          ? 'Enregistrer les modifications'
                          : (draft.scheduledAt != null
                              ? 'Programmer la campagne'
                              : 'Envoyer la campagne'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    String? value,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF5B50EC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF5B50EC)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                if (child != null) child,
                if (value != null)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
