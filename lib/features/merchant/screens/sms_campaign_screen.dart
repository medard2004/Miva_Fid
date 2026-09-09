import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/campaign_model.dart';
import '../../client/providers/settings_provider.dart';
import '../providers/merchant_provider.dart';
import '../providers/sms_provider.dart';

/// Libellé affiché pour un `recipient_type` de campagne — partagé entre la
/// liste ([SmsCampaignScreen]) et le détail (`SmsCampaignDetailScreen`) pour
/// ne pas diverger.
String targetLabel(String? recipientType) {
  switch (recipientType) {
    case 'all':
      return 'Tous les clients';
    case 'inactive':
      return 'Clients inactifs';
    case 'near_reward':
      return 'Proches récompense';
    case 'manual':
      return 'Sélection manuelle';
    default:
      return 'Tous les clients';
  }
}

class SmsCampaignScreen extends ConsumerStatefulWidget {
  const SmsCampaignScreen({super.key});

  @override
  ConsumerState<SmsCampaignScreen> createState() => _SmsCampaignScreenState();
}

class _SmsCampaignScreenState extends ConsumerState<SmsCampaignScreen> {
  bool _showArchived = false;
  StreamSubscription? _campaignSub;

  @override
  void initState() {
    super.initState();
    _campaignSub = RealtimeService.instance.onCampaignUpdated.listen((_) {
      if (mounted) {
        ref.invalidate(smsNotifierProvider);
      }
    });
  }

  @override
  void dispose() {
    _campaignSub?.cancel();
    super.dispose();
  }

  late List<_CampaignMock> _campaigns;

  @override
  void initState() {
    super.initState();
    _campaigns = List.from(_mockCampaigns);
  }

