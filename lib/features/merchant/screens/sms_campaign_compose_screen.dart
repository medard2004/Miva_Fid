import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/campaign_model.dart';
import '../providers/sms_campaign_draft_provider.dart';

/// Étape 2 du wizard de campagne SMS : composer le message, programmer en
/// option, puis envoyer (ou enregistrer, en édition).
class SmsCampaignComposeScreen extends ConsumerStatefulWidget {
  const SmsCampaignComposeScreen({super.key, this.editingCampaign});

  final CampaignModel? editingCampaign;

  @override
  ConsumerState<SmsCampaignComposeScreen> createState() =>
      _SmsCampaignComposeScreenState();
}

class _SmsCampaignComposeScreenState
    extends ConsumerState<SmsCampaignComposeScreen> {
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _msgCtrl.text = ref.read(smsCampaignDraftProvider(widget.editingCampaign)).message;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScheduledDate() async {
    final notifier = ref.read(smsCampaignDraftProvider(widget.editingCampaign).notifier);
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    notifier.setScheduledAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _send() async {
    final draft = ref.read(smsCampaignDraftProvider(widget.editingCampaign));
    final isEditing = widget.editingCampaign != null;
    if (draft.message.trim().isEmpty) {
      ToastService.showError('Veuillez saisir un message');
      return;
    }
    if (isEditing && draft.scheduledAt == null) {
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isEditing ? 'Enregistrer' : (draft.scheduledAt != null ? 'Programmer' : 'Envoyer'),
              style: const TextStyle(color: Color(0xFF5B50EC), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(smsCampaignDraftProvider(widget.editingCampaign).notifier).submit();
      if (mounted) {
        context.go('/merchant/sms');
        ToastService.showSuccess(
          isEditing
              ? 'Campagne modifiée !'
              : (draft.scheduledAt != null ? 'Campagne programmée !' : 'Campagne envoyée avec succès !'),
        );
      }
    } catch (e) {
      if (mounted) ToastService.showError('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(smsCampaignDraftProvider(widget.editingCampaign));
    final notifier = ref.read(smsCampaignDraftProvider(widget.editingCampaign).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.editingCampaign != null ? 'Modifier la campagne' : 'Message',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.users, size: 16, color: Color(0xFF5B50EC)),
                      const SizedBox(width: 8),
                      Text(
                        '${draft.selectedClientIds.length} destinataires',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        'Modifier',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 15),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Message SMS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _msgCtrl,
                maxLines: 4,
                maxLength: 160,
                onChanged: notifier.setMessage,
                decoration: InputDecoration(
                  hintText: 'Ex: Promotion spéciale ce week-end ! -15% sur toute l\'addition.',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickScheduledDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendarClock, size: 18, color: Color(0xFF5B50EC)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          draft.scheduledAt == null
                              ? 'Envoyer maintenant (toucher pour programmer)'
                              : 'Programmée pour le ${draft.scheduledAt!.day}/${draft.scheduledAt!.month} à ${draft.scheduledAt!.hour}:${draft.scheduledAt!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (draft.scheduledAt != null)
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () => notifier.setScheduledAt(null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: draft.sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B50EC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: draft.sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.send, size: 17),
                  label: Text(
                    widget.editingCampaign != null
                        ? 'Enregistrer les modifications'
                        : (draft.scheduledAt != null ? 'Programmer la campagne' : 'Envoyer la campagne'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
