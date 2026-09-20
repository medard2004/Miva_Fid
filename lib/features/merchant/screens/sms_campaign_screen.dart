import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/widgets/app_dialog.dart';
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
  int _visibleLimit = 15;
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
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        _showArchived = false;
                        _visibleLimit = 15;
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: !_showArchived
                              ? const Color(0xFF5B50EC)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.send,
                              size: 13,
                              color: !_showArchived ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Actives',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: !_showArchived ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() {
                        _showArchived = true;
                        _visibleLimit = 15;
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _showArchived
                              ? const Color(0xFF5B50EC)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.archive,
                              size: 13,
                              color: _showArchived ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Archivées',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _showArchived ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                          padding: EdgeInsets.all(32),
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

                    final visibleCampaigns = campaigns.take(_visibleLimit).toList();

                    return Column(
                      children: [
                        for (int i = 0; i < visibleCampaigns.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                          _showArchived
                              ? Dismissible(
                                  key: ValueKey('archived_${visibleCampaigns[i].id}'),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    final confirmed = await AppDialog.confirm(
                                      context,
                                      title: 'Supprimer la campagne',
                                      message:
                                          'Êtes-vous sûr de vouloir supprimer définitivement cette campagne archivée ?',
                                      confirmLabel: 'Supprimer',
                                      destructive: true,
                                    );
                                    if (confirmed == true) {
                                      try {
                                        await ref
                                            .read(smsNotifierProvider.notifier)
                                            .deleteCampaign(visibleCampaigns[i].id);
                                        ToastService.showSuccess('Campagne supprimée');
                                        return true;
                                      } catch (e) {
                                        ToastService.showError('Erreur: $e');
                                        return false;
                                      }
                                    }
                                    return false;
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Supprimer',
                                          style: TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(LucideIcons.trash2,
                                            color: Color(0xFFDC2626), size: 18),
                                      ],
                                    ),
                                  ),
                                  child: _buildCampaignCard(visibleCampaigns[i]),
                                )
                              : Dismissible(
                                  key: ValueKey('active_${visibleCampaigns[i].id}'),
                                  direction: DismissDirection.horizontal,
                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.startToEnd) {
                                      try {
                                        await ref
                                            .read(smsNotifierProvider.notifier)
                                            .archive(visibleCampaigns[i].id);
                                        ToastService.showSuccess('Campagne archivée');
                                        return true;
                                      } catch (e) {
                                        ToastService.showError('Erreur: $e');
                                        return false;
                                      }
                                    } else {
                                      final confirmed = await AppDialog.confirm(
                                        context,
                                        title: 'Supprimer la campagne',
                                        message:
                                            'Êtes-vous sûr de vouloir supprimer définitivement cette campagne ?',
                                        confirmLabel: 'Supprimer',
                                        destructive: true,
                                      );
                                      if (confirmed == true) {
                                        try {
                                          await ref
                                              .read(smsNotifierProvider.notifier)
                                              .deleteCampaign(visibleCampaigns[i].id);
                                          ToastService.showSuccess('Campagne supprimée');
                                          return true;
                                        } catch (e) {
                                          ToastService.showError('Erreur: $e');
                                          return false;
                                        }
                                      }
                                      return false;
                                    }
                                  },
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5B50EC)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(LucideIcons.archive,
                                            color: Color(0xFF5B50EC), size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Archiver',
                                          style: TextStyle(
                                            color: Color(0xFF5B50EC),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Supprimer',
                                          style: TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(LucideIcons.trash2,
                                            color: Color(0xFFDC2626), size: 18),
                                      ],
                                    ),
                                  ),
                                  child: _buildCampaignCard(visibleCampaigns[i]),
                                ),
                        ],
                        if (campaigns.length > _visibleLimit)
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 6),
                            child: Center(
                              child: InkWell(
                                onTap: () => setState(() => _visibleLimit += 15),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.chevronDown,
                                          size: 15, color: Color(0xFF5B50EC)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Voir plus (${campaigns.length - _visibleLimit} restante${campaigns.length - _visibleLimit > 1 ? 's' : ''})',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5B50EC),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiBox(value: '$reached', label: 'Atteints'),
        ),
        const SizedBox(width: 8),
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
    final title = displayTitle.length > 28
        ? '${displayTitle.substring(0, 28)}...'
        : displayTitle;
    final visual = _typeVisual(camp.type);

    return InkWell(
      onTap: () {
        if (camp.isDraft) {
          context.push('/merchant/campaigns/new', extra: camp);
        } else {
          context.push('/merchant/sms/campaign/${camp.id}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: visual.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(visual.icon, size: 18, color: visual.color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: isDraft
                              ? AppColors.textSecondary
                              : (isPlanned
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A)),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${_targetLabel(camp.recipientType)} • $time',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${camp.recipientsCount} destinataire${camp.recipientsCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(String? recipientType) => targetLabel(recipientType);

  ({IconData icon, Color color, Color bg}) _typeVisual(String type) {
    return switch (type) {
      'promotion' => (
          icon: LucideIcons.tag,
          color: const Color(0xFF5B50EC),
          bg: const Color(0xFF5B50EC).withValues(alpha: 0.12),
        ),
      'reminder' => (
          icon: LucideIcons.bellRing,
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        ),
      'review' => (
          icon: LucideIcons.star,
          color: const Color(0xFFEC4899),
          bg: const Color(0xFFEC4899).withValues(alpha: 0.12),
        ),
      'reward' => (
          icon: LucideIcons.gift,
          color: const Color(0xFF10B981),
          bg: const Color(0xFF10B981).withValues(alpha: 0.12),
        ),
      'progress' => (
          icon: LucideIcons.trendingUp,
          color: const Color(0xFF3B82F6),
          bg: const Color(0xFF3B82F6).withValues(alpha: 0.12),
        ),
      'referral' => (
          icon: LucideIcons.userPlus,
          color: const Color(0xFF14B8A6),
          bg: const Color(0xFF14B8A6).withValues(alpha: 0.12),
        ),
      'cashback' => (
          icon: LucideIcons.coins,
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        ),
      'announcement' => (
          icon: LucideIcons.megaphone,
          color: const Color(0xFF6366F1),
          bg: const Color(0xFF6366F1).withValues(alpha: 0.12),
        ),
      _ => (
          icon: LucideIcons.messageSquare,
          color: const Color(0xFF5B50EC),
          bg: const Color(0xFF5B50EC).withValues(alpha: 0.12),
        ),
    };
  }

  Widget _buildKpiBox({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