  void _showNewCampaignModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedTarget = 'Tous les clients';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final charCount = messageCtrl.text.length;
          final smsCount = (charCount / 160).ceil().clamp(1, 99);

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.messageSquarePlus,
                          color: Color(0xFF5B50EC),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nouvelle campagne SMS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Envoyez un message direct à vos clients',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x,
                            size: 20, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Titre campagne
                  Text(
                    'Titre de la campagne',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Ex: Promo week-end -20%',
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Destinataires
                  Text(
                    'Destinataires cibles',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Tous les clients',
                      'Inactifs +14j',
                      'VIP Or & Platine',
                      'Nouveaux inscrits',
                    ].map((target) {
                      final isSelected = selectedTarget == target;
                      return ChoiceChip(
                        label: Text(target),
                        selected: isSelected,
                        onSelected: (_) =>
                            setModalState(() => selectedTarget = target),
                        selectedColor: const Color(0xFF5B50EC),
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF5B50EC)
                              : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Message SMS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Message SMS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$charCount/160 ($smsCount SMS)',
                        style: TextStyle(
                          fontSize: 11,
                          color: charCount > 160
                              ? const Color(0xFFD97706)
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 4,
                    onChanged: (_) => setModalState(() {}),
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText:
                          'Bonjour {nom}, profitez de notre offre spéciale ce week-end !',
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez saisir un titre')),
                          );
                          return;
                        }

                        final newCampaign = _CampaignMock(
                          id: '${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          status: 'Envoyée',
                          target: selectedTarget,
                          time: "À l'instant",
                          sentStats: '47/47 envoyés',
                          openStats: '100% reçus',
                        );

                        setState(() {
                          _campaigns.insert(0, newCampaign);
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Campagne SMS envoyée avec succès'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B50EC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Envoyer la campagne',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final newCampaign = _CampaignMock(
                          id: '${DateTime.now().millisecondsSinceEpoch}',
                          title: title.isNotEmpty ? title : 'Brouillon sans titre',
                          status: 'Planifiée',
                          isPlanned: true,
                          target: selectedTarget,
                          time: 'Brouillon',
                          sentStats: '0 envoyé',
                        );

                        setState(() {
                          _campaigns.insert(0, newCampaign);
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Campagne enregistrée en brouillon'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Enregistrer comme brouillon',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(merchantNotifierProvider).value;
    final smsAsync = _showArchived
        ? ref.watch(archivedCampaignsProvider)
        : ref.watch(smsNotifierProvider);
    ref.watch(appBrightnessProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP HEADER (PERSISTENT / FIXED ON SCROLL) ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.messageSquare,
                      color: Color(0xFF5B50EC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.merchantNavSms,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/merchant/campaigns/new'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B50EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.push('/merchant/more/notifications'),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.bell,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5B50EC),
                onRefresh: () {
                  if (_showArchived) {
                    return ref.refresh(archivedCampaignsProvider.future);
                  }
                  return ref.refresh(smsNotifierProvider.future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 3 KPI STAT CARDS ROW ─────────────────────────────────────
                      _buildKpiRow(smsAsync, merchant?.smsRemaining),
                const SizedBox(height: 20),

                // ── SECTION HISTORIQUE ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.merchantClientDetailHistoryTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      smsAsync.maybeWhen(
                        data: (list) =>
                            '${list.length} campagne${list.length > 1 ? 's' : ''}',
                        orElse: () => '',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Toggle Actives / Archivées
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showArchived = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_showArchived ? const Color(0xFF5B50EC) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Actives',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_showArchived ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showArchived = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _showArchived ? const Color(0xFF5B50EC) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Archivées',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showArchived ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Campaign Cards
                smsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: Color(0xFF5B50EC),
                      ),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erreur: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  data: (campaigns) {
                    if (campaigns.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                LucideIcons.messageSquare,
                                size: 32,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Aucune campagne pour le moment',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final camp in campaigns)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _showArchived
                                ? _buildCampaignCard(camp) // On ne permet pas de ré-archiver/désarchiver pour l'instant
                                : Dismissible(
                                    key: ValueKey(camp.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        LucideIcons.archive,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    onDismissed: (_) async {
                                      try {
                                        await ref
                                            .read(smsNotifierProvider.notifier)
                                            .archive(camp.id);
                                        ToastService.showSuccess(
                                            'Campagne archivée');
                                      } catch (e) {
                                        ToastService.showError('Erreur: $e');
                                      }
                                    },
                                    child: _buildCampaignCard(camp),
                                  ),
                          ),
                      ],
                    );
                  },
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

  Widget _buildKpiRow(
      AsyncValue<List<CampaignModel>> smsAsync, int? smsRemaining) {
    final campaigns = smsAsync.value ?? const <CampaignModel>[];
    final sentCount = campaigns.where((c) => c.isSent).length;
    final reached = campaigns.fold<int>(0, (sum, c) => sum + c.recipientsCount);

    return Row(
      children: [
        Expanded(
          child: _buildKpiBox(value: '$sentCount', label: 'Envoyées'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiBox(value: '$reached', label: 'Atteints'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiBox(
            value: '${smsRemaining ?? 0}',
            label: 'Solde SMS',
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignCard(CampaignModel camp) {
    final isPlanned = !camp.isSent && !camp.isDraft;
    final isDraft = camp.isDraft;
    final status = isDraft 
        ? 'Brouillon' 
        : (camp.isScheduled ? 'Planifiée' : 'Envoyée');
    final date = camp.sentAt ?? camp.createdAt;
    final time = isPlanned && camp.scheduledAt != null
        ? 'Prévue ${DateFormatter.short(camp.scheduledAt!)}'
        : DateFormatter.relative(date);
    final displayTitle = camp.title.isNotEmpty ? camp.title : camp.message;
    final title = displayTitle.length > 24
        ? '${displayTitle.substring(0, 24)}...'
        : displayTitle;
    final typeEmoji = _typeEmoji(camp.type);

    return InkWell(
      onTap: () {
        if (camp.isDraft) {
          String route = '/merchant/campaigns/new';
          if (camp.draftStep == 2) {
            route += '/content';
          } else if (camp.draftStep == 3) {
            route += '/recipients';
          } else if (camp.draftStep == 4) {
            route += '/summary';
          }
          context.push(route, extra: camp);
        } else {
          context.push('/merchant/sms/campaign/${camp.id}');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(typeEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDraft 
                        ? AppColors.border // grey tint for draft
                        : (isPlanned ? AppColors.warningTint : AppColors.successTint),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDraft 
                          ? AppColors.textSecondary.withValues(alpha: 0.3)
                          : (isPlanned
                              ? (AppColors.isDark ? const Color(0xFF4A3A14) : const Color(0xFFFDE68A))
                              : (AppColors.isDark ? const Color(0xFF1F4A38) : const Color(0xFFBBF7D0))),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDraft 
                            ? LucideIcons.fileEdit
                            : (isPlanned ? LucideIcons.clock : LucideIcons.circleCheck),
                        size: 11,
                        color: isDraft
                            ? AppColors.textSecondary
                            : (isPlanned ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: isPlanned
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_targetLabel(camp.recipientType)} • $time',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${camp.recipientsCount}/${camp.recipientsCount} envoyés',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(String? recipientType) => targetLabel(recipientType);

  String _typeEmoji(String type) {
    return switch (type) {
      'promotion' => '🏷️',
      'reminder' => '🔔',
      'review' => '⭐',
      'reward' => '🎁',
      'progress' => '📈',
      'cashback' => '💰',
      'referral' => '🤝',
      'announcement' => '📢',
      _ => '📋',
    };
  }

  Widget _buildKpiBox({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
