import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../models/campaign_model.dart';
import '../providers/sms_campaign_draft_provider.dart';

/// Écran de création / édition directe de campagne SMS (en un seul écran).
class CampaignTypeScreen extends ConsumerStatefulWidget {
  const CampaignTypeScreen({super.key, this.editingCampaign});

  final CampaignModel? editingCampaign;

  @override
  ConsumerState<CampaignTypeScreen> createState() => _CampaignTypeScreenState();
}

class _CampaignTypeScreenState extends ConsumerState<CampaignTypeScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _msgCtrl;
  bool _isScheduled = false;

  static const _types = [
    (CampaignType.promotion, LucideIcons.tag, Color(0xFF5B50EC), 'Offres spéciales, réductions, nouveautés'),
    (CampaignType.reminder, LucideIcons.bellRing, Color(0xFFF59E0B), 'Relancer les clients sans visite récente'),
    (CampaignType.review, LucideIcons.star, Color(0xFFEC4899), 'Inviter vos clients à donner leur avis'),
    (CampaignType.reward, LucideIcons.gift, Color(0xFF10B981), 'Annoncer les récompenses disponibles'),
    (CampaignType.progress, LucideIcons.trendingUp, Color(0xFF3B82F6), 'Encourager à compléter la carte de fidélité'),
    (CampaignType.referral, LucideIcons.userPlus, Color(0xFF14B8A6), 'Inciter à parrainer des proches'),
  ];

  static const _audiences = [
    ('all', 'Tous les clients', LucideIcons.users),
    ('inactive', 'Inactifs', LucideIcons.userX),
    ('near_reward', 'Proches récompense', LucideIcons.gift),
    ('reward_available', 'Récompense dispo', LucideIcons.sparkles),
  ];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(campaignDraftProvider(widget.editingCampaign));
    _titleCtrl = TextEditingController(text: draft.title);
    _msgCtrl = TextEditingController(text: draft.message);
    _isScheduled = draft.scheduledAt != null;

    if (draft.type == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(campaignDraftProvider(widget.editingCampaign).notifier)
            .setType(CampaignType.promotion);
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xfile != null) {
        final notifier =
            ref.read(campaignDraftProvider(widget.editingCampaign).notifier);
        notifier.setLocalImagePath(xfile.path);
        notifier.setImageUrl(null);
      }
    } catch (e) {
      ToastService.showError('Impossible de charger l\'image: $e');
    }
  }

  Future<void> _pickDateTime() async {
    final draft = ref.read(campaignDraftProvider(widget.editingCampaign));
    final initialDate = draft.scheduledAt ??
        DateTime.now().add(const Duration(hours: 1));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _ModernDateTimePickerSheet(
          initialDateTime: initialDate,
          onConfirmed: (dateTime) {
            ref
                .read(campaignDraftProvider(widget.editingCampaign).notifier)
                .setScheduledAt(dateTime);
            setState(() => _isScheduled = true);
          },
        );
      },
    );

    if (mounted) {
      final updatedDraft =
          ref.read(campaignDraftProvider(widget.editingCampaign));
      setState(() {
        _isScheduled = updatedDraft.scheduledAt != null;
      });
    }
  }

  void _showTypeSelector(CampaignType currentType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Type de campagne',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sélectionnez l\'objectif de votre message',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _types.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 52,
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, index) {
                      final (type, icon, color, description) = _types[index];
                      final isSelected = type == currentType;

                      return InkWell(
                        onTap: () {
                          ref
                              .read(campaignDraftProvider(widget.editingCampaign)
                                  .notifier)
                              .setType(type);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 11),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Icon(icon, size: 19, color: color),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? color
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecipientsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final draft =
                ref.watch(campaignDraftProvider(widget.editingCampaign));
            final notifier = ref
                .read(campaignDraftProvider(widget.editingCampaign).notifier);

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sélection des clients',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: notifier.toggleSelectAllVisible,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              draft.allVisibleSelected
                                  ? 'Tout désélectionner'
                                  : 'Tout sélectionner',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5B50EC),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: notifier.setSearch,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un client...',
                          hintStyle: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5),
                          prefixIcon: const Icon(LucideIcons.search,
                              size: 16, color: Color(0xFF5B50EC)),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: draft.loadingRecipients
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF5B50EC),
                                ),
                              )
                            : draft.visibleRecipients.isEmpty
                                ? Center(
                                    child: Text(
                                      'Aucun client trouvé',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: draft.visibleRecipients.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final r = draft.visibleRecipients[index];
                                      final isSelected = draft
                                          .selectedClientIds
                                          .contains(r.clientId);

                                      return CheckboxListTile(
                                        value: isSelected,
                                        activeColor: const Color(0xFF5B50EC),
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          r.name.isEmpty
                                              ? 'Client #${r.clientId}'
                                              : r.name,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          r.phone ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        onChanged: (_) =>
                                            notifier.toggle(r.clientId),
                                      );
                                    },
                                  ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B50EC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Valider (${draft.selectedClientIds.length} sélectionné${draft.selectedClientIds.length > 1 ? 's' : ''})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    final notifier =
        ref.read(campaignDraftProvider(widget.editingCampaign).notifier);
    final draft = ref.read(campaignDraftProvider(widget.editingCampaign));

    if (draft.message.trim().isEmpty) {
      ToastService.showError('Veuillez saisir un message pour la campagne');
      return;
    }

    final isScheduled = draft.scheduledAt != null;
    final isDraft = widget.editingCampaign?.isDraft ?? false;
    final isEditingExistingScheduled =
        widget.editingCampaign != null && !isDraft;

    final String actionLabel;
    final String dialogTitle;
    final String dialogMessage;

    if (isEditingExistingScheduled) {
      actionLabel = 'Enregistrer';
      dialogTitle = 'Modifier la campagne';
      dialogMessage =
          'Souhaitez-vous enregistrer les modifications apportées à cette campagne ?';
    } else if (isScheduled) {
      actionLabel = 'Programmer';
      dialogTitle = 'Programmer la campagne';
      dialogMessage =
          'Ce message sera programmé pour ${draft.selectedClientIds.length} client(s).';
    } else {
      actionLabel = 'Envoyer';
      dialogTitle = 'Envoyer la campagne';
      dialogMessage =
          'Ce message sera envoyé immédiatement à ${draft.selectedClientIds.length} client(s).';
    }

    final confirmed = await AppDialog.confirm(
      context,
      title: dialogTitle,
      message: dialogMessage,
      confirmLabel: actionLabel,
      icon: isScheduled ? LucideIcons.clock : LucideIcons.send,
    );

    if (confirmed != true || !mounted) return;

    try {
      await notifier.submit();
      if (mounted) {
        ToastService.showSuccess(isEditingExistingScheduled
            ? 'Campagne modifiée avec succès'
            : (isScheduled
                ? 'Campagne programmée avec succès'
                : 'Campagne envoyée avec succès'));
        context.go('/merchant/sms');
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

    final isDraft = widget.editingCampaign?.isDraft ?? false;
    final isEditingExistingScheduled =
        widget.editingCampaign != null && !isDraft;

    final charCount = draft.message.length;
    final segmentCount = (charCount / 160).ceil().clamp(1, 99);
    final selectedType = draft.type ?? CampaignType.promotion;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditingExistingScheduled
              ? 'Modifier la campagne'
              : (isDraft ? 'Finaliser la campagne' : 'Nouvelle campagne'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon:
                Icon(LucideIcons.save, size: 19, color: AppColors.textPrimary),
            tooltip: 'Sauvegarder en brouillon',
            onPressed: () async {
              try {
                await notifier.saveAsDraft(1);
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. TYPE DE CAMPAGNE (CHAMP DÉROULANT / SÉLECTEUR) ───
                    Text(
                      'Type de campagne',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showTypeSelector(selectedType),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    selectedType.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(selectedType.icon,
                                  size: 16, color: selectedType.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedType.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronDown,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── 2. IMAGE D'ILLUSTRATION (SEULEMENT POUR PROMOTIONS / RÉCOMPENSES) ────
                    if (selectedType.hasImage) ...[
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Image d\'illustration (optionnelle)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (draft.localImagePath != null ||
                              (draft.imageUrl != null &&
                                  draft.imageUrl!.isNotEmpty))
                            GestureDetector(
                              onTap: () {
                                notifier.setLocalImagePath(null);
                                notifier.setImageUrl(null);
                              },
                              child: const Text(
                                'Supprimer',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (draft.localImagePath != null ||
                          (draft.imageUrl != null &&
                              draft.imageUrl!.isNotEmpty))
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: draft.localImagePath != null
                                    ? Image.file(
                                        File(draft.localImagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        draft.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                          child: Icon(LucideIcons.imageOff,
                                              size: 32),
                                        ),
                                      ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.7),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(LucideIcons.image, size: 14),
                                  label: const Text(
                                    'Changer',
                                    style: TextStyle(fontSize: 11.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B50EC)
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.imagePlus,
                                    size: 18,
                                    color: Color(0xFF5B50EC),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ajouter une image',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'JPG, PNG jusqu\'à 5 Mo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 18),

                    // ── 3. TITRE (OPTIONNEL) ──────────────────────────────
                    Text(
                      'Titre de la campagne (optionnel)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleCtrl,
                      onChanged: notifier.setTitle,
                      style: TextStyle(
                          fontSize: 13.5, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'ex. Offre spéciale week-end',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
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
                          borderSide: const BorderSide(
                              color: Color(0xFF5B50EC), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 4. MESSAGE SMS ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Message SMS',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$charCount car. • $segmentCount segment${segmentCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _msgCtrl,
                      onChanged: notifier.setMessage,
                      maxLines: 4,
                      style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            'Rédigez le message à envoyer à vos clients…',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.all(14),
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
                          borderSide: const BorderSide(
                              color: Color(0xFF5B50EC), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 5. AUDIENCE / DESTINATAIRES ───────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Destinataires',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: _showRecipientsSheet,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  '${draft.selectedClientIds.length} ciblé(s)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5B50EC),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.slidersHorizontal,
                                  size: 13,
                                  color: Color(0xFF5B50EC),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _audiences.map((aud) {
                        final (key, label, icon) = aud;
                        final isSelected = draft.recipientType == key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: InkWell(
                              onTap: () => notifier.setSegment(key),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF5B50EC)
                                          .withValues(alpha: 0.12)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF5B50EC)
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      icon,
                                      size: 16,
                                      color: isSelected
                                          ? const Color(0xFF5B50EC)
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF5B50EC)
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // ── 6. PROGRAMMATION (OPTIONNEL) ─────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.clock,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Programmer l\'envoi',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Envoyer automatiquement à une date précise',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isScheduled,
                                activeTrackColor: const Color(0xFF5B50EC),
                                onChanged: (val) {
                                  setState(() => _isScheduled = val);
                                  if (!val) {
                                    notifier.setScheduledAt(null);
                                  } else {
                                    _pickDateTime();
                                  }
                                },
                              ),
                            ],
                          ),
                          if (_isScheduled && draft.scheduledAt != null) ...[
                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickDateTime,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Prévu le : ${DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(draft.scheduledAt!)}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF5B50EC),
                                      ),
                                    ),
                                    const Icon(
                                      LucideIcons.calendar,
                                      size: 15,
                                      color: Color(0xFF5B50EC),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BOTTOM ACTION BUTTON ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.6),
                    width: 0.5,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: draft.sending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B50EC),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: draft.sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              draft.scheduledAt != null
                                  ? LucideIcons.clock
                                  : LucideIcons.send,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEditingExistingScheduled
                                  ? 'Enregistrer les modifications'
                                  : (draft.scheduledAt != null
                                      ? 'Programmer la campagne'
                                      : 'Envoyer la campagne (${draft.selectedClientIds.length})'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernDateTimePickerSheet extends StatefulWidget {
  const _ModernDateTimePickerSheet({
    required this.initialDateTime,
    required this.onConfirmed,
  });

  final DateTime initialDateTime;
  final ValueChanged<DateTime> onConfirmed;

  @override
  State<_ModernDateTimePickerSheet> createState() =>
      _ModernDateTimePickerSheetState();
}

class _ModernDateTimePickerSheetState
    extends State<_ModernDateTimePickerSheet> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
  }

  void _applyPreset(DateTime dt) {
    setState(() => _selectedDateTime = dt);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today18h = DateTime(now.year, now.month, now.day, 18, 0);
    final tomorrow10h = DateTime(now.year, now.month, now.day + 1, 10, 0);
    final tomorrow18h = DateTime(now.year, now.month, now.day + 1, 18, 0);
    final formattedDateText = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDateTime);
    final formattedTimeText = DateFormat('HH:mm', 'fr_FR').format(_selectedDateTime);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Programmer l\'envoi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x,
                      size: 20, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Live selected banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF5B50EC).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B50EC).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.calendarClock,
                      size: 18,
                      color: Color(0xFF5B50EC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDateText[0].toUpperCase() + formattedDateText.substring(1),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'à $formattedTimeText',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5B50EC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip(
                    label: 'Dans 1h',
                    onTap: () => _applyPreset(now.add(const Duration(hours: 1))),
                  ),
                  const SizedBox(width: 8),
                  if (now.hour < 18) ...[
                    _buildPresetChip(
                      label: 'Ce soir 18h',
                      onTap: () => _applyPreset(today18h),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildPresetChip(
                    label: 'Demain 10h',
                    onTap: () => _applyPreset(tomorrow10h),
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    label: 'Demain 18h',
                    onTap: () => _applyPreset(tomorrow18h),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Cupertino Wheel Picker
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    use24hFormat: true,
                    minimumDate: now.subtract(const Duration(minutes: 2)),
                    maximumDate: now.add(const Duration(days: 365)),
                    initialDateTime: _selectedDateTime.isBefore(now) ? now : _selectedDateTime,
                    onDateTimeChanged: (dt) {
                      setState(() => _selectedDateTime = dt);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirmed(_selectedDateTime);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B50EC),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.check, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Confirmer pour le ${DateFormat('dd/MM à HH:mm', 'fr_FR').format(_selectedDateTime)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
