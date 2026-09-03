import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../models/campaign_model.dart';
import '../providers/sms_campaign_draft_provider.dart';

/// Étape 2 du wizard : contenu de la campagne (formulaire dynamique).
class CampaignContentScreen extends ConsumerStatefulWidget {
  const CampaignContentScreen({super.key, this.editingCampaign});

  final CampaignModel? editingCampaign;

  @override
  ConsumerState<CampaignContentScreen> createState() =>
      _CampaignContentScreenState();
}

class _CampaignContentScreenState
    extends ConsumerState<CampaignContentScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _msgCtrl;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(campaignDraftProvider(widget.editingCampaign));
    _titleCtrl = TextEditingController(text: draft.title);
    _msgCtrl = TextEditingController(text: draft.message);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  bool _canProceed(CampaignDraft draft) {
    // Au minimum un titre ou un message doit être renseigné
    return draft.title.trim().isNotEmpty || draft.message.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(campaignDraftProvider(widget.editingCampaign));
    final notifier =
        ref.read(campaignDraftProvider(widget.editingCampaign).notifier);
    final type = draft.type ?? CampaignType.promotion;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              type.label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save, size: 20),
            tooltip: 'Sauvegarder en brouillon',
            onPressed: () async {
              try {
                await notifier.saveAsDraft(2);
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
                          color: i <= 1
                              ? const Color(0xFF5B50EC)
                              : AppColors.border,
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
                      'Contenu de la campagne',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleForType(type),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image (local)
                    if (type.hasImage) ...[
                      _buildLabel('Image'),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final xfile = await picker.pickImage(source: ImageSource.gallery);
                          if (xfile != null) {
                            notifier.setLocalImagePath(xfile.path);
                            notifier.setImageUrl(null);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: draft.localImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(draft.localImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : draft.imageUrl != null && draft.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        draft.imageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.imagePlus,
                                              color: AppColors.textSecondary, size: 32),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Ajouter une image',
                                            style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      if (draft.localImagePath != null ||
                          (draft.imageUrl != null && draft.imageUrl!.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              notifier.setLocalImagePath(null);
                              notifier.setImageUrl(null);
                            },
                            icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                            label: const Text('Supprimer l\'image',
                                style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // Title
                    if (type.hasTitle) ...[
                      _buildLabel('Titre'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleCtrl,
                        maxLength: 120,
                        onChanged: notifier.setTitle,
                        decoration: _inputDecoration(
                          hintText: _titleHint(type),
                          icon: LucideIcons.type,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Message
                    if (type.hasMessage) ...[
                      _buildLabel(_messageLabel(type)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _msgCtrl,
                        maxLines: 4,
                        maxLength: 500,
                        onChanged: notifier.setMessage,
                        decoration: _inputDecoration(
                          hintText: _messageHint(type),
                          icon: LucideIcons.alignLeft,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Preview card
                    _buildPreview(draft, type),
                  ],
                ),
              ),
            ),

            // Next button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !_canProceed(draft)
                        ? null
                        : () => context.push(
                              '/merchant/campaigns/new/recipients',
                              extra: widget.editingCampaign,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B50EC),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Suivant — Destinataires',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5B50EC), width: 1.5),
      ),
    );
  }

  Widget _buildPreview(CampaignDraft draft, CampaignType type) {
    if (draft.title.trim().isEmpty && draft.message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu de la notification',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                child: Center(
                  child: Text(type.emoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (draft.title.trim().isNotEmpty)
                      Text(
                        draft.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (draft.message.trim().isNotEmpty) ...[
                      if (draft.title.trim().isNotEmpty)
                        const SizedBox(height: 2),
                      Text(
                        draft.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _subtitleForType(CampaignType type) {
    return switch (type) {
      CampaignType.promotion =>
        'Ajoutez une image, un titre et une description pour votre promotion',
      CampaignType.reminder =>
        'Rédigez un message de rappel pour les clients inactifs',
      CampaignType.review =>
        'Demandez à vos clients de noter leur expérience',
      CampaignType.reward =>
        'Informez vos clients d\'une récompense disponible',
      CampaignType.progress =>
        'Encouragez vos clients à atteindre le prochain palier',
      CampaignType.referral =>
        'Encouragez le parrainage entre vos clients',
    };
  }

  String _titleHint(CampaignType type) {
    return switch (type) {
      CampaignType.promotion => 'Ex: -20% ce week-end !',
      CampaignType.reminder => 'Ex: Vous nous manquez !',
      CampaignType.review => 'Ex: Votre avis compte',
      CampaignType.reward => 'Ex: Récompense disponible !',
      CampaignType.progress => 'Ex: Plus qu\'un tampon !',
      CampaignType.referral => 'Ex: Parrainez vos amis',
    };
  }

  String _messageLabel(CampaignType type) {
    return switch (type) {
      CampaignType.promotion => 'Description de l\'offre',
      CampaignType.review => 'Message d\'invitation',
      _ => 'Message',
    };
  }

  String _messageHint(CampaignType type) {
    return switch (type) {
      CampaignType.promotion =>
        'Profitez de -20% sur tout notre menu ce week-end...',
      CampaignType.reminder =>
        'Cela fait longtemps que vous n\'êtes pas venu. Votre prochaine récompense vous attend !',
      CampaignType.review =>
        'Comment avez-vous apprécié votre dernière visite ?',
      CampaignType.reward =>
        'Félicitations ! Votre récompense est maintenant disponible.',
      CampaignType.progress =>
        'Plus qu\'un tampon avant votre prochaine récompense !',
      CampaignType.referral =>
        'Parrainez un ami et recevez tous les deux une récompense !',
    };
  }
}
